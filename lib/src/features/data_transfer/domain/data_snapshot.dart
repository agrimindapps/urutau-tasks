/// Retrato lógico versionado dos dados (spec 07, RF-01 a RF-04/RF-10).
///
/// Formato aberto `format_version` 1, independente da versão do esquema
/// Drift (RF-07). Datas locais permanecem `YYYY-MM-DD` e instantes UTC
/// permanecem instantes (RF-04).
library;

import 'dart:convert';

/// Falhas de validação do retrato/importação (spec 07, RF-13/RF-17).
enum SnapshotFailure {
  malformedJson,
  wrongStructure,
  unsupportedVersion,
  duplicateId,
  brokenReference,
  unknownField,
  wrongType,
}

class SnapshotException implements Exception {
  const SnapshotException(this.failure, [this.detail = '']);

  final SnapshotFailure failure;
  final String detail;

  @override
  String toString() => 'SnapshotException(${failure.name}: $detail)';
}

/// Versão atual do formato lógico (monotônica; spec 07, RF-07).
const int kSnapshotFormatVersion = 1;

/// Retrato completo e imutável do estado local.
class DataSnapshot {
  const DataSnapshot({
    required this.exportedAt,
    required this.tasks,
    required this.subtasks,
    required this.lists,
    required this.groups,
    required this.categories,
    required this.tags,
    required this.taskTags,
    required this.recurringSeries,
    required this.myDayEntries,
    this.formatVersion = kSnapshotFormatVersion,
  });

  final int formatVersion;

  /// Instante UTC de criação (spec 07, RF-07).
  final DateTime exportedAt;

  final List<Map<String, Object?>> tasks;
  final List<Map<String, Object?>> subtasks;
  final List<Map<String, Object?>> lists;
  final List<Map<String, Object?>> groups;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> tags;
  final List<Map<String, Object?>> taskTags;
  final List<Map<String, Object?>> recurringSeries;
  final List<Map<String, Object?>> myDayEntries;

  /// Serializa para o formato aberto v1 (UTF-8 JSON legível; RF-09/RF-10).
  String encode() {
    return const JsonEncoder.withIndent('  ').convert({
      'format_version': formatVersion,
      'exported_at': exportedAt.toUtc().toIso8601String(),
      'data': {
        'tasks': tasks,
        'subtasks': subtasks,
        'lists': lists,
        'groups': groups,
        'categories': categories,
        'tags': tags,
        'task_tags': taskTags,
        'recurring_series': recurringSeries,
        'my_day_entries': myDayEntries,
      },
    });
  }

  /// Lê e valida o formato aberto (spec 07, RF-13).
  ///
  /// Rejeita JSON malformado, estrutura errada, versão não suportada,
  /// IDs duplicados, referências inválidas e campos desconhecidos com
  /// dados — nada é descartado silenciosamente.
  factory DataSnapshot.decode(String content) {
    Object? root;
    try {
      root = jsonDecode(content);
    } on FormatException catch (e) {
      throw SnapshotException(SnapshotFailure.malformedJson, e.message);
    }
    if (root is! Map<String, Object?>) {
      throw const SnapshotException(SnapshotFailure.wrongStructure, 'raiz');
    }

    final version = root['format_version'];
    if (version is! int) {
      throw const SnapshotException(SnapshotFailure.wrongType, 'format_version');
    }
    if (version > kSnapshotFormatVersion) {
      throw SnapshotException(
        SnapshotFailure.unsupportedVersion,
        'format_version=$version',
      );
    }

    final exportedRaw = root['exported_at'];
    if (exportedRaw is! String) {
      throw const SnapshotException(SnapshotFailure.wrongType, 'exported_at');
    }
    final exportedAt = DateTime.tryParse(exportedRaw);
    if (exportedAt == null) {
      throw const SnapshotException(SnapshotFailure.wrongType, 'exported_at');
    }

    for (final key in root.keys) {
      if (key != 'format_version' && key != 'exported_at' && key != 'data') {
        if (root[key] != null) {
          throw SnapshotException(SnapshotFailure.unknownField, key);
        }
      }
    }

    final data = root['data'];
    if (data is! Map<String, Object?>) {
      throw const SnapshotException(SnapshotFailure.wrongStructure, 'data');
    }

    const arrays = [
      'tasks',
      'subtasks',
      'lists',
      'groups',
      'categories',
      'tags',
      'task_tags',
      'recurring_series',
      'my_day_entries',
    ];
    for (final name in arrays) {
      if (data[name] is! List) {
        throw SnapshotException(SnapshotFailure.wrongStructure, name);
      }
    }
    // Campos desconhecidos com dados não são descartados (RF-13).
    for (final key in data.keys) {
      if (!arrays.contains(key) && (data[key] as List).isNotEmpty) {
        throw SnapshotException(SnapshotFailure.unknownField, key);
      }
    }

    final snapshot = DataSnapshot(
      formatVersion: version,
      exportedAt: exportedAt,
      tasks: _readList(data['tasks'], _taskFields, 'tasks'),
      subtasks: _readList(data['subtasks'], _subtaskFields, 'subtasks'),
      lists: _readList(data['lists'], _listFields, 'lists'),
      groups: _readList(data['groups'], _groupFields, 'groups'),
      categories: _readList(data['categories'], _categoryFields, 'categories'),
      tags: _readList(data['tags'], _tagFields, 'tags'),
      taskTags: _readList(data['task_tags'], _taskTagFields, 'task_tags'),
      recurringSeries:
          _readList(data['recurring_series'], _seriesFields, 'recurring_series'),
      myDayEntries:
          _readList(data['my_day_entries'], _myDayFields, 'my_day_entries'),
    );
    snapshot._validate();
    return snapshot;
  }

  void _validate() {
    void uniqueIds(String name, List<Map<String, Object?>> rows) {
      final seen = <String>{};
      for (final row in rows) {
        final id = row['id'];
        if (id is! String || !seen.add(id)) {
          throw SnapshotException(SnapshotFailure.duplicateId, '$name/$id');
        }
      }
    }

    uniqueIds('tasks', tasks);
    uniqueIds('subtasks', subtasks);
    uniqueIds('lists', lists);
    uniqueIds('groups', groups);
    uniqueIds('categories', categories);
    uniqueIds('tags', tags);
    uniqueIds('recurring_series', recurringSeries);
    uniqueIds('my_day_entries', myDayEntries);

    final taskIds = {for (final t in tasks) t['id']};
    final listIds = {for (final l in lists) l['id']};
    final groupIds = {for (final g in groups) g['id']};
    final categoryIds = {for (final c in categories) c['id']};
    final tagIds = {for (final t in tags) t['id']};
    final seriesIds = {for (final s in recurringSeries) s['id']};

    void mustExist(Object? ref, Set<Object?> known, String where) {
      if (ref != null && !known.contains(ref)) {
        throw SnapshotException(SnapshotFailure.brokenReference, where);
      }
    }

    for (final task in tasks) {
      mustExist(task['list_id'], listIds, 'task.list_id');
      mustExist(task['category_id'], categoryIds, 'task.category_id');
      mustExist(task['series_id'], seriesIds, 'task.series_id');
    }
    for (final subtask in subtasks) {
      mustExist(subtask['task_id'], taskIds, 'subtask.task_id');
    }
    for (final list in lists) {
      mustExist(list['group_id'], groupIds, 'list.group_id');
    }
    for (final pair in taskTags) {
      mustExist(pair['task_id'], taskIds, 'task_tag.task_id');
      mustExist(pair['tag_id'], tagIds, 'task_tag.tag_id');
    }
    for (final entry in myDayEntries) {
      mustExist(entry['task_id'], taskIds, 'my_day_entry.task_id');
    }
    // Chave tarefa/tag única (spec 06, RF-19).
    final pairs = <String>{};
    for (final pair in taskTags) {
      final key = '${pair['task_id']}/${pair['tag_id']}';
      if (!pairs.add(key)) {
        throw SnapshotException(SnapshotFailure.duplicateId, 'task_tags/$key');
      }
    }
  }
}

List<Map<String, Object?>> _readList(
  Object? raw,
  Set<String> fields,
  String name,
) {
  return [
    for (final item in raw! as List)
      _readRow(item, fields, name),
  ];
}

Map<String, Object?> _readRow(Object? raw, Set<String> fields, String name) {
  if (raw is! Map<String, Object?>) {
    throw SnapshotException(SnapshotFailure.wrongType, name);
  }
  for (final key in raw.keys) {
    if (!fields.contains(key) && raw[key] != null) {
      throw SnapshotException(SnapshotFailure.unknownField, '$name.$key');
    }
  }
  return raw;
}

const Set<String> _taskFields = {
  'id', 'title', 'notes', 'status', 'status_before_trash',
  'created_at', 'updated_at', 'completed_at', 'position',
  'list_id', 'category_id', 'priority', 'due_date', 'reminder', 'series_id',
};

const Set<String> _subtaskFields = {
  'id', 'task_id', 'description', 'is_completed', 'position',
};

const Set<String> _listFields = {'id', 'name', 'position', 'group_id'};

const Set<String> _groupFields = {'id', 'name', 'position'};

const Set<String> _categoryFields = {'id', 'name'};

const Set<String> _tagFields = {'id', 'name', 'normalized_name'};

const Set<String> _taskTagFields = {'task_id', 'tag_id'};

const Set<String> _seriesFields = {
  'id', 'frequency', 'base_date', 'cancelled',
};

const Set<String> _myDayFields = {'id', 'task_id', 'date', 'position'};
