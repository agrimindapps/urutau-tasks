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
    final subtaskRows = await _db.select(_db.subtasks).get();
    return _assemble(taskRows, subtaskRows);
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
    return query.watch().map((rows) {
      final byTask = <String, List<Subtask>>{};
      final taskById = <String, TaskRow>{};
      for (final row in rows) {
        final task = row.readTable(_db.tasks);
        taskById[task.id] = task;
        final subtask = row.readTableOrNull(_db.subtasks);
        if (subtask != null) {
          (byTask[task.id] ??= []).add(_toSubtask(subtask));
        }
      }
      return [
        for (final task in taskById.values)
          _toTask(task, byTask[task.id] ?? const []),
      ]..sort((a, b) => a.position.compareTo(b.position));
    });
  }

  List<Task> _assemble(List<TaskRow> taskRows, List<SubtaskRow> subtaskRows) {
    final byTask = <String, List<Subtask>>{};
    for (final row in subtaskRows) {
      (byTask[row.taskId] ??= []).add(_toSubtask(row));
    }
    return [
      for (final row in taskRows) _toTask(row, byTask[row.id] ?? const []),
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
    return _toTask(row, subtaskRows.map(_toSubtask).toList());
  }

  @override
  Future<void> saveTask(Task task) async {
    // Escrita composta atômica (spec 06, RF-04): tarefa + subtarefas.
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

  Task _toTask(TaskRow row, List<Subtask> subtasks) {
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
