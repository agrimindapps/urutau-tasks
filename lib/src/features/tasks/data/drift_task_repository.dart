import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Persistência Drift das tarefas (spec 06, RF-05/RF-06/RF-21).
class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Task>> fetchAll() async {
    final taskRows = await _db.select(_db.tasks).get();
    return _assemble(taskRows, await _loadSubtasks(), await _loadTags());
  }

  @override
  Stream<List<Task>> watchAll() {
    // Join reage a mudanças em tarefas e em subtarefas.
    final query = _db.select(_db.tasks).join([
      leftOuterJoin(
        _db.subtasks,
        _db.subtasks.taskId.equalsExp(_db.tasks.id),
      ),
    ]);
    return query.watch().asyncMap((rows) async {
      final taskById = <String, TaskRow>{};
      for (final row in rows) {
        taskById[row.readTable(_db.tasks).id] = row.readTable(_db.tasks);
      }
      return _assemble(taskById.values.toList(), await _loadSubtasks(),
          await _loadTags());
    });
  }

  Future<Map<String, List<Subtask>>> _loadSubtasks() async {
    final rows = await _db.select(_db.subtasks).get();
    final byTask = <String, List<Subtask>>{};
    for (final row in rows) {
      (byTask[row.taskId] ??= []).add(_toSubtask(row));
    }
    return byTask;
  }

  Future<Map<String, List<String>>> _loadTags() async {
    final rows = await _db.select(_db.taskTags).get();
    final byTask = <String, List<String>>{};
    for (final row in rows) {
      (byTask[row.taskId] ??= []).add(row.tagId);
    }
    return byTask;
  }

  List<Task> _assemble(
    List<TaskRow> taskRows,
    Map<String, List<Subtask>> subtasksByTask,
    Map<String, List<String>> tagsByTask,
  ) {
    return [
      for (final row in taskRows)
        _toTask(
          row,
          subtasksByTask[row.id] ?? const [],
          tagsByTask[row.id] ?? const [],
        ),
    ]..sort((a, b) => a.position.compareTo(b.position));
  }

  @override
  Future<Task?> fetchById(String id) async {
    final row = await (_db.select(_db.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final subtaskRows = await (_db.select(_db.subtasks)
          ..where((s) => s.taskId.equals(id)))
        .get();
    final tagRows = await (_db.select(_db.taskTags)
          ..where((t) => t.taskId.equals(id)))
        .get();
    return _toTask(
      row,
      subtaskRows.map(_toSubtask).toList(),
      tagRows.map((r) => r.tagId).toList(),
    );
  }

  @override
  Future<void> saveTask(Task task) async {
    // Escrita composta atômica (spec 06, RF-04): tarefa + subtarefas + tags.
    await _db.transaction(() async {
      await _db.into(_db.tasks).insertOnConflictUpdate(_toCompanion(task));
      final existing = await (_db.select(_db.subtasks)
            ..where((s) => s.taskId.equals(task.id)))
          .get();
      final keep = {for (final s in task.subtasks) s.id};
      for (final row in existing) {
        if (!keep.contains(row.id)) {
          await (_db.delete(_db.subtasks)
                ..where((s) => s.id.equals(row.id)))
              .go();
        }
      }
      for (final subtask in task.subtasks) {
        await _db
            .into(_db.subtasks)
            .insertOnConflictUpdate(_toSubtaskCompanion(subtask));
      }
      await (_db.delete(_db.taskTags)
            ..where((t) => t.taskId.equals(task.id)))
          .go();
      for (final tagId in task.tagIds) {
        await _db.into(_db.taskTags).insertOnConflictUpdate(
              TaskTagsCompanion.insert(taskId: task.id, tagId: tagId),
            );
      }
    });
  }

  @override
  Future<void> removeSubtask(String subtaskId) async {
    // Exclusão física em transação (spec 01, RF-07; spec 06, RF-06).
    await _db.transaction(() async {
      await (_db.delete(_db.subtasks)..where((s) => s.id.equals(subtaskId)))
          .go();
    });
  }

  Task _toTask(TaskRow row, List<Subtask> subtasks, List<String> tagIds) {
    return Task(
      id: row.id,
      title: row.title,
      notes: row.notes,
      status: _statusFromName(row.status),
      statusBeforeTrash: row.statusBeforeTrash == null
          ? null
          : _statusFromName(row.statusBeforeTrash!),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      completedAt: row.completedAt,
      position: row.position,
      subtasks: subtasks,
      listId: row.listId,
      categoryId: row.categoryId,
      tagIds: tagIds,
    );
  }

  Subtask _toSubtask(SubtaskRow row) {
    return Subtask(
      id: row.id,
      taskId: row.taskId,
      description: row.description,
      isCompleted: row.isCompleted,
      position: row.position,
    );
  }

  TasksCompanion _toCompanion(Task task) {
    return TasksCompanion.insert(
      id: task.id,
      title: task.title,
      notes: Value(task.notes),
      status: task.status.name,
      statusBeforeTrash: Value(task.statusBeforeTrash?.name),
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      completedAt: Value(task.completedAt),
      position: Value(task.position),
      listId: Value(task.listId),
      categoryId: Value(task.categoryId),
    );
  }

  SubtasksCompanion _toSubtaskCompanion(Subtask subtask) {
    return SubtasksCompanion.insert(
      id: subtask.id,
      taskId: subtask.taskId,
      description: subtask.description,
      isCompleted: Value(subtask.isCompleted),
      position: Value(subtask.position),
    );
  }

  TaskStatus _statusFromName(String name) {
    return TaskStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => throw StateError('Status desconhecido: $name'),
    );
  }
}
