import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../organization/domain/organization.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Implementação Drift do repositório de tarefas.
///
/// Todas as escritas que envolvem mais de um registro usam transação
/// (spec 06, RF-04).
class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Task>> watchTasks({bool includeTrashed = false}) {
    final query = _db.select(_db.tasks)
      ..orderBy([
        (t) => OrderingTerm.asc(t.position),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);
    if (!includeTrashed) {
      query.where((t) => t.deletedAt.isNull());
    }
    return query.watch().asyncMap((rows) async {
      final ids = rows.map((r) => r.id).toList();
      final subtasksByTask = await _loadSubtasks(ids);
      final tagsByTask = await _loadTags(ids);
      return [
        for (final row in rows)
          _toTask(row, subtasksByTask[row.id] ?? const [],
              tagsByTask[row.id] ?? const []),
      ];
    });
  }

  @override
  Stream<Task?> watchTask(String id) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final subtasks = await _loadSubtasks([id]);
      final tags = await _loadTags([id]);
      return _toTask(row, subtasks[id] ?? const [], tags[id] ?? const []);
    });
  }

  @override
  Future<Task?> getTask(String id) async {
    final row = await (_db.select(_db.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final subtasks = await _loadSubtasks([id]);
    final tags = await _loadTags([id]);
    return _toTask(row, subtasks[id] ?? const [], tags[id] ?? const []);
  }

  @override
  Future<void> insertTask(Task task) {
    return _db.transaction(() async {
      await _db.into(_db.tasks).insert(_taskCompanion(task));
      if (task.subtasks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.subtasks, [
            for (final subtask in task.subtasks) _subtaskCompanion(subtask),
          ]);
        });
      }
      await _writeTags(task);
    });
  }

  @override
  Future<void> saveTask(Task task) {
    return _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id)))
          .write(_taskCompanion(task, forUpdate: true));
      await (_db.delete(_db.subtasks)..where((s) => s.taskId.equals(task.id)))
          .go();
      if (task.subtasks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.subtasks, [
            for (final subtask in task.subtasks) _subtaskCompanion(subtask),
          ]);
        });
      }
      await _writeTags(task);
    });
  }

  Future<void> _writeTags(Task task) async {
    await (_db.delete(_db.taskTags)..where((tt) => tt.taskId.equals(task.id)))
        .go();
    if (task.tags.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(_db.taskTags, [
          for (final tag in task.tags)
            TaskTagsCompanion.insert(taskId: task.id, tagId: tag.id),
        ]);
      });
    }
  }

  @override
  Future<void> deleteSubtask(String subtaskId) {
    return _db.transaction(() async {
      await (_db.delete(_db.subtasks)..where((s) => s.id.equals(subtaskId)))
          .go();
    });
  }

  @override
  Future<int> nextTaskPosition() async {
    final max = _db.tasks.position.max();
    final query = _db.selectOnly(_db.tasks)..addColumns([max]);
    final row = await query.getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  @override
  Future<int> nextSubtaskPosition(String taskId) async {
    final max = _db.subtasks.position.max();
    final query = _db.selectOnly(_db.subtasks)
      ..addColumns([max])
      ..where(_db.subtasks.taskId.equals(taskId));
    final row = await query.getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<Map<String, List<Subtask>>> _loadSubtasks(
    Iterable<String> taskIds,
  ) async {
    final ids = taskIds.toList();
    if (ids.isEmpty) return {};
    final rows = await (_db.select(_db.subtasks)
          ..where((s) => s.taskId.isIn(ids))
          ..orderBy([
            (s) => OrderingTerm.asc(s.position),
            (s) => OrderingTerm.asc(s.id),
          ]))
        .get();
    final result = <String, List<Subtask>>{};
    for (final row in rows) {
      (result[row.taskId] ??= []).add(
        Subtask(
          id: row.id,
          taskId: row.taskId,
          title: row.title,
          isCompleted: row.isCompleted,
          position: row.position,
        ),
      );
    }
    return result;
  }

  Future<Map<String, List<Tag>>> _loadTags(Iterable<String> taskIds) async {
    final ids = taskIds.toList();
    if (ids.isEmpty) return {};
    final query = _db.select(_db.taskTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.taskTags.tagId)),
    ])
      ..where(_db.taskTags.taskId.isIn(ids))
      ..orderBy([
        OrderingTerm.asc(_db.tags.name),
      ]);
    final rows = await query.get();
    final result = <String, List<Tag>>{};
    for (final row in rows) {
      final taskId = row.readTable(_db.taskTags).taskId;
      final tag = row.readTable(_db.tags);
      (result[taskId] ??= []).add(Tag(id: tag.id, name: tag.name));
    }
    return result;
  }

  Task _toTask(
    TaskRecord row,
    List<Subtask> subtasks,
    List<Tag> tags,
  ) {
    return Task(
      id: row.id,
      title: row.title,
      notes: row.notes,
      status: row.status == 'completed'
          ? TaskStatus.completed
          : TaskStatus.active,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      completedAt: row.completedAt,
      deletedAt: row.deletedAt,
      position: row.position,
      priority: Priority.parse(row.priority),
      dueDate: _decodeDate(row.dueDate),
      reminder: row.reminder,
      listId: row.listId,
      categoryId: row.categoryId,
      seriesId: row.seriesId,
      subtasks: subtasks,
      tags: tags,
    );
  }

  TasksCompanion _taskCompanion(Task task, {bool forUpdate = false}) {
    final status = Value(
      task.status == TaskStatus.completed ? 'completed' : 'active',
    );
    if (forUpdate) {
      return TasksCompanion(
        title: Value(task.title),
        notes: Value(task.notes),
        status: status,
        createdAt: Value(task.createdAt),
        updatedAt: Value(task.updatedAt),
        completedAt: Value(task.completedAt),
        deletedAt: Value(task.deletedAt),
        position: Value(task.position),
        priority: Value(task.priority.storedName),
        dueDate: Value(_encodeDate(task.dueDate)),
        reminder: Value(task.reminder),
        listId: Value(task.listId),
        categoryId: Value(task.categoryId),
        seriesId: Value(task.seriesId),
      );
    }
    return TasksCompanion.insert(
      id: task.id,
      title: task.title,
      notes: Value(task.notes),
      status: status,
      createdAt: task.createdAt,
      updatedAt: Value(task.updatedAt),
      completedAt: Value(task.completedAt),
      deletedAt: Value(task.deletedAt),
      position: Value(task.position),
      priority: Value(task.priority.storedName),
      dueDate: Value(_encodeDate(task.dueDate)),
      reminder: Value(task.reminder),
      listId: Value(task.listId),
      categoryId: Value(task.categoryId),
      seriesId: Value(task.seriesId),
    );
  }

  /// Prazo persistido como data de calendário `yyyy-MM-dd` (spec 06, RF-11).
  static String? _encodeDate(DateTime? dueDate) {
    if (dueDate == null) return null;
    final local = dueDate.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static DateTime? _decodeDate(String? encoded) {
    if (encoded == null) return null;
    final parts = encoded.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  SubtasksCompanion _subtaskCompanion(Subtask subtask) {
    return SubtasksCompanion.insert(
      id: subtask.id,
      taskId: subtask.taskId,
      title: subtask.title,
      isCompleted: Value(subtask.isCompleted),
      position: Value(subtask.position),
    );
  }
}
