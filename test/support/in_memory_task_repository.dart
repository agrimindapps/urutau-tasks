import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task_repository.dart';

/// Repositório em memória para testes de serviço, sem depender de banco
/// real (spec 06, RF-26).
class InMemoryTaskRepository implements TaskRepository {
  final _tasks = <String, Task>{};

  @override
  Stream<List<Task>> watchTasks({bool includeTrashed = false}) async* {
    yield _sorted(includeTrashed: includeTrashed);
  }

  @override
  Stream<Task?> watchTask(String id) async* {
    yield _tasks[id];
  }

  @override
  Future<Task?> getTask(String id) async => _tasks[id];

  @override
  Future<void> insertTask(Task task) async {
    if (_tasks.containsKey(task.id)) {
      throw StateError('Duplicate task id: ${task.id}');
    }
    _tasks[task.id] = task;
  }

  @override
  Future<void> saveTask(Task task) async {
    if (!_tasks.containsKey(task.id)) {
      throw StateError('Unknown task id: ${task.id}');
    }
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteSubtask(String subtaskId) async {
    for (final entry in _tasks.entries.toList()) {
      final task = entry.value;
      if (task.subtasks.any((s) => s.id == subtaskId)) {
        _tasks[entry.key] = task.copyWith(
          subtasks: task.subtasks.where((s) => s.id != subtaskId).toList(),
        );
      }
    }
  }

  Iterable<Task> get allTasks => _tasks.values;

  int countInList(String listId) =>
      _tasks.values.where((t) => t.listId == listId).length;

  void moveTasksToList(String sourceId, String destinationId) {
    for (final entry in _tasks.entries.toList()) {
      final task = entry.value;
      if (task.listId == sourceId) {
        _tasks[entry.key] = task.copyWith(listId: destinationId);
      }
    }
  }

  void unbindCategory(String categoryId) {
    for (final entry in _tasks.entries.toList()) {
      final task = entry.value;
      if (task.categoryId == categoryId) {
        _tasks[entry.key] = task.copyWith(clearCategoryId: true);
      }
    }
  }

  void removeTagEverywhere(String tagId) {
    for (final entry in _tasks.entries.toList()) {
      final task = entry.value;
      final kept = task.tags.where((t) => t.id != tagId).toList();
      if (kept.length != task.tags.length) {
        _tasks[entry.key] = task.copyWith(tags: kept);
      }
    }
  }

  void updateTask(Task task) {
    if (!_tasks.containsKey(task.id)) {
      throw StateError('Unknown task id: ${task.id}');
    }
    _tasks[task.id] = task;
  }

  Task? taskById(String id) => _tasks[id];

  @override
  Future<int> nextTaskPosition() async =>
      _tasks.values.isEmpty
          ? 0
          : _tasks.values.map((t) => t.position).reduce((a, b) => a > b ? a : b) + 1;

  @override
  Future<int> nextSubtaskPosition(String taskId) async {
    final subtasks = _tasks[taskId]?.subtasks ?? const [];
    if (subtasks.isEmpty) return 0;
    return subtasks.map((s) => s.position).reduce((a, b) => a > b ? a : b) + 1;
  }

  List<Task> _sorted({required bool includeTrashed}) {
    final values = _tasks.values
        .where((t) => includeTrashed || !t.isDeleted)
        .toList()
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        if (byPosition != 0) return byPosition;
        return a.createdAt.compareTo(b.createdAt);
      });
    return values;
  }
}
