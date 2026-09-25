import 'package:urutau_tasks/src/core/ids.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// Data fixa para testes determinísticos.
final DateTime kTestNow = DateTime.utc(2026, 9, 25, 12);

/// Cria uma tarefa com [title], [status] e campos opcionais.
Task buildTask({
  String? id,
  String title = 'Tarefa',
  String notes = '',
  TaskStatus status = TaskStatus.active,
  TaskPriority? priority,
  String? dueDate,
  DateTime? reminder,
  int position = 0,
  DateTime? createdAt,
  DateTime? completedAt,
  List<Subtask> subtasks = const [],
}) {
  var result = Task.create(
    id: id ?? newId(),
    title: title,
    notes: notes,
    createdAt: createdAt ?? kTestNow,
    position: position,
    priority: priority,
    dueDate: dueDate,
    reminder: reminder,
  );
  for (final subtask in subtasks) {
    result = result.addSubtask(
      id: subtask.id,
      description: subtask.description,
    );
  }
  if (status == TaskStatus.completed) {
    result = result.complete(at: completedAt ?? kTestNow);
  } else if (status == TaskStatus.trash) {
    result = result.moveToTrash(at: kTestNow);
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
