import 'dart:convert';

import 'data_snapshot.dart';

/// Versão atual do formato aberto e do retrato lógico (spec 07, RF-10).
const int snapshotFormatVersion = 1;

/// Versões aceitas; um conversor explícito é exigido para versões antigas
/// (spec 07, RF-13/CA-14). Hoje apenas a corrente.
const Set<int> supportedFormatVersions = {snapshotFormatVersion};

const List<String> _dataKeys = [
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

/// Codifica o retrato como JSON UTF-8 legível, indentado
/// (spec 07, RF-09/RF-10).
String encodeSnapshot(DataSnapshot snapshot) {
  final encoder = const JsonEncoder.withIndent('  ');
  return encoder.convert({
    'format_version': snapshot.formatVersion,
    'exported_at': snapshot.exportedAt,
    'data': {
      'tasks': [
        for (final t in snapshot.tasks) _taskToJson(t),
      ],
      'subtasks': [
        for (final s in snapshot.subtasks) {
          'id': s.id,
          'task_id': s.taskId,
          'title': s.title,
          'is_completed': s.isCompleted,
          'position': s.position,
        },
      ],
      'lists': [
        for (final l in snapshot.lists) {
          'id': l.id,
          'name': l.name,
          'position': l.position,
          'group_id': l.groupId,
        },
      ],
      'groups': [
        for (final g in snapshot.groups) {
          'id': g.id,
          'name': g.name,
          'position': g.position,
        },
      ],
      'categories': [
        for (final c in snapshot.categories) {'id': c.id, 'name': c.name},
      ],
      'tags': [
        for (final t in snapshot.tags) {'id': t.id, 'name': t.name},
      ],
      'task_tags': [
        for (final tt in snapshot.taskTags) {
          'task_id': tt.taskId,
          'tag_id': tt.tagId,
        },
      ],
      'recurring_series': [
        for (final s in snapshot.series) {
          'id': s.id,
          'frequency': s.frequency,
          'anchor_date': s.anchorDate,
          'active': s.active,
        },
      ],
      'my_day_entries': [
        for (final e in snapshot.myDayEntries) {
          'id': e.id,
          'task_id': e.taskId,
          'date': e.date,
          'position': e.position,
        },
      ],
    },
  });
}

Map<String, Object?> _taskToJson(TaskData t) => {
      'id': t.id,
      'title': t.title,
      'notes': t.notes,
      'status': t.status,
      'priority': t.priority,
      'due_date': t.dueDate,
      'reminder': t.reminder,
      'list_id': t.listId,
      'category_id': t.categoryId,
      'series_id': t.seriesId,
      'position': t.position,
      'created_at': t.createdAt,
      'updated_at': t.updatedAt,
      'completed_at': t.completedAt,
      'deleted_at': t.deletedAt,
    };

/// Decodifica e valida o documento (spec 07, RF-13): versão, estrutura,
/// tipos, unicidade de UUIDs e integridade de referências. Campos não
/// reconhecidos são rejeitados em vez de descartados silenciosamente.
DataSnapshot decodeSnapshot(String source) {
  Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    throw SnapshotException(SnapshotError.malformed, error.message);
  }
  if (decoded is! Map<String, dynamic>) {
    throw const SnapshotException(SnapshotError.malformed);
  }

  final root = decoded;
  _rejectUnknown(root, const {'format_version', 'exported_at', 'data'});

  final version = root['format_version'];
  if (version is! int) {
    throw const SnapshotException(SnapshotError.wrongType, 'format_version');
  }
  if (!supportedFormatVersions.contains(version)) {
    throw SnapshotException(SnapshotError.unsupportedVersion, '$version');
  }
  final exportedAt = _requireIso(root['exported_at'], 'exported_at');

  final data = root['data'];
  if (data is! Map<String, dynamic>) {
    throw const SnapshotException(SnapshotError.wrongType, 'data');
  }
  for (final key in _dataKeys) {
    if (data[key] is! List) {
      throw SnapshotException(SnapshotError.missingField, 'data.$key');
    }
  }
  _rejectUnknown(
    data,
    [for (final key in _dataKeys) key],
  );

  final tasks = _parseList(data['tasks'], 'tasks', _parseTask);
  final subtasks = _parseList(data['subtasks'], 'subtasks', _parseSubtask);
  final lists = _parseList(data['lists'], 'lists', _parseListData);
  final groups = _parseList(data['groups'], 'groups', _parseGroup);
  final categories =
      _parseList(data['categories'], 'categories', _parseCategory);
  final tags = _parseList(data['tags'], 'tags', _parseTag);
  final taskTags = _parseList(data['task_tags'], 'task_tags', _parseTaskTag);
  final series = _parseList(
      data['recurring_series'], 'recurring_series', _parseSeries);
  final myDayEntries = _parseList(
      data['my_day_entries'], 'my_day_entries', _parseMyDayEntry);

  _ensureUniqueIds('tasks', tasks.map((t) => t.id));
  _ensureUniqueIds('subtasks', subtasks.map((t) => t.id));
  _ensureUniqueIds('lists', lists.map((t) => t.id));
  _ensureUniqueIds('groups', groups.map((t) => t.id));
  _ensureUniqueIds('categories', categories.map((t) => t.id));
  _ensureUniqueIds('tags', tags.map((t) => t.id));
  _ensureUniqueIds('recurring_series', series.map((t) => t.id));
  _ensureUniqueIds('my_day_entries', myDayEntries.map((t) => t.id));

  final taskIds = tasks.map((t) => t.id).toSet();
  final listIds = lists.map((t) => t.id).toSet();
  final groupIds = groups.map((t) => t.id).toSet();
  final categoryIds = categories.map((t) => t.id).toSet();
  final tagIds = tags.map((t) => t.id).toSet();
  final seriesIds = series.map((t) => t.id).toSet();

  for (final subtask in subtasks) {
    if (!taskIds.contains(subtask.taskId)) {
      throw SnapshotException(
          SnapshotError.danglingReference, 'subtasks:${subtask.id}');
    }
  }
  for (final task in tasks) {
    if (task.listId != null && !listIds.contains(task.listId)) {
      throw SnapshotException(
          SnapshotError.danglingReference, 'tasks:${task.id}:list');
    }
    if (task.categoryId != null && !categoryIds.contains(task.categoryId)) {
      throw SnapshotException(
          SnapshotError.danglingReference, 'tasks:${task.id}:category');
    }
    if (task.seriesId != null && !seriesIds.contains(task.seriesId)) {
      throw SnapshotException(
          SnapshotError.danglingReference, 'tasks:${task.id}:series');
    }
  }
  for (final list in lists) {
    if (list.groupId != null && !groupIds.contains(list.groupId)) {
      throw SnapshotException(
          SnapshotError.danglingReference, 'lists:${list.id}:group');
    }
  }
  final taskTagKeys = <String>{};
  for (final taskTag in taskTags) {
    if (!taskIds.contains(taskTag.taskId)) {
      throw const SnapshotException(
          SnapshotError.danglingReference, 'task_tags:task');
    }
    if (!tagIds.contains(taskTag.tagId)) {
      throw const SnapshotException(
          SnapshotError.danglingReference, 'task_tags:tag');
    }
    final key = '${taskTag.taskId}|${taskTag.tagId}';
    if (!taskTagKeys.add(key)) {
      throw const SnapshotException(SnapshotError.duplicateId, 'task_tags');
    }
  }
  for (final entry in myDayEntries) {
    if (!taskIds.contains(entry.taskId)) {
      throw SnapshotException(
          SnapshotError.danglingReference, 'my_day:${entry.id}');
    }
  }

  return DataSnapshot(
    formatVersion: version,
    exportedAt: exportedAt,
    tasks: tasks,
    subtasks: subtasks,
    lists: lists,
    groups: groups,
    categories: categories,
    tags: tags,
    taskTags: taskTags,
    series: series,
    myDayEntries: myDayEntries,
  );
}

/// Calcula o resumo de apresentação (spec 07, RF-14 / CA-07).
ImportSummary summarize(DataSnapshot snapshot, {required bool isBackup}) {
  var active = 0;
  var completed = 0;
  var trashed = 0;
  for (final task in snapshot.tasks) {
    if (task.deletedAt != null) {
      trashed += 1;
    } else if (task.status == 'completed') {
      completed += 1;
    } else {
      active += 1;
    }
  }
  return ImportSummary(
    isBackup: isBackup,
    exportedAt: snapshot.exportedAt,
    activeTasks: active,
    completedTasks: completed,
    trashedTasks: trashed,
    subtasks: snapshot.subtasks.length,
    lists: snapshot.lists.length,
    groups: snapshot.groups.length,
    categories: snapshot.categories.length,
    tags: snapshot.tags.length,
    series: snapshot.series.length,
    myDayEntries: snapshot.myDayEntries.length,
  );
}

// ---------------------------------------------------------------- tipos

void _rejectUnknown(Map<String, dynamic> map, Iterable<String> known) {
  final knownSet = known.toSet();
  for (final key in map.keys) {
    if (!knownSet.contains(key)) {
      throw SnapshotException(SnapshotError.unknownField, key);
    }
  }
}

String _requireString(Object? value, String field) {
  if (value is! String || value.isEmpty) {
    throw SnapshotException(SnapshotError.wrongType, field);
  }
  return value;
}

String? _optionalString(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) {
    throw SnapshotException(SnapshotError.wrongType, field);
  }
  return value;
}

int _requireInt(Object? value, String field) {
  if (value is! int) {
    throw SnapshotException(SnapshotError.wrongType, field);
  }
  return value;
}

bool _requireBool(Object? value, String field) {
  if (value is! bool) {
    throw SnapshotException(SnapshotError.wrongType, field);
  }
  return value;
}

String _requireIso(Object? value, String field) {
  final text = _requireString(value, field);
  try {
    DateTime.parse(text);
  } on FormatException {
    throw SnapshotException(SnapshotError.wrongType, field);
  }
  return text;
}

void _ensureEnum(String value, Set<String> allowed, String field) {
  if (!allowed.contains(value)) {
    throw SnapshotException(SnapshotError.wrongType, field);
  }
}

void _ensureUniqueIds(String collection, Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw SnapshotException(SnapshotError.duplicateId, '$collection:$id');
    }
  }
}

List<T> _parseList<T>(
  Object? raw,
  String field,
  T Function(Map<String, dynamic>) parse,
) {
  if (raw is! List) {
    throw SnapshotException(SnapshotError.missingField, field);
  }
  final result = <T>[];
  for (final item in raw) {
    if (item is! Map<String, dynamic>) {
      throw SnapshotException(SnapshotError.wrongType, field);
    }
    result.add(parse(item));
  }
  return result;
}

TaskData _parseTask(Map<String, dynamic> map) {
  _rejectUnknown(map, const {
    'id', 'title', 'notes', 'status', 'priority', 'due_date', 'reminder',
    'list_id', 'category_id', 'series_id', 'position', 'created_at',
    'updated_at', 'completed_at', 'deleted_at',
  });
  final status = _requireString(map['status'], 'tasks.status');
  _ensureEnum(status, const {'active', 'completed'}, 'tasks.status');
  final priority = _requireString(map['priority'], 'tasks.priority');
  _ensureEnum(
      priority, const {'low', 'medium', 'high', 'urgent'}, 'tasks.priority');
  final dueDate = _optionalString(map['due_date'], 'tasks.due_date');
  if (dueDate != null && !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dueDate)) {
    throw const SnapshotException(
        SnapshotError.wrongType, 'tasks.due_date');
  }
  final reminder = map['reminder'];
  return TaskData(
    id: _requireString(map['id'], 'tasks.id'),
    title: _requireString(map['title'], 'tasks.title'),
    notes: _optionalString(map['notes'], 'tasks.notes'),
    status: status,
    priority: priority,
    dueDate: dueDate,
    reminder: reminder == null
        ? null
        : _requireIso(reminder, 'tasks.reminder'),
    listId: _optionalString(map['list_id'], 'tasks.list_id'),
    categoryId: _optionalString(map['category_id'], 'tasks.category_id'),
    seriesId: _optionalString(map['series_id'], 'tasks.series_id'),
    position: _requireInt(map['position'], 'tasks.position'),
    createdAt: _requireIso(map['created_at'], 'tasks.created_at'),
    updatedAt: map['updated_at'] == null
        ? null
        : _requireIso(map['updated_at'], 'tasks.updated_at'),
    completedAt: map['completed_at'] == null
        ? null
        : _requireIso(map['completed_at'], 'tasks.completed_at'),
    deletedAt: map['deleted_at'] == null
        ? null
        : _requireIso(map['deleted_at'], 'tasks.deleted_at'),
  );
}

SubtaskData _parseSubtask(Map<String, dynamic> map) {
  _rejectUnknown(map, const {
    'id', 'task_id', 'title', 'is_completed', 'position',
  });
  return SubtaskData(
    id: _requireString(map['id'], 'subtasks.id'),
    taskId: _requireString(map['task_id'], 'subtasks.task_id'),
    title: _requireString(map['title'], 'subtasks.title'),
    isCompleted: _requireBool(map['is_completed'], 'subtasks.is_completed'),
    position: _requireInt(map['position'], 'subtasks.position'),
  );
}

ListData _parseListData(Map<String, dynamic> map) {
  _rejectUnknown(map, const {'id', 'name', 'position', 'group_id'});
  return ListData(
    id: _requireString(map['id'], 'lists.id'),
    name: _requireString(map['name'], 'lists.name'),
    position: _requireInt(map['position'], 'lists.position'),
    groupId: _optionalString(map['group_id'], 'lists.group_id'),
  );
}

GroupData _parseGroup(Map<String, dynamic> map) {
  _rejectUnknown(map, const {'id', 'name', 'position'});
  return GroupData(
    id: _requireString(map['id'], 'groups.id'),
    name: _requireString(map['name'], 'groups.name'),
    position: _requireInt(map['position'], 'groups.position'),
  );
}

CategoryData _parseCategory(Map<String, dynamic> map) {
  _rejectUnknown(map, const {'id', 'name'});
  return CategoryData(
    id: _requireString(map['id'], 'categories.id'),
    name: _requireString(map['name'], 'categories.name'),
  );
}

TagData _parseTag(Map<String, dynamic> map) {
  _rejectUnknown(map, const {'id', 'name'});
  return TagData(
    id: _requireString(map['id'], 'tags.id'),
    name: _requireString(map['name'], 'tags.name'),
  );
}

TaskTagData _parseTaskTag(Map<String, dynamic> map) {
  _rejectUnknown(map, const {'task_id', 'tag_id'});
  return TaskTagData(
    taskId: _requireString(map['task_id'], 'task_tags.task_id'),
    tagId: _requireString(map['tag_id'], 'task_tags.tag_id'),
  );
}

SeriesData _parseSeries(Map<String, dynamic> map) {
  _rejectUnknown(map, const {'id', 'frequency', 'anchor_date', 'active'});
  final frequency =
      _requireString(map['frequency'], 'recurring_series.frequency');
  _ensureEnum(frequency, const {
    'daily', 'weekdays', 'weekly', 'monthly', 'yearly',
  }, 'recurring_series.frequency');
  final anchor = _requireString(map['anchor_date'], 'recurring_series.anchor');
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(anchor)) {
    throw const SnapshotException(
        SnapshotError.wrongType, 'recurring_series.anchor_date');
  }
  return SeriesData(
    id: _requireString(map['id'], 'recurring_series.id'),
    frequency: frequency,
    anchorDate: anchor,
    active: _requireBool(map['active'], 'recurring_series.active'),
  );
}

MyDayEntryData _parseMyDayEntry(Map<String, dynamic> map) {
  _rejectUnknown(map, const {'id', 'task_id', 'date', 'position'});
  final date = _requireString(map['date'], 'my_day_entries.date');
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
    throw const SnapshotException(SnapshotError.wrongType, 'my_day_entries.date');
  }
  return MyDayEntryData(
    id: _requireString(map['id'], 'my_day_entries.id'),
    taskId: _requireString(map['task_id'], 'my_day_entries.task_id'),
    date: date,
    position: _requireInt(map['position'], 'my_day_entries.position'),
  );
}
