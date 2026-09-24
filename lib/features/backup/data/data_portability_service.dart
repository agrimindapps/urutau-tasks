import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../organization/domain/organization.dart';
import '../../tasks/domain/task.dart';

enum PortabilityFileType { openJson, encryptedBackup }

class PreparedImport {
  PreparedImport._({
    required this.fileType,
    required this.exportedAtUtc,
    required this.activeTaskCount,
    required this.completedTaskCount,
    required this.trashedTaskCount,
    required this.subtaskCount,
    required this.listCount,
    required this.groupCount,
    required this.categoryCount,
    required this.tagCount,
    required this.recurrenceSeriesCount,
    required this.myDayEntryCount,
    required Map<String, dynamic> data,
  }) : data = _freezeJsonObject(data);

  final PortabilityFileType fileType;
  final DateTime exportedAtUtc;
  final int activeTaskCount;
  final int completedTaskCount;
  final int trashedTaskCount;
  final int subtaskCount;
  final int listCount;
  final int groupCount;
  final int categoryCount;
  final int tagCount;
  final int recurrenceSeriesCount;
  final int myDayEntryCount;
  final Map<String, dynamic> data;
}

Map<String, dynamic> _freezeJsonObject(Map<String, dynamic> value) =>
    Map<String, dynamic>.unmodifiable({
      for (final entry in value.entries)
        entry.key: _freezeJsonValue(entry.value),
    });

Object? _freezeJsonValue(Object? value) => switch (value) {
  Map() => Map<String, Object?>.unmodifiable({
    for (final entry in value.entries)
      entry.key as String: _freezeJsonValue(entry.value),
  }),
  List() => List<Object?>.unmodifiable(value.map(_freezeJsonValue)),
  _ => value,
};

class DataPortabilityService {
  DataPortabilityService(this._database);

  final AppDatabase _database;

  static const int _logicalFormatVersion = 1;
  static const int _containerVersion = 1;
  static const int _argonMemoryKiB = 19456;
  static const int _argonIterations = 2;
  static const int _argonParallelism = 1;
  static const int _keyLengthBytes = 32;
  static const int _saltLengthBytes = 16;
  static const int _nonceLengthBytes = 12;
  static const int _tagLengthBytes = 16;

  Future<Uint8List> exportOpenJson() async => Uint8List.fromList(
    utf8.encode(jsonEncode(await _createLogicalSnapshot())),
  );

  Future<Uint8List> exportEncryptedBackup(String password) async {
    if (password.isEmpty) throw const InvalidBackupPasswordException();
    final logicalBytes = utf8.encode(
      jsonEncode(await _createLogicalSnapshot()),
    );
    final cipher = AesGcm.with256bits(nonceLength: _nonceLengthBytes);
    final salt = SecretKeyData.random(length: _saltLengthBytes).bytes;
    final nonce = cipher.newNonce();
    final kdf = Argon2id(
      memory: _argonMemoryKiB,
      iterations: _argonIterations,
      parallelism: _argonParallelism,
      hashLength: _keyLengthBytes,
    );
    final key = await kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final aad = _authenticatedHeader(salt: salt, nonce: nonce);
    late final SecretBox box;
    try {
      box = await cipher.encrypt(
        logicalBytes,
        secretKey: key,
        nonce: nonce,
        aad: aad,
      );
    } finally {
      key.destroy();
    }
    final envelope = <String, dynamic>{
      'container_version': _containerVersion,
      'kdf': {
        'algorithm': 'argon2id',
        'memory_kib': _argonMemoryKiB,
        'iterations': _argonIterations,
        'parallelism': _argonParallelism,
        'hash_length': _keyLengthBytes,
        'salt': base64Encode(salt),
      },
      'cipher': {
        'algorithm': 'aes-256-gcm',
        'nonce': base64Encode(nonce),
        'ciphertext': base64Encode(box.cipherText),
        'tag': base64Encode(box.mac.bytes),
      },
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<PreparedImport> prepareImport(
    Uint8List bytes, {
    String? password,
  }) async {
    final decoded = _decodeJson(bytes);
    final root = _asObject(decoded, 'arquivo');
    PortabilityFileType fileType;
    Map<String, dynamic> logicalRoot;
    if (root.containsKey('container_version')) {
      fileType = PortabilityFileType.encryptedBackup;
      if (password == null) throw const BackupPasswordRequiredException();
      logicalRoot = await _decryptEnvelope(root, password);
    } else {
      fileType = PortabilityFileType.openJson;
      logicalRoot = root;
    }
    final validated = _validateLogicalSnapshot(logicalRoot);
    final data = validated['data'] as Map<String, dynamic>;
    final tasks = data['tasks'] as List<Map<String, dynamic>>;
    return PreparedImport._(
      fileType: fileType,
      exportedAtUtc: DateTime.parse(validated['exported_at'] as String).toUtc(),
      activeTaskCount: tasks.where((row) => row['status'] == 'active').length,
      completedTaskCount: tasks
          .where((row) => row['status'] == 'completed')
          .length,
      trashedTaskCount: tasks.where((row) => row['status'] == 'trashed').length,
      subtaskCount: (data['subtasks'] as List).length,
      listCount: (data['lists'] as List).length,
      groupCount: (data['groups'] as List).length,
      categoryCount: (data['categories'] as List).length,
      tagCount: (data['tags'] as List).length,
      recurrenceSeriesCount: (data['recurring_series'] as List).length,
      myDayEntryCount: (data['my_day_entries'] as List).length,
      data: data,
    );
  }

  Future<void> replaceAllData(PreparedImport prepared) async {
    final data = prepared.data;
    await _database.transaction(() async {
      await _database.delete(_database.taskTags).go();
      await _database.delete(_database.subtasks).go();
      await _database.delete(_database.myDayEntries).go();
      await _database.delete(_database.tasks).go();
      await _database.delete(_database.tags).go();
      await _database.delete(_database.categories).go();
      await _database.delete(_database.taskLists).go();
      await _database.delete(_database.taskGroups).go();
      await _database.delete(_database.recurrenceSeries).go();

      for (final row in _rows(data, 'groups')) {
        await _database
            .into(_database.taskGroups)
            .insert(
              TaskGroupsCompanion.insert(
                id: row['id'] as String,
                name: row['name'] as String,
                position: row['position'] as int,
              ),
            );
      }
      for (final row in _rows(data, 'lists')) {
        await _database
            .into(_database.taskLists)
            .insert(
              TaskListsCompanion.insert(
                id: row['id'] as String,
                name: row['name'] as String,
                position: row['position'] as int,
                groupId: Value(row['group_id'] as String?),
              ),
            );
      }
      for (final row in _rows(data, 'categories')) {
        await _database
            .into(_database.categories)
            .insert(
              CategoriesCompanion.insert(
                id: row['id'] as String,
                name: row['name'] as String,
              ),
            );
      }
      for (final row in _rows(data, 'tags')) {
        final name = row['name'] as String;
        await _database
            .into(_database.tags)
            .insert(
              TagsCompanion.insert(
                id: row['id'] as String,
                name: name,
                normalizedName: canonicalTagName(name),
              ),
            );
      }
      for (final row in _rows(data, 'recurring_series')) {
        await _database
            .into(_database.recurrenceSeries)
            .insert(
              RecurrenceSeriesCompanion.insert(
                id: row['id'] as String,
                frequency: _frequencyValue(row['frequency'] as String),
                anchorDueDateIso: row['anchor_due_date_iso'] as String,
                isActive: Value(row['is_active'] as bool),
                createdAtUtc: _utcMilliseconds(row['created_at_utc'] as String),
                updatedAtUtc: _utcMilliseconds(row['updated_at_utc'] as String),
              ),
            );
      }
      for (final row in _rows(data, 'tasks')) {
        await _database
            .into(_database.tasks)
            .insert(
              TasksCompanion.insert(
                id: row['id'] as String,
                title: row['title'] as String,
                notes: Value(row['notes'] as String?),
                status: Value(_statusValue(row['status'] as String)),
                priority: Value(_priorityValue(row['priority'] as String)),
                listId: Value(row['list_id'] as String?),
                categoryId: Value(row['category_id'] as String?),
                dueDateIso: Value(row['due_date_iso'] as String?),
                reminderAtUtc: Value(
                  _optionalUtcMilliseconds(row['reminder_at_utc']),
                ),
                recurringSeriesId: Value(row['recurring_series_id'] as String?),
                createdAtUtc: _utcMilliseconds(row['created_at_utc'] as String),
                updatedAtUtc: _utcMilliseconds(row['updated_at_utc'] as String),
                completedAtUtc: Value(
                  _optionalUtcMilliseconds(row['completed_at_utc']),
                ),
                position: Value(row['position'] as int),
                statusBeforeTrash: Value(
                  _optionalStatusValue(row['status_before_trash']),
                ),
                deletedAtUtc: Value(
                  _optionalUtcMilliseconds(row['deleted_at_utc']),
                ),
              ),
            );
      }
      for (final row in _rows(data, 'subtasks')) {
        await _database
            .into(_database.subtasks)
            .insert(
              SubtasksCompanion.insert(
                id: row['id'] as String,
                taskId: row['task_id'] as String,
                title: row['title'] as String,
                isCompleted: Value(row['is_completed'] as bool),
                position: row['position'] as int,
              ),
            );
      }
      for (final row in _rows(data, 'task_tags')) {
        await _database
            .into(_database.taskTags)
            .insert(
              TaskTagsCompanion.insert(
                taskId: row['task_id'] as String,
                tagId: row['tag_id'] as String,
              ),
            );
      }
      for (final row in _rows(data, 'my_day_entries')) {
        await _database
            .into(_database.myDayEntries)
            .insert(
              MyDayEntriesCompanion.insert(
                id: row['id'] as String,
                taskId: row['task_id'] as String,
                localDateIso: row['local_date_iso'] as String,
                position: row['position'] as int,
              ),
            );
      }
    });
  }

  Future<Map<String, dynamic>> _createLogicalSnapshot() async {
    return _database.transaction(() async {
      final groupRows = await (_database.select(
        _database.taskGroups,
      )..orderBy([(row) => OrderingTerm.asc(row.position)])).get();
      final listRows = await (_database.select(
        _database.taskLists,
      )..orderBy([(row) => OrderingTerm.asc(row.position)])).get();
      final categoryRows = await (_database.select(
        _database.categories,
      )..orderBy([(row) => OrderingTerm.asc(row.name)])).get();
      final tagRows = await (_database.select(
        _database.tags,
      )..orderBy([(row) => OrderingTerm.asc(row.name)])).get();
      final seriesRows = await (_database.select(
        _database.recurrenceSeries,
      )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
      final taskRows = await (_database.select(
        _database.tasks,
      )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
      final subtaskRows =
          await (_database.select(_database.subtasks)..orderBy([
                (row) => OrderingTerm.asc(row.taskId),
                (row) => OrderingTerm.asc(row.position),
              ]))
              .get();
      final taskTagRows =
          await (_database.select(_database.taskTags)..orderBy([
                (row) => OrderingTerm.asc(row.taskId),
                (row) => OrderingTerm.asc(row.tagId),
              ]))
              .get();
      final myDayRows =
          await (_database.select(_database.myDayEntries)..orderBy([
                (row) => OrderingTerm.asc(row.localDateIso),
                (row) => OrderingTerm.asc(row.position),
              ]))
              .get();

      return {
        'format_version': _logicalFormatVersion,
        'exported_at': _utcIso(DateTime.now().toUtc()),
        'data': {
          'tasks': taskRows
              .map(
                (row) => {
                  'id': row.id,
                  'title': row.title,
                  'notes': row.notes,
                  'status': _statusName(row.status),
                  'priority': _priorityName(row.priority),
                  'list_id': row.listId,
                  'category_id': row.categoryId,
                  'due_date_iso': row.dueDateIso,
                  'reminder_at_utc': _optionalUtcIso(row.reminderAtUtc),
                  'recurring_series_id': row.recurringSeriesId,
                  'created_at_utc': _utcIsoFromMilliseconds(row.createdAtUtc),
                  'updated_at_utc': _utcIsoFromMilliseconds(row.updatedAtUtc),
                  'completed_at_utc': _optionalUtcIso(row.completedAtUtc),
                  'position': row.position,
                  'status_before_trash': row.statusBeforeTrash == null
                      ? null
                      : _statusName(row.statusBeforeTrash!),
                  'deleted_at_utc': _optionalUtcIso(row.deletedAtUtc),
                },
              )
              .toList(growable: false),
          'subtasks': subtaskRows
              .map(
                (row) => {
                  'id': row.id,
                  'task_id': row.taskId,
                  'title': row.title,
                  'is_completed': row.isCompleted,
                  'position': row.position,
                },
              )
              .toList(growable: false),
          'lists': listRows
              .map(
                (row) => {
                  'id': row.id,
                  'name': row.name,
                  'position': row.position,
                  'group_id': row.groupId,
                },
              )
              .toList(growable: false),
          'groups': groupRows
              .map(
                (row) => {
                  'id': row.id,
                  'name': row.name,
                  'position': row.position,
                },
              )
              .toList(growable: false),
          'categories': categoryRows
              .map((row) => {'id': row.id, 'name': row.name})
              .toList(growable: false),
          'tags': tagRows
              .map((row) => {'id': row.id, 'name': row.name})
              .toList(growable: false),
          'task_tags': taskTagRows
              .map((row) => {'task_id': row.taskId, 'tag_id': row.tagId})
              .toList(growable: false),
          'recurring_series': seriesRows
              .map(
                (row) => {
                  'id': row.id,
                  'frequency': _frequencyName(row.frequency),
                  'anchor_due_date_iso': row.anchorDueDateIso,
                  'is_active': row.isActive,
                  'created_at_utc': _utcIsoFromMilliseconds(row.createdAtUtc),
                  'updated_at_utc': _utcIsoFromMilliseconds(row.updatedAtUtc),
                },
              )
              .toList(growable: false),
          'my_day_entries': myDayRows
              .map(
                (row) => {
                  'id': row.id,
                  'task_id': row.taskId,
                  'local_date_iso': row.localDateIso,
                  'position': row.position,
                },
              )
              .toList(growable: false),
        },
      };
    });
  }

  Future<Map<String, dynamic>> _decryptEnvelope(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    _requireKeys(envelope, {'container_version', 'kdf', 'cipher'}, 'backup');
    final containerVersion = _requiredInt(envelope, 'container_version');
    if (containerVersion != _containerVersion) {
      throw UnsupportedBackupContainerVersionException(containerVersion);
    }
    final kdf = _asObject(envelope['kdf'], 'KDF');
    final cipherInfo = _asObject(envelope['cipher'], 'criptografia');
    _requireKeys(kdf, {
      'algorithm',
      'memory_kib',
      'iterations',
      'parallelism',
      'hash_length',
      'salt',
    }, 'KDF');
    _requireKeys(cipherInfo, {
      'algorithm',
      'nonce',
      'ciphertext',
      'tag',
    }, 'criptografia');
    if (kdf['algorithm'] != 'argon2id' ||
        _requiredInt(kdf, 'memory_kib') != _argonMemoryKiB ||
        _requiredInt(kdf, 'iterations') != _argonIterations ||
        _requiredInt(kdf, 'parallelism') != _argonParallelism ||
        _requiredInt(kdf, 'hash_length') != _keyLengthBytes) {
      throw const UnsupportedBackupContainerVersionException(_containerVersion);
    }
    if (cipherInfo['algorithm'] != 'aes-256-gcm') {
      throw const UnsupportedBackupContainerVersionException(_containerVersion);
    }
    final salt = _decodeBase64(kdf['salt'], 'salt');
    final nonce = _decodeBase64(cipherInfo['nonce'], 'nonce');
    final ciphertext = _decodeBase64(cipherInfo['ciphertext'], 'ciphertext');
    final tag = _decodeBase64(cipherInfo['tag'], 'tag');
    if (salt.length != _saltLengthBytes ||
        nonce.length != _nonceLengthBytes ||
        tag.length != _tagLengthBytes) {
      throw const InvalidBackupFileException();
    }
    final key = await Argon2id(
      memory: _argonMemoryKiB,
      iterations: _argonIterations,
      parallelism: _argonParallelism,
      hashLength: _keyLengthBytes,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    final box = SecretBox(ciphertext, nonce: nonce, mac: Mac(tag));
    try {
      final plaintext = await AesGcm.with256bits(nonceLength: _nonceLengthBytes)
          .decrypt(
            box,
            secretKey: key,
            aad: _authenticatedHeader(salt: salt, nonce: nonce),
          );
      return _asObject(_decodeJson(Uint8List.fromList(plaintext)), 'retrato');
    } on SecretBoxAuthenticationError {
      throw const BackupAuthenticationFailedException();
    } finally {
      key.destroy();
    }
  }

  List<int> _authenticatedHeader({
    required List<int> salt,
    required List<int> nonce,
  }) => utf8.encode(
    jsonEncode({
      'container_version': _containerVersion,
      'kdf': {
        'algorithm': 'argon2id',
        'memory_kib': _argonMemoryKiB,
        'iterations': _argonIterations,
        'parallelism': _argonParallelism,
        'hash_length': _keyLengthBytes,
        'salt': base64Encode(salt),
      },
      'cipher': {'algorithm': 'aes-256-gcm', 'nonce': base64Encode(nonce)},
    }),
  );

  Map<String, dynamic> _validateLogicalSnapshot(Map<String, dynamic> root) {
    _requireKeys(root, {'format_version', 'exported_at', 'data'}, 'arquivo');
    final version = _requiredInt(root, 'format_version');
    if (version != _logicalFormatVersion) {
      throw UnsupportedLogicalFormatVersionException(version);
    }
    _utcMilliseconds(root['exported_at']);
    final data = _asObject(root['data'], 'dados');
    const dataKeys = {
      'tasks',
      'subtasks',
      'lists',
      'groups',
      'categories',
      'tags',
      'task_tags',
      'recurring_series',
      'my_day_entries',
    };
    _requireKeys(data, dataKeys, 'dados');
    final tasks = _readRows(data, 'tasks', {
      'id',
      'title',
      'notes',
      'status',
      'priority',
      'list_id',
      'category_id',
      'due_date_iso',
      'reminder_at_utc',
      'recurring_series_id',
      'created_at_utc',
      'updated_at_utc',
      'completed_at_utc',
      'position',
      'status_before_trash',
      'deleted_at_utc',
    });
    final subtasks = _readRows(data, 'subtasks', {
      'id',
      'task_id',
      'title',
      'is_completed',
      'position',
    });
    final lists = _readRows(data, 'lists', {
      'id',
      'name',
      'position',
      'group_id',
    });
    final groups = _readRows(data, 'groups', {'id', 'name', 'position'});
    final categories = _readRows(data, 'categories', {'id', 'name'});
    final tags = _readRows(data, 'tags', {'id', 'name'});
    final taskTags = _readRows(data, 'task_tags', {'task_id', 'tag_id'});
    final series = _readRows(data, 'recurring_series', {
      'id',
      'frequency',
      'anchor_due_date_iso',
      'is_active',
      'created_at_utc',
      'updated_at_utc',
    });
    final myDay = _readRows(data, 'my_day_entries', {
      'id',
      'task_id',
      'local_date_iso',
      'position',
    });

    final allIds = <String>{};
    final groupIds = _validateNamedRows(groups, 'grupo', allIds);
    final listIds = _validateNamedRows(lists, 'lista', allIds);
    final categoryIds = _validateNamedRows(categories, 'categoria', allIds);
    final tagIds = _validateNamedRows(tags, 'tag', allIds);
    final seriesIds = <String>{};
    final activeSeriesById = <String, bool>{};
    for (final row in series) {
      _registerId(row['id'], 'série recorrente', allIds);
      final seriesId = row['id'] as String;
      seriesIds.add(seriesId);
      _requireDateOnly(row['anchor_due_date_iso'], 'anchor_due_date_iso');
      _frequencyValue(_requiredString(row, 'frequency'));
      activeSeriesById[seriesId] = _requiredBool(row, 'is_active');
      _utcMilliseconds(row['created_at_utc']);
      _utcMilliseconds(row['updated_at_utc']);
    }

    final taskIds = <String>{};
    final taskPositionKeys = <String>{};
    final statusByTask = <String, String>{};
    final occurrenceCreationTimesBySeries = <String, Set<int>>{};
    for (final row in tasks) {
      _registerId(row['id'], 'tarefa', allIds);
      final id = row['id'] as String;
      taskIds.add(id);
      final title = _requiredString(row, 'title');
      if (title.trim().isEmpty || title != title.trim()) {
        throw const InvalidBackupFileException();
      }
      _optionalString(row, 'notes');
      final status = _requiredString(row, 'status');
      _statusValue(status);
      statusByTask[id] = status;
      _priorityValue(_requiredString(row, 'priority'));
      final listId = _optionalString(row, 'list_id');
      final categoryId = _optionalString(row, 'category_id');
      final seriesId = _optionalString(row, 'recurring_series_id');
      if (listId != null && !listIds.contains(listId) ||
          categoryId != null && !categoryIds.contains(categoryId) ||
          seriesId != null && !seriesIds.contains(seriesId)) {
        throw const InvalidBackupFileException();
      }
      final createdAtUtc = _utcMilliseconds(row['created_at_utc']);
      if (seriesId != null &&
          !occurrenceCreationTimesBySeries
              .putIfAbsent(seriesId, () => <int>{})
              .add(createdAtUtc)) {
        throw const InvalidBackupFileException();
      }
      final dueDate = _optionalString(row, 'due_date_iso');
      if (dueDate != null) _requireDateOnly(dueDate, 'due_date_iso');
      if (seriesId != null &&
          dueDate == null &&
          activeSeriesById[seriesId] == true) {
        throw const InvalidBackupFileException();
      }
      _optionalUtcMilliseconds(row['reminder_at_utc']);
      _utcMilliseconds(row['updated_at_utc']);
      final completedAt = _optionalUtcMilliseconds(row['completed_at_utc']);
      final previousStatus = row['status_before_trash'];
      final previousStatusValue = _optionalStatusValue(previousStatus);
      final deletedAt = _optionalUtcMilliseconds(row['deleted_at_utc']);
      final effectiveStatus = status == 'trashed'
          ? previousStatus as String?
          : status;
      if (effectiveStatus == 'completed' && completedAt == null ||
          effectiveStatus == 'active' && completedAt != null ||
          status == 'trashed' && previousStatusValue == null ||
          previousStatus == 'trashed' ||
          status != 'trashed' && previousStatusValue != null ||
          status == 'trashed' && deletedAt == null ||
          status != 'trashed' && deletedAt != null) {
        throw const InvalidBackupFileException();
      }
      final position = _nonNegativeInt(row, 'position');
      final positionContext = listId == null ? 'inbox' : 'list:$listId';
      if (!taskPositionKeys.add('$positionContext:$position')) {
        throw const InvalidBackupFileException();
      }
    }

    final subtaskPositionKeys = <String>{};
    for (final row in subtasks) {
      _registerId(row['id'], 'subtarefa', allIds);
      final taskId = _requiredString(row, 'task_id');
      if (!taskIds.contains(taskId)) throw const InvalidBackupFileException();
      final title = _requiredString(row, 'title');
      if (title.trim().isEmpty || title != title.trim()) {
        throw const InvalidBackupFileException();
      }
      _requiredBool(row, 'is_completed');
      _nonNegativeInt(row, 'position');
      if (!subtaskPositionKeys.add('$taskId:${row['position']}')) {
        throw const InvalidBackupFileException();
      }
    }

    final taskTagKeys = <String>{};
    for (final row in taskTags) {
      final taskId = _requiredString(row, 'task_id');
      final tagId = _requiredString(row, 'tag_id');
      if (!taskIds.contains(taskId) ||
          !tagIds.contains(tagId) ||
          !taskTagKeys.add('$taskId:$tagId')) {
        throw const InvalidBackupFileException();
      }
    }

    final myDayKeys = <String>{};
    final myDayPositionKeys = <String>{};
    for (final row in myDay) {
      _registerId(row['id'], 'entrada do My Day', allIds);
      final taskId = _requiredString(row, 'task_id');
      if (!taskIds.contains(taskId) || statusByTask[taskId] != 'active') {
        throw const InvalidBackupFileException();
      }
      final date = _requiredString(row, 'local_date_iso');
      _requireDateOnly(date, 'local_date_iso');
      final position = _nonNegativeInt(row, 'position');
      if (!myDayKeys.add('$taskId:$date') ||
          !myDayPositionKeys.add('$date:$position')) {
        throw const InvalidBackupFileException();
      }
    }

    final groupNames = <String>{};
    final groupPositions = <int>{};
    for (final row in groups) {
      _validateNameUnique(groupNames, row['name']);
      if (!groupPositions.add(_nonNegativeInt(row, 'position'))) {
        throw const InvalidBackupFileException();
      }
    }
    final listNames = <String>{};
    final listPositions = <int>{};
    for (final row in lists) {
      _validateNameUnique(listNames, row['name']);
      if (!listPositions.add(_nonNegativeInt(row, 'position'))) {
        throw const InvalidBackupFileException();
      }
      final groupId = _optionalString(row, 'group_id');
      if (groupId != null && !groupIds.contains(groupId)) {
        throw const InvalidBackupFileException();
      }
    }
    final categoryNames = <String>{};
    for (final row in categories) {
      _validateNameUnique(categoryNames, row['name']);
    }
    final tagNames = <String>{};
    for (final row in tags) {
      _validateNameUnique(tagNames, row['name'], normalize: true);
    }

    return {
      'format_version': version,
      'exported_at': root['exported_at'],
      'data': {
        'tasks': tasks,
        'subtasks': subtasks,
        'lists': lists,
        'groups': groups,
        'categories': categories,
        'tags': tags,
        'task_tags': taskTags,
        'recurring_series': series,
        'my_day_entries': myDay,
      },
    };
  }

  Set<String> _validateNamedRows(
    List<Map<String, dynamic>> rows,
    String label,
    Set<String> allIds,
  ) {
    final ids = <String>{};
    for (final row in rows) {
      _registerId(row['id'], label, allIds);
      ids.add(row['id'] as String);
      _requiredString(row, 'name');
    }
    return ids;
  }

  void _validateNameUnique(
    Set<String> names,
    Object? value, {
    bool normalize = false,
  }) {
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw const InvalidBackupFileException();
    }
    final comparison = normalize ? value.toLowerCase() : value;
    if (!names.add(comparison)) throw const InvalidBackupFileException();
  }

  List<Map<String, dynamic>> _readRows(
    Map<String, dynamic> data,
    String key,
    Set<String> keys,
  ) {
    final value = data[key];
    if (value is! List) throw const InvalidBackupFileException();
    return value
        .map((item) {
          final row = _asObject(item, key);
          _requireKeys(row, keys, key);
          return row;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> data, String key) =>
      (data[key] as List).cast<Map<String, dynamic>>();

  void _registerId(Object? value, String label, Set<String> allIds) {
    if (value is! String ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(value) ||
        !allIds.add(value.toLowerCase())) {
      throw const InvalidBackupFileException();
    }
  }

  Map<String, dynamic> _asObject(Object? value, String context) {
    if (value is! Map) throw const InvalidBackupFileException();
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) throw const InvalidBackupFileException();
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  void _requireKeys(
    Map<String, dynamic> object,
    Set<String> keys,
    String context,
  ) {
    if (object.length != keys.length ||
        !object.keys.toSet().containsAll(keys)) {
      throw const InvalidBackupFileException();
    }
  }

  String _requiredString(Map<String, dynamic> object, String key) {
    final value = object[key];
    if (value is! String) throw const InvalidBackupFileException();
    return value;
  }

  String? _optionalString(Map<String, dynamic> object, String key) {
    final value = object[key];
    if (value == null) return null;
    if (value is! String) throw const InvalidBackupFileException();
    return value;
  }

  int _requiredInt(Map<String, dynamic> object, String key) {
    final value = object[key];
    if (value is! int) throw const InvalidBackupFileException();
    return value;
  }

  int _nonNegativeInt(Map<String, dynamic> object, String key) {
    final value = _requiredInt(object, key);
    if (value < 0) throw const InvalidBackupFileException();
    return value;
  }

  bool _requiredBool(Map<String, dynamic> object, String key) {
    final value = object[key];
    if (value is! bool) throw const InvalidBackupFileException();
    return value;
  }

  void _requireDateOnly(Object? value, String label) {
    if (value is! String) throw const InvalidBackupFileException();
    try {
      normalizeDateOnly(value);
    } on InvalidDateOnlyException {
      throw const InvalidBackupFileException();
    }
  }

  int _utcMilliseconds(Object? value) {
    if (value is! String) throw const InvalidBackupFileException();
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?Z$',
    ).firstMatch(value);
    if (match == null) throw const InvalidBackupFileException();
    final parsed = DateTime.tryParse(value);
    if (parsed == null ||
        !parsed.isUtc ||
        parsed.year != int.parse(match.group(1)!) ||
        parsed.month != int.parse(match.group(2)!) ||
        parsed.day != int.parse(match.group(3)!) ||
        parsed.hour != int.parse(match.group(4)!) ||
        parsed.minute != int.parse(match.group(5)!) ||
        parsed.second != int.parse(match.group(6)!)) {
      throw const InvalidBackupFileException();
    }
    return parsed.millisecondsSinceEpoch;
  }

  int? _optionalUtcMilliseconds(Object? value) =>
      value == null ? null : _utcMilliseconds(value);

  int? _optionalStatusValue(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const InvalidBackupFileException();
    return _statusValue(value);
  }

  List<int> _decodeBase64(Object? value, String context) {
    if (value is! String) throw const InvalidBackupFileException();
    try {
      return base64Decode(value);
    } on FormatException {
      throw const InvalidBackupFileException();
    }
  }

  Object? _decodeJson(Uint8List bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const InvalidBackupFileException();
    }
  }

  int _statusValue(String value) => switch (value) {
    'active' => TaskStatus.active.databaseValue,
    'completed' => TaskStatus.completed.databaseValue,
    'trashed' => TaskStatus.trashed.databaseValue,
    _ => throw const InvalidBackupFileException(),
  };

  String _statusName(int value) => switch (value) {
    0 => 'active',
    1 => 'completed',
    2 => 'trashed',
    _ => throw const InvalidBackupFileException(),
  };

  int _priorityValue(String value) => switch (value) {
    'none' => TaskPriority.none.databaseValue,
    'low' => TaskPriority.low.databaseValue,
    'medium' => TaskPriority.medium.databaseValue,
    'high' => TaskPriority.high.databaseValue,
    'urgent' => TaskPriority.urgent.databaseValue,
    _ => throw const InvalidBackupFileException(),
  };

  String _priorityName(int value) => switch (value) {
    0 => 'none',
    1 => 'low',
    2 => 'medium',
    3 => 'high',
    4 => 'urgent',
    _ => throw const InvalidBackupFileException(),
  };

  int _frequencyValue(String value) => switch (value) {
    'daily' => RecurrenceFrequency.daily.databaseValue,
    'weekdays' => RecurrenceFrequency.weekdays.databaseValue,
    'weekly' => RecurrenceFrequency.weekly.databaseValue,
    'monthly' => RecurrenceFrequency.monthly.databaseValue,
    'yearly' => RecurrenceFrequency.yearly.databaseValue,
    _ => throw const InvalidBackupFileException(),
  };

  String _frequencyName(int value) => switch (value) {
    0 => 'daily',
    1 => 'weekdays',
    2 => 'weekly',
    3 => 'monthly',
    4 => 'yearly',
    _ => throw const InvalidBackupFileException(),
  };

  String _utcIsoFromMilliseconds(int value) =>
      _utcIso(DateTime.fromMillisecondsSinceEpoch(value, isUtc: true));

  String? _optionalUtcIso(int? value) =>
      value == null ? null : _utcIsoFromMilliseconds(value);

  String _utcIso(DateTime value) => value.toUtc().toIso8601String();
}

class BackupPasswordRequiredException implements Exception {
  const BackupPasswordRequiredException();
}

class InvalidBackupPasswordException implements Exception {
  const InvalidBackupPasswordException();
}

class BackupAuthenticationFailedException implements Exception {
  const BackupAuthenticationFailedException();
}

class InvalidBackupFileException implements Exception {
  const InvalidBackupFileException();
}

class UnsupportedLogicalFormatVersionException implements Exception {
  const UnsupportedLogicalFormatVersionException(this.version);

  final int version;
}

class UnsupportedBackupContainerVersionException implements Exception {
  const UnsupportedBackupContainerVersionException(this.version);

  final int version;
}
