import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

class _TaskBuilder {
  _TaskBuilder({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes,
    this.status = TaskStatus.active,
    this.updatedAt,
    this.completedAt,
    this.deletedAt,
    this.position = 0,
    this.priority = Priority.medium,
    this.dueDate,
    this.reminder,
    this.listId,
    this.categoryId,
    List<Tag>? tags,
    this.seriesId,
    List<Subtask>? subtasks,
  })  : _tags = List.of(tags ?? const <Tag>[]),
        _subtasks = List.of(subtasks ?? const <Subtask>[]);

  final String id;
  final String title;
  final String? notes;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final int position;
  final Priority priority;
  final DateTime? dueDate;
  final DateTime? reminder;
  final String? listId;
  final String? categoryId;
  final List<Tag> _tags;
  final String? seriesId;
  final List<Subtask> _subtasks;

  Task build() => Task(
        id: id,
        title: title,
        notes: notes,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: completedAt,
        deletedAt: deletedAt,
        position: position,
        priority: priority,
        dueDate: dueDate,
        reminder: reminder,
        listId: listId,
        categoryId: categoryId,
        tags: _tags,
        seriesId: seriesId,
        subtasks: _subtasks,
      );
}

/// Auxiliar de testes para montar tarefas com subtarefas.
Task buildTestTask({
  String id = 'task-1',
  String title = 'Sample task',
  String? notes,
  TaskStatus status = TaskStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
  DateTime? deletedAt,
  int position = 0,
  Priority priority = Priority.medium,
  DateTime? dueDate,
  DateTime? reminder,
  String? listId,
  String? categoryId,
  List<Tag> tags = const [],
  String? seriesId,
  List<Subtask> subtasks = const [],
}) {
  return _TaskBuilder(
    id: id,
    title: title,
    notes: notes,
    status: status,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt,
    completedAt: completedAt,
    deletedAt: deletedAt,
    position: position,
    priority: priority,
    dueDate: dueDate,
    reminder: reminder,
    listId: listId,
    categoryId: categoryId,
    tags: tags,
    seriesId: seriesId,
    subtasks: subtasks,
  ).build();
}

Subtask buildTestSubtask({
  required String id,
  required String taskId,
  required String title,
  bool isCompleted = false,
  int position = 0,
}) {
  return Subtask(
    id: id,
    taskId: taskId,
    title: title,
    isCompleted: isCompleted,
    position: position,
  );
}
