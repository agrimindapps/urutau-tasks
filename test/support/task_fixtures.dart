import 'package:urutau_tasks/src/core/ids.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// Data fixa para testes determinísticos.
final DateTime kTestNow = DateTime.utc(2026, 9, 25, 12);

/// Cria uma tarefa ativa com [title] e [notes] opcionais.
Task buildTask({
  String? id,
  String title = 'Tarefa',
  String notes = '',
  TaskStatus status = TaskStatus.active,
  int position = 0,
  DateTime? createdAt,
  List<Subtask> subtasks = const [],
}) {
  final task = Task.create(
    id: id ?? newId(),
    title: title,
    notes: notes,
    createdAt: createdAt ?? kTestNow,
    position: position,
  );
  var result = task;
  for (final subtask in subtasks) {
    result = result.addSubtask(
      id: subtask.id,
      description: subtask.description,
    );
  }
  return result;
}

/// Cria uma subtarefa avulsa para composição manual.
Subtask buildSubtask({
  String? id,
  required String taskId,
  String description = 'Etapa',
  bool isCompleted = false,
  int position = 0,
}) {
  return Subtask(
    id: id ?? newId(),
    taskId: taskId,
    description: description,
    isCompleted: isCompleted,
    position: position,
  );
}
