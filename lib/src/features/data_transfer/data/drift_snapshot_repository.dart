import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../domain/data_snapshot.dart';

/// Exporta e importa o retrato lógico completo (spec 07, RF-01/RF-03/RF-16).
class DriftSnapshotRepository {
  DriftSnapshotRepository(this._db);

  final AppDatabase _db;

  /// Coleta o estado completo, incluindo lixeira e histórico
  /// (spec 07, RF-01).
  Future<DataSnapshot> exportSnapshot({DateTime? exportedAt}) async {
    final taskRows = await _db.select(_db.tasks).get();
    final subtaskRows = await _db.select(_db.subtasks).get();
    final listRows = await _db.select(_db.taskLists).get();
    final groupRows = await _db.select(_db.groups).get();
    final categoryRows = await _db.select(_db.categories).get();
    final tagRows = await _db.select(_db.tags).get();
    final taskTagRows = await _db.select(_db.taskTags).get();
    final seriesRows = await _db.select(_db.series).get();
    final myDayRows = await _db.select(_db.myDayEntries).get();

    return DataSnapshot(
      exportedAt: exportedAt ?? DateTime.now().toUtc(),
      tasks: [for (final row in taskRows) _taskToMap(row)],
      subtasks: [for (final row in subtaskRows) _subtaskToMap(row)],
      lists: [for (final row in listRows) _listToMap(row)],
      groups: [for (final row in groupRows) _groupToMap(row)],
      categories: [for (final row in categoryRows) _categoryToMap(row)],
      tags: [for (final row in tagRows) _tagToMap(row)],
      taskTags: [for (final row in taskTagRows) _taskTagToMap(row)],
      recurringSeries: [for (final row in seriesRows) _seriesToMap(row)],
      myDayEntries: [for (final row in myDayRows) _myDayToMap(row)],
    );
  }

  /// Substituição integral em uma única transação com rollback em falha
  /// (spec 07, RF-12/RF-16). Os UUIDs e referências são preservados
  /// (RF-03).
  Future<void> replaceAll(DataSnapshot snapshot) async {
    await _db.transaction(() async {
      // Ordem respeita as chaves estrangeiras.
      await _db.delete(_db.taskTags).go();
      await _db.delete(_db.subtasks).go();
      await _db.delete(_db.myDayEntries).go();
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.taskLists).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.tags).go();
      await _db.delete(_db.groups).go();
      await _db.delete(_db.series).go();

      for (final row in snapshot.groups) {
        await _db.into(_db.groups).insert(_groupFromMap(row));
      }
      for (final row in snapshot.lists) {
        await _db.into(_db.taskLists).insert(_listFromMap(row));
      }
      for (final row in snapshot.categories) {
        await _db.into(_db.categories).insert(_categoryFromMap(row));
      }
      for (final row in snapshot.tags) {
        await _db.into(_db.tags).insert(_tagFromMap(row));
      }
      for (final row in snapshot.recurringSeries) {
        await _db.into(_db.series).insert(_seriesFromMap(row));
      }
      for (final row in snapshot.tasks) {
        await _db.into(_db.tasks).insert(_taskFromMap(row));
      }
      for (final row in snapshot.subtasks) {
        await _db.into(_db.subtasks).insert(_subtaskFromMap(row));
      }
      for (final row in snapshot.taskTags) {
        await _db.into(_db.taskTags).insert(_taskTagFromMap(row));
      }
      for (final row in snapshot.myDayEntries) {
        await _db.into(_db.myDayEntries).insert(_myDayFromMap(row));
      }
    });
  }

  Map<String, Object?> _taskToMap(TaskRow row) => {
        'id': row.id,
        'title': row.title,
        'notes': row.notes,
        'status': row.status,
        'status_before_trash': row.statusBeforeTrash,
        'created_at': row.createdAt.toUtc().toIso8601String(),
        'updated_at': row.updatedAt.toUtc().toIso8601String(),
        'completed_at': row.completedAt?.toUtc().toIso8601String(),
        'position': row.position,
        'list_id': row.listId,
        'category_id': row.categoryId,
        'priority': row.priority,
        'due_date': row.dueDate,
        'reminder': row.reminder?.toUtc().toIso8601String(),
        'series_id': row.seriesId,
      };

  TasksCompanion _taskFromMap(Map<String, Object?> map) {
    return TasksCompanion.insert(
      id: map['id']! as String,
      title: map['title']! as String,
      notes: Value((map['notes'] ?? '') as String),
      status: map['status']! as String,
      statusBeforeTrash: Value(map['status_before_trash'] as String?),
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      completedAt: Value(_instant(map['completed_at'])),
      position: Value((map['position'] ?? 0) as int),
      listId: Value(map['list_id'] as String?),
      categoryId: Value(map['category_id'] as String?),
      priority: Value(map['priority'] as String?),
      dueDate: Value(map['due_date'] as String?),
      reminder: Value(_instant(map['reminder'])),
      seriesId: Value(map['series_id'] as String?),
    );
  }

  Map<String, Object?> _subtaskToMap(SubtaskRow row) => {
        'id': row.id,
        'task_id': row.taskId,
        'description': row.description,
        'is_completed': row.isCompleted,
        'position': row.position,
      };

  SubtasksCompanion _subtaskFromMap(Map<String, Object?> map) {
    return SubtasksCompanion.insert(
      id: map['id']! as String,
      taskId: map['task_id']! as String,
      description: map['description']! as String,
      isCompleted: Value((map['is_completed'] ?? false) as bool),
      position: Value((map['position'] ?? 0) as int),
    );
  }

  Map<String, Object?> _listToMap(TaskListRow row) => {
        'id': row.id,
        'name': row.name,
        'position': row.position,
        'group_id': row.groupId,
      };

  TaskListsCompanion _listFromMap(Map<String, Object?> map) {
    return TaskListsCompanion.insert(
      id: map['id']! as String,
      name: map['name']! as String,
      position: Value((map['position'] ?? 0) as int),
      groupId: Value(map['group_id'] as String?),
    );
  }

  Map<String, Object?> _groupToMap(GroupRow row) => {
        'id': row.id,
        'name': row.name,
        'position': row.position,
      };

  GroupsCompanion _groupFromMap(Map<String, Object?> map) {
    return GroupsCompanion.insert(
      id: map['id']! as String,
      name: map['name']! as String,
      position: Value((map['position'] ?? 0) as int),
    );
  }

  Map<String, Object?> _categoryToMap(CategoryRow row) => {
        'id': row.id,
        'name': row.name,
      };

  CategoriesCompanion _categoryFromMap(Map<String, Object?> map) {
    return CategoriesCompanion.insert(
      id: map['id']! as String,
      name: map['name']! as String,
    );
  }

  Map<String, Object?> _tagToMap(TagRow row) => {
        'id': row.id,
        'name': row.name,
        'normalized_name': row.normalizedName,
      };

  TagsCompanion _tagFromMap(Map<String, Object?> map) {
    return TagsCompanion.insert(
      id: map['id']! as String,
      name: map['name']! as String,
      normalizedName: map['normalized_name']! as String,
    );
  }

  Map<String, Object?> _taskTagToMap(TaskTagRow row) => {
        'task_id': row.taskId,
        'tag_id': row.tagId,
      };

  TaskTagsCompanion _taskTagFromMap(Map<String, Object?> map) {
    return TaskTagsCompanion.insert(
      taskId: map['task_id']! as String,
      tagId: map['tag_id']! as String,
    );
  }

  Map<String, Object?> _seriesToMap(SeriesRow row) => {
        'id': row.id,
        'frequency': row.frequency,
        'base_date': row.baseDate,
        'cancelled': row.cancelled,
      };

  SeriesCompanion _seriesFromMap(Map<String, Object?> map) {
    return SeriesCompanion.insert(
      id: map['id']! as String,
      frequency: map['frequency']! as String,
      baseDate: map['base_date']! as String,
      cancelled: Value((map['cancelled'] ?? false) as bool),
    );
  }

  Map<String, Object?> _myDayToMap(MyDayEntryRow row) => {
        'id': row.id,
        'task_id': row.taskId,
        'date': row.date,
        'position': row.position,
      };

  MyDayEntriesCompanion _myDayFromMap(Map<String, Object?> map) {
    return MyDayEntriesCompanion.insert(
      id: map['id']! as String,
      taskId: map['task_id']! as String,
      date: map['date']! as String,
      position: Value((map['position'] ?? 0) as int),
    );
  }

  DateTime? _instant(Object? raw) =>
      raw == null ? null : DateTime.parse(raw as String);
}
