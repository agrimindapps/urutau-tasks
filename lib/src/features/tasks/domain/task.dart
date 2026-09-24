import 'package:urutau_tasks/src/features/organization/domain/organization.dart';

/// Ciclo de vida principal de uma tarefa (spec 01, RF-02).
///
/// A lixeira não é um status separado: é representada por [Task.deletedAt]
/// preenchido, preservando o estado anterior para restauração (RF-02/RF-10).
enum TaskStatus {
  active,
  completed,
}

/// Níveis de prioridade do MVP (escopo 3.3). Usados pela visão Importante
/// e pela ordenação das visões (spec 03, RF-02/RF-11).
enum Priority {
  low,
  medium,
  high,
  urgent;

  /// Ordem para ordenação decrescente (RF-11, etapa 4).
  int get rank => index;

  static Priority parse(String raw) => switch (raw) {
        'high' => Priority.high,
        'urgent' => Priority.urgent,
        'low' => Priority.low,
        _ => Priority.medium,
      };

  String get storedName => switch (this) {
        Priority.low => 'low',
        Priority.medium => 'medium',
        Priority.high => 'high',
        Priority.urgent => 'urgent',
      };
}

/// Exceção de domínio para títulos vazios (spec 01, RF-01 / CA-02).
class InvalidTitleException implements Exception {
  const InvalidTitleException();

  @override
  String toString() => 'Title must not be empty.';
}

String normalizeTitle(String raw) {
  final title = raw.trim();
  if (title.isEmpty) throw const InvalidTitleException();
  return title;
}

/// Subtarefa: etapa interna de uma tarefa principal (spec 01, RF-05).
class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.position = 0,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int position;

  Subtask copyWith({
    String? title,
    bool? isCompleted,
    int? position,
  }) {
    return Subtask(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Subtask &&
      other.id == id &&
      other.taskId == taskId &&
      other.title == title &&
      other.isCompleted == isCompleted &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, taskId, title, isCompleted, position);
}

/// Tarefa principal (spec 01 e spec 06, RF-05).
class Task {
  Task({
    required this.id,
    required String title,
    this.notes,
    this.status = TaskStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.deletedAt,
    this.position = 0,
    this.priority = Priority.medium,
    this.dueDate,
    this.reminder,
    this.listId,
    this.categoryId,
    this.seriesId,
    List<Subtask>? subtasks,
    List<Tag>? tags,
  })  : title = normalizeTitle(title),
        subtasks = List.unmodifiable(subtasks ?? const <Subtask>[]),
        tags = List.unmodifiable(tags ?? const <Tag>[]);

  final String id;
  final String title;
  final String? notes;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  /// Preenchido quando a tarefa está na lixeira (exclusão lógica).
  final DateTime? deletedAt;

  final int position;

  /// Prioridade sempre presente (escopo MVP 3.3).
  final Priority priority;

  /// Prazo como data de calendário local, sem horário (spec 06, RF-11).
  final DateTime? dueDate;

  /// Lembrete como instante UTC (spec 06, RF-12).
  final DateTime? reminder;

  /// Lista da tarefa; nulo = inbox implícita (spec 02, RF-03).
  final String? listId;

  /// Categoria principal; no máximo uma (spec 02, RF-08).
  final String? categoryId;

  /// Série recorrente da qual esta tarefa é ocorrência (spec 04, RF-07).
  final String? seriesId;

  final List<Subtask> subtasks;
  final List<Tag> tags;

  bool get isDeleted => deletedAt != null;
  bool get isActive => !isDeleted && status == TaskStatus.active;
  bool get isCompleted => status == TaskStatus.completed;

  /// Visão Importante (spec 03, RF-02).
  bool get isImportant =>
      isActive && (priority == Priority.high || priority == Priority.urgent);

  /// Visão Planejado (spec 03, RF-03): prazo OU lembrete, uma única vez.
  bool get isPlanned => isActive && (dueDate != null || reminder != null);

  /// Progresso no formato `concluídas/total` (spec 01, RF-08 / CA-06).
  /// Retorna `null` quando não há subtarefas, para não exibir progresso
  /// artificial.
  ({int completed, int total})? get progress {
    if (subtasks.isEmpty) return null;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return (completed: completed, total: subtasks.length);
  }

  Task copyWith({
    String? title,
    String? notes,
    bool clearNotes = false,
    TaskStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? position,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? reminder,
    bool clearReminder = false,
    String? listId,
    bool clearListId = false,
    String? categoryId,
    bool clearCategoryId = false,
    String? seriesId,
    bool clearSeriesId = false,
    List<Subtask>? subtasks,
    List<Tag>? tags,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      position: position ?? this.position,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminder: clearReminder ? null : (reminder ?? this.reminder),
      listId: clearListId ? null : (listId ?? this.listId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      seriesId: clearSeriesId ? null : (seriesId ?? this.seriesId),
      subtasks: subtasks ?? this.subtasks,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.notes == notes &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.completedAt == completedAt &&
      other.deletedAt == deletedAt &&
      other.position == position &&
      other.priority == priority &&
      other.dueDate == dueDate &&
      other.reminder == reminder &&
      other.listId == listId &&
      other.categoryId == categoryId &&
      other.seriesId == seriesId &&
      _listEquals(other.subtasks, subtasks) &&
      _listEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        notes,
        status,
        createdAt,
        updatedAt,
        completedAt,
        deletedAt,
        position,
        priority,
        dueDate,
        reminder,
        listId,
        categoryId,
        seriesId,
        Object.hashAll(subtasks),
        Object.hashAll(tags),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Conclui ou reabre a tarefa principal sem alterar subtarefas
/// (spec 01, RF-04 / CA-07 / CA-08).
Task toggleTaskCompletion(Task task, DateTime now) {
  if (task.isDeleted) {
    throw StateError('Tasks in the trash cannot change completion.');
  }
  if (task.status == TaskStatus.active) {
    return task.copyWith(
      status: TaskStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
  }
  return task.copyWith(
    status: TaskStatus.active,
    clearCompletedAt: true,
    updatedAt: now,
  );
}

/// Move a tarefa para a lixeira preservando hierarquia e estados
/// (spec 01, RF-09 / CA-09).
Task trashTask(Task task, DateTime now) {
  if (task.isDeleted) return task;
  return task.copyWith(deletedAt: now, updatedAt: now);
}

/// Restaura a tarefa com o estado anterior à exclusão
/// (spec 01, RF-10 / CA-10).
Task restoreTask(Task task, DateTime now) {
  if (!task.isDeleted) return task;
  return task.copyWith(clearDeletedAt: true, updatedAt: now);
}

/// Reordena as subtarefas e renumera posições de forma determinística
/// (spec 01, RF-06 / CA-04; spec 06, RF-18).
List<Subtask> reorderSubtasks(
  List<Subtask> subtasks,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex < 0 || oldIndex >= subtasks.length) {
    throw RangeError.index(oldIndex, subtasks, 'oldIndex');
  }
  final items = List<Subtask>.from(subtasks);
  final item = items.removeAt(oldIndex);
  var insertAt = newIndex;
  if (insertAt < 0) insertAt = 0;
  if (insertAt > items.length) insertAt = items.length;
  items.insert(insertAt, item);
  return [
    for (var i = 0; i < items.length; i++)
      items[i].copyWith(position: i),
  ];
}

/// Progresso agrupado para exibição (spec 01, RF-08).
String formatProgress(({int completed, int total}) progress) =>
    '${progress.completed}/${progress.total}';
