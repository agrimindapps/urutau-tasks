import 'dart:async';

import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task_repository.dart';

/// Repositório em memória para testes de serviço e interface
/// (spec 06, RF-26: banco isolado, sem ordem de execução).
class InMemoryTaskRepository implements TaskRepository {
  final _tasks = <String, Task>{};
  final _controller = StreamController<List<Task>>.broadcast();

  List<Task> _snapshot() {
    return _tasks.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  void _notify() => _controller.add(_snapshot());

  @override
  Future<List<Task>> fetchAll() async => _snapshot();

  @override
  Stream<List<Task>> watchAll() async* {
    yield _snapshot();
    yield* _controller.stream;
  }

  @override
  Future<Task?> fetchById(String id) async => _tasks[id];

  @override
  Future<void> saveTask(Task task) async {
    _tasks[task.id] = task;
    _notify();
  }

  @override
  Future<void> removeSubtask(String subtaskId) async {
    for (final entry in _tasks.entries.toList()) {
      final task = entry.value;
      if (task.subtasks.any((s) => s.id == subtaskId)) {
        _tasks[entry.key] = task.removeSubtask(subtaskId);
      }
    }
    _notify();
  }

  /// Acesso direto às tarefas armazenadas para asserções.
  Iterable<Task> get allTasks => _tasks.values;
}
