/// Domínio de tarefas e subtarefas (spec 01).
///
/// Regras puras, sem dependência de widgets, banco ou plataforma
/// (docs/03, princípio 2).
library;

/// Estados da tarefa (spec 01, RF-02).
enum TaskStatus {
  /// Criada e não concluída.
  active,

  /// Concluída pelo usuário.
  completed,

  /// Excluída logicamente; restaurável (spec 01, RF-02).
  trash,
}

/// Falhas de validação/estado do domínio de tarefas.
enum TaskFailure {
  /// Título/descrição vazio após trim (spec 01, RF-01/RF-05).
  emptyTitle,

  /// Tentativa de editar tarefa na lixeira antes de restaurar (spec 01, RF-01).
  editInTrash,

  /// Transição de estado fora da tabela da spec 01, RF-02.
  invalidTransition,

  /// Subtarefa pertence a outra tarefa ou não existe no agregado.
  unknownSubtask,

  /// Tarefa não encontrada.
  unknownTask,

  /// Conversão de subtarefa em tarefa principal não é permitida (spec 01, RF-05).
  nestedSubtask,

  /// Tag duplicada equivalente na tarefa (spec 02, RF-09).
  duplicateTag,
}

/// Exceção de domínio com a falha associada.
class TaskException implements Exception {
  const TaskException(this.failure);

  final TaskFailure failure;

  @override
  String toString() => 'TaskException(${failure.name})';
}

String _validateTitle(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const TaskException(TaskFailure.emptyTitle);
  }
  return trimmed;
}

void _ensureEditable(TaskStatus status) {
  if (status == TaskStatus.trash) {
    throw const TaskException(TaskFailure.editInTrash);
  }
}

/// Subtarefa: etapa exclusiva de uma tarefa principal (spec 01, RF-05).
///
/// Possui apenas título (descrição), estado de conclusão e posição.
/// Não aninha subtarefas nem carrega lista, prioridade, prazo, lembrete,
/// recorrência ou categoria.
class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.description,
    required this.isCompleted,
    required this.position,
  });

  /// Identificador estável (UUID gerado no domínio).
  final String id;

  /// Tarefa principal obrigatória (spec 01, RF-05).
  final String taskId;

  /// Título da etapa (não vazio após trim).
  final String description;

  /// Estado de conclusão da etapa.
  final bool isCompleted;

  /// Posição inteira definida pelo usuário (spec 01, RF-06).
  final int position;

  Subtask copyWith({
    String? description,
    bool? isCompleted,
    int? position,
  }) {
    return Subtask(
      id: id,
      taskId: taskId,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
    );
  }

  /// Renomeia a etapa preservando identidade e estado (spec 01, RF-05).
  Subtask rename(String description) {
    return copyWith(description: _validateTitle(description));
  }

  /// Conclui a etapa.
  Subtask complete() => copyWith(isCompleted: true);

  /// Reabre a etapa.
  Subtask reopen() => copyWith(isCompleted: false);

  @override
  bool operator ==(Object other) {
    return other is Subtask &&
        other.id == id &&
        other.taskId == taskId &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(id, taskId, description, isCompleted, position);
}

/// Tarefa principal com suas subtarefas (agregado da spec 01).
class Task {
  Task({
    required this.id,
    required this.title,
    required this.notes,
    required this.status,
    required this.statusBeforeTrash,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.position,
    required List<Subtask> subtasks,
    this.listId,
    this.categoryId,
    List<String> tagIds = const [],
  })  : subtasks = List.unmodifiable(_sorted(subtasks)),
        tagIds = List.unmodifiable(tagIds.toSet().toList(growable: false)) {
    if (subtasks.any((s) => s.taskId != id)) {
      throw const TaskException(TaskFailure.nestedSubtask);
    }
  }

  /// Cria uma tarefa ativa com título validado (spec 01, RF-01/RF-02).
  factory Task.create({
    required String id,
    required String title,
    String notes = '',
    required DateTime createdAt,
    int position = 0,
    String? listId,
    String? categoryId,
    List<String> tagIds = const [],
  }) {
    return Task(
      id: id,
      title: _validateTitle(title),
      notes: notes.trim(),
      status: TaskStatus.active,
      statusBeforeTrash: null,
      createdAt: createdAt,
      updatedAt: createdAt,
      completedAt: null,
      position: position,
      subtasks: const [],
      listId: listId,
      categoryId: categoryId,
      tagIds: tagIds,
    );
  }

  final String id;
  final String title;
  final String notes;
  final TaskStatus status;

  /// Estado anterior à exclusão, usado na restauração (spec 01, RF-02/RF-10).
  final TaskStatus? statusBeforeTrash;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Instante da última conclusão; nulo quando ativa.
  final DateTime? completedAt;

  /// Posição de ordenação na origem (spec 06, RF-18).
  final int position;

  /// Lista personalizada opcional; nula = inbox implícita (spec 02, RF-03).
  final String? listId;

  /// Categoria opcional, no máximo uma por tarefa (spec 02, RF-08).
  final String? categoryId;

  /// Tags associadas, sem duplicatas (spec 02, RF-09).
  final List<String> tagIds;

  /// Subtarefas ordenadas por posição (spec 01, RF-06).
  final List<Subtask> subtasks;

  static List<Subtask> _sorted(List<Subtask> subtasks) {
    final copy = [...subtasks]..sort((a, b) => a.position.compareTo(b.position));
    return copy;
  }

  int get subtaskCount => subtasks.length;

  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;

  /// Progresso `concluídas/total`; nulo sem subtarefas
  /// (spec 01, RF-08: sem progresso artificial).
  double? get progress {
    if (subtasks.isEmpty) return null;
    return completedSubtaskCount / subtasks.length;
  }

  bool get isTrashed => status == TaskStatus.trash;

  Task _copyWith({
    String? title,
    String? notes,
    TaskStatus? status,
    TaskStatus? statusBeforeTrash,
    bool clearStatusBeforeTrash = false,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? position,
    List<Subtask>? subtasks,
    String? listId,
    bool clearList = false,
    String? categoryId,
    bool clearCategory = false,
    List<String>? tagIds,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      statusBeforeTrash: clearStatusBeforeTrash
          ? null
          : (statusBeforeTrash ?? this.statusBeforeTrash),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      position: position ?? this.position,
      subtasks: subtasks ?? this.subtasks,
      listId: clearList ? null : (listId ?? this.listId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      tagIds: tagIds ?? this.tagIds,
    );
  }

  /// Edita título/notas preservando identidade e hierarquia (spec 01, RF-01/RF-03).
  Task rename({required String title, String? notes, required DateTime at}) {
    _ensureEditable(status);
    return _copyWith(
      title: _validateTitle(title),
      notes: notes == null ? this.notes : notes.trim(),
      updatedAt: at,
    );
  }

  /// Conclui a tarefa sem alterar subtarefas (spec 01, RF-02/RF-04).
  Task complete({required DateTime at}) {
    _ensureEditable(status);
    if (status == TaskStatus.completed) {
      throw const TaskException(TaskFailure.invalidTransition);
    }
    return _copyWith(
      status: TaskStatus.completed,
      completedAt: at,
      updatedAt: at,
    );
  }

  /// Reabre preservando estados das subtarefas (spec 01, RF-02/RF-04/CA-08).
  Task reopen({required DateTime at}) {
    _ensureEditable(status);
    if (status != TaskStatus.completed) {
      throw const TaskException(TaskFailure.invalidTransition);
    }
    return _copyWith(
      status: TaskStatus.active,
      clearCompletedAt: true,
      updatedAt: at,
    );
  }

  /// Move a hierarquia para a lixeira preservando dados (spec 01, RF-02/RF-09).
  Task moveToTrash({required DateTime at}) {
    if (status == TaskStatus.trash) {
      throw const TaskException(TaskFailure.invalidTransition);
    }
    return _copyWith(
      status: TaskStatus.trash,
      statusBeforeTrash: status,
      updatedAt: at,
    );
  }

  /// Restaura a hierarquia ao estado anterior (spec 01, RF-02/RF-10).
  Task restore({required DateTime at}) {
    if (status != TaskStatus.trash) {
      throw const TaskException(TaskFailure.invalidTransition);
    }
    final target = statusBeforeTrash ?? TaskStatus.active;
    return _copyWith(
      status: target,
      clearStatusBeforeTrash: true,
      completedAt: target == TaskStatus.completed ? completedAt : null,
      clearCompletedAt: target != TaskStatus.completed,
      updatedAt: at,
    );
  }

  /// Adiciona etapa ao final da ordem (spec 01, RF-05/RF-06).
  Task addSubtask({required String id, required String description, DateTime? at}) {
    _ensureEditable(status);
    final next = Subtask(
      id: id,
      taskId: this.id,
      description: _validateTitle(description),
      isCompleted: false,
      position: subtasks.isEmpty ? 0 : subtasks.last.position + 1,
    );
    return _copyWith(
      subtasks: [...subtasks, next],
      updatedAt: at,
    );
  }

  /// Atualiza uma etapa existente (renomear, concluir, reabrir, reposicionar).
  Task updateSubtask(Subtask updated, {DateTime? at}) {
    _ensureEditable(status);
    if (updated.taskId != id) {
      throw const TaskException(TaskFailure.nestedSubtask);
    }
    final index = subtasks.indexWhere((s) => s.id == updated.id);
    if (index == -1) {
      throw const TaskException(TaskFailure.unknownSubtask);
    }
    final copy = [...subtasks];
    copy[index] = updated;
    return _copyWith(subtasks: copy, updatedAt: at);
  }

  /// Remoção individual: sai do progresso e é definitiva (spec 01, RF-07).
  Task removeSubtask(String subtaskId, {DateTime? at}) {
    _ensureEditable(status);
    final index = subtasks.indexWhere((s) => s.id == subtaskId);
    if (index == -1) {
      throw const TaskException(TaskFailure.unknownSubtask);
    }
    final copy = [...subtasks]..removeAt(index);
    return _copyWith(subtasks: copy, updatedAt: at);
  }

  /// Reordena as etapas preservando estados e títulos (spec 01, RF-06).
  Task reorderSubtasks(List<String> orderedIds, {DateTime? at}) {
    _ensureEditable(status);
    if (orderedIds.length != subtasks.length ||
        orderedIds.toSet().length != orderedIds.length ||
        !orderedIds.toSet().containsAll(subtasks.map((s) => s.id))) {
      throw const TaskException(TaskFailure.unknownSubtask);
    }
    final byId = {for (final s in subtasks) s.id: s};
    final reordered = <Subtask>[];
    for (var i = 0; i < orderedIds.length; i++) {
      reordered.add(byId[orderedIds[i]]!.copyWith(position: i));
    }
    return _copyWith(subtasks: reordered, updatedAt: at);
  }

  /// Atribui/remove lista preservando a hierarquia (spec 02, RF-03/RF-07).
  ///
  /// [listId] nulo devolve a tarefa à inbox implícita.
  Task assignList(String? listId, {DateTime? at}) {
    _ensureEditable(status);
    return listId == null
        ? _copyWith(clearList: true, updatedAt: at)
        : _copyWith(listId: listId, updatedAt: at);
  }

  /// Define a categoria única (spec 02, RF-08); nulo remove.
  Task assignCategory(String? categoryId, {DateTime? at}) {
    _ensureEditable(status);
    return categoryId == null
        ? _copyWith(clearCategory: true, updatedAt: at)
        : _copyWith(categoryId: categoryId, updatedAt: at);
  }

  /// Associa uma tag (spec 02, RF-09); duplicatas são rejeitadas.
  Task addTagId(String tagId, {DateTime? at}) {
    _ensureEditable(status);
    if (tagIds.contains(tagId)) {
      throw const TaskException(TaskFailure.duplicateTag);
    }
    return _copyWith(tagIds: [...tagIds, tagId], updatedAt: at);
  }

  /// Remove a associação de uma tag (a tag em si permanece global).
  Task removeTagId(String tagId, {DateTime? at}) {
    _ensureEditable(status);
    return _copyWith(
      tagIds: tagIds.where((id) => id != tagId).toList(growable: false),
      updatedAt: at,
    );
  }

  /// Substitui o conjunto de tags preservando a ordem informada.
  Task setTagIds(List<String> newTagIds, {DateTime? at}) {
    _ensureEditable(status);
    final unique = newTagIds.toSet();
    if (unique.length != newTagIds.length) {
      throw const TaskException(TaskFailure.duplicateTag);
    }
    return _copyWith(
      tagIds: List.unmodifiable(newTagIds),
      updatedAt: at,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.notes == notes &&
        other.status == status &&
        other.statusBeforeTrash == statusBeforeTrash &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.completedAt == completedAt &&
        other.position == position &&
        other.listId == listId &&
        other.categoryId == categoryId &&
        _listEquals(other.tagIds, tagIds) &&
        _listEquals(other.subtasks, subtasks);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        notes,
        status,
        statusBeforeTrash,
        createdAt,
        updatedAt,
        completedAt,
        position,
        listId,
        categoryId,
        Object.hashAll(tagIds),
        Object.hashAll(subtasks),
      );
}

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
