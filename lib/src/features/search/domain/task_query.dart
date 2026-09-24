// Busca textual e filtros como projeção dos dados existentes (spec 05).
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// Onde o termo correspondeu (spec 05, RF-16/RF-17).
enum MatchField { title, notes, subtask }

/// Categorias de prazo do filtro (spec 05, RF-13).
enum DueFilter { none, overdue, today, next7Days, customRange }

/// Filtro de lembrete (spec 05, RF-14).
enum ReminderFilter { withReminder, withoutReminder }

/// Filtro de recorrência (spec 05, RF-15).
enum RecurrenceFilter { active, none, canceled }

/// Normaliza texto para comparação sem alterar o armazenado: minúsculas e
/// sem acentos (spec 05, RF-05 / CA-04).
String normalizeForSearch(String input) {
  const accented = 'àáâãäåèéêëìíîïòóôõöùúûüçñýÿÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑÝŸ';
  const plain = 'aaaaaaeeeeiiiiooooouuuucnyyAAAAAAEEEEIIIIOOOOOUUUUCNYY';
  final lowered = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lowered.runes) {
    final char = String.fromCharCode(rune);
    final index = accented.indexOf(char);
    buffer.write(index >= 0 ? plain[index] : char);
  }
  return buffer.toString();
}

/// Critérios de busca e filtros combinados (spec 05, RF-08: AND entre
/// categorias, OR dentro de cada categoria).
class TaskFilters {
  const TaskFilters({
    this.query = '',
    this.statuses = const {},
    this.listIds = const {},
    this.groupIds = const {},
    this.categoryIds = const {},
    this.tagIds = const {},
    this.noTags = false,
    this.priorities = const {},
    this.due,
    this.customDueStart,
    this.customDueEnd,
    this.reminder,
    this.recurrence,
  });

  /// Texto digitado (bruto; normalizado na comparação).
  final String query;

  /// RF-09: vazio = ativas e concluídas (RF-02).
  final Set<TaskStatus> statuses;

  /// RF-10: `null` no conjunto = **Sem lista**; OR dentro do conjunto.
  final Set<String?> listIds;

  /// RF-10: OR dos grupos; tarefas sem lista nunca pertencem a grupo.
  final Set<String> groupIds;

  /// RF-11: `null` no conjunto = **Sem categoria**.
  final Set<String?> categoryIds;

  final Set<String> tagIds;
  final bool noTags;

  /// RF-12: vazio = sem filtro de prioridade.
  final Set<Priority> priorities;

  final DueFilter? due;
  final DateTime? customDueStart;
  final DateTime? customDueEnd;

  final ReminderFilter? reminder;
  final RecurrenceFilter? recurrence;

  bool get hasText => query.trim().isNotEmpty;

  bool get hasStructuredFilters =>
      statuses.isNotEmpty ||
      listIds.isNotEmpty ||
      groupIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      tagIds.isNotEmpty ||
      noTags ||
      priorities.isNotEmpty ||
      due != null ||
      reminder != null ||
      recurrence != null;

  /// Modo de busca global ativo (spec 05, RF-01/RF-07).
  bool get isActive => hasText || hasStructuredFilters;

  TaskFilters copyWith({
    String? query,
    Set<TaskStatus>? statuses,
    Set<String?>? listIds,
    Set<String>? groupIds,
    Set<String?>? categoryIds,
    Set<String>? tagIds,
    bool? noTags,
    Set<Priority>? priorities,
    DueFilter? due,
    bool clearDue = false,
    DateTime? customDueStart,
    DateTime? customDueEnd,
    ReminderFilter? reminder,
    RecurrenceFilter? recurrence,
  }) {
    return TaskFilters(
      query: query ?? this.query,
      statuses: statuses ?? this.statuses,
      listIds: listIds ?? this.listIds,
      groupIds: groupIds ?? this.groupIds,
      categoryIds: categoryIds ?? this.categoryIds,
      tagIds: tagIds ?? this.tagIds,
      noTags: noTags ?? this.noTags,
      priorities: priorities ?? this.priorities,
      due: clearDue ? null : (due ?? this.due),
      customDueStart: customDueStart ?? this.customDueStart,
      customDueEnd: customDueEnd ?? this.customDueEnd,
      reminder: reminder ?? this.reminder,
      recurrence: recurrence ?? this.recurrence,
    );
  }
}

/// Dados auxiliares dos filtros: calendário, listas/grupos e séries
/// (spec 05, RF-10/RF-13/RF-15).
class TaskSearchContext {
  const TaskSearchContext({
    required this.today,
    required this.lists,
    required this.seriesById,
  });

  final DateTime today;
  final List<TaskList> lists;
  final Map<String, RecurrenceSeries> seriesById;

  TaskList? listById(String? id) {
    if (id == null) return null;
    for (final list in lists) {
      if (list.id == id) return list;
    }
    return null;
  }
}

/// Localiza o termo normalizado nos campos pesquisáveis (spec 05, RF-04).
/// Retorna `null` quando não há termo ou não há correspondência.
MatchField? locateMatch(Task task, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return null;
  if (normalizeForSearch(task.title).contains(normalizedQuery)) {
    return MatchField.title;
  }
  final notes = task.notes;
  if (notes != null && normalizeForSearch(notes).contains(normalizedQuery)) {
    return MatchField.notes;
  }
  for (final subtask in task.subtasks) {
    if (normalizeForSearch(subtask.title).contains(normalizedQuery)) {
      return MatchField.subtask;
    }
  }
  return null;
}

/// Relevância textual (spec 05, RF-16): título < notas < subtarefas.
int _relevanceRank(MatchField? field) => switch (field) {
      MatchField.title => 0,
      MatchField.notes => 1,
      MatchField.subtask => 2,
      null => 3,
    };

bool _matchesStatus(Task task, TaskFilters filters) {
  if (filters.statuses.isEmpty) return true; // RF-02: ativas e concluídas
  return filters.statuses.contains(task.status);
}

bool _matchesList(Task task, TaskFilters filters) {
  if (filters.listIds.isEmpty) return true;
  return filters.listIds.contains(task.listId);
}

bool _matchesGroup(Task task, TaskFilters filters, TaskSearchContext ctx) {
  if (filters.groupIds.isEmpty) return true;
  if (task.listId == null) return false; // RF-10: sem lista fora do grupo
  final list = ctx.listById(task.listId);
  final groupId = list?.groupId;
  if (groupId == null) return false;
  return filters.groupIds.contains(groupId);
}

bool _matchesCategory(Task task, TaskFilters filters) {
  if (filters.categoryIds.isEmpty) return true;
  return filters.categoryIds.contains(task.categoryId);
}

bool _matchesTags(Task task, TaskFilters filters) {
  final hasTagFilter = filters.tagIds.isNotEmpty || filters.noTags;
  if (!hasTagFilter) return true;
  final taskTagIds = task.tags.map((t) => t.id).toSet();
  if (filters.noTags && taskTagIds.isEmpty) return true;
  if (filters.tagIds.isEmpty) return false;
  return taskTagIds.any(filters.tagIds.contains); // OR (RF-11)
}

bool _matchesPriority(Task task, TaskFilters filters) {
  if (filters.priorities.isEmpty) return true;
  return filters.priorities.contains(task.priority); // OR (RF-12)
}

bool _matchesDue(Task task, TaskFilters filters, TaskSearchContext ctx) {
  final dueFilter = filters.due;
  if (dueFilter == null) return true;
  final due = task.dueDate;
  return switch (dueFilter) {
    DueFilter.none => due == null,
    DueFilter.overdue =>
      // RF-13/CA-20: atraso é condição de tarefa ativa.
      task.isActive && due != null && _before(due, ctx.today),
    DueFilter.today =>
      due != null && _sameDay(due, ctx.today),
    DueFilter.next7Days =>
      due != null &&
          !(_before(due, ctx.today)) &&
          !_sameDay(due, ctx.today) &&
          !_after(due, _addDays(ctx.today, 7)),
    DueFilter.customRange =>
      due != null &&
          filters.customDueStart != null &&
          filters.customDueEnd != null &&
          !_before(due, filters.customDueStart!) &&
          !_after(due, filters.customDueEnd!),
  };
}

bool _matchesReminder(Task task, TaskFilters filters) {
  final reminderFilter = filters.reminder;
  if (reminderFilter == null) return true;
  return switch (reminderFilter) {
    ReminderFilter.withReminder => task.reminder != null,
    ReminderFilter.withoutReminder => task.reminder == null,
  };
}

bool _matchesRecurrence(Task task, TaskFilters filters, TaskSearchContext ctx) {
  final recurrenceFilter = filters.recurrence;
  if (recurrenceFilter == null) return true;
  final seriesId = task.seriesId;
  return switch (recurrenceFilter) {
    RecurrenceFilter.none => seriesId == null,
    RecurrenceFilter.active =>
      seriesId != null && (ctx.seriesById[seriesId]?.active ?? false),
    RecurrenceFilter.canceled =>
      seriesId != null && !(ctx.seriesById[seriesId]?.active ?? false),
  };
}

/// Avalia a tarefa contra todos os filtros estruturados com AND
/// (spec 05, RF-08).
bool taskMatchesFilters(
  Task task,
  TaskFilters filters,
  TaskSearchContext ctx,
) {
  return _matchesStatus(task, filters) &&
      _matchesList(task, filters) &&
      _matchesGroup(task, filters, ctx) &&
      _matchesCategory(task, filters) &&
      _matchesTags(task, filters) &&
      _matchesPriority(task, filters) &&
      _matchesDue(task, filters, ctx) &&
      _matchesReminder(task, filters) &&
      _matchesRecurrence(task, filters, ctx);
}

/// Executa busca global sobre tarefas fora da lixeira (spec 05, RF-01
/// a RF-04, RF-16 / CA-01 a CA-05, CA-17, CA-18).
///
/// O chamador deve fornecer apenas tarefas pesquisáveis (sem lixeira);
/// o resultado é sempre a tarefa principal, uma única vez.
List<Task> searchTasks({
  required Iterable<Task> tasks,
  required TaskFilters filters,
  required TaskSearchContext context,
}) {
  final normalizedQuery = normalizeForSearch(filters.query.trim());
  final results = <(Task, MatchField?)>[];

  for (final task in tasks) {
    if (task.isDeleted) continue; // RF-02/CA-08: lixeira nunca participa
    final match = locateMatch(task, normalizedQuery);
    if (filters.hasText && match == null) continue;
    if (!taskMatchesFilters(task, filters, context)) continue;
    results.add((task, match));
  }

  if (filters.hasText) {
    // RF-16: relevância textual; ordem de origem como desempate.
    results.sort((a, b) {
      final byRank = _relevanceRank(a.$2).compareTo(_relevanceRank(b.$2));
      if (byRank != 0) return byRank;
      final byOrigin = a.$1.position.compareTo(b.$1.position);
      if (byOrigin != 0) return byOrigin;
      return a.$1.createdAt.compareTo(b.$1.createdAt);
    });
  } else {
    // RF-16: só filtros → ordem de origem.
    results.sort((a, b) {
      final byOrigin = a.$1.position.compareTo(b.$1.position);
      if (byOrigin != 0) return byOrigin;
      return a.$1.createdAt.compareTo(b.$1.createdAt);
    });
  }

  return [for (final result in results) result.$1];
}

/// Local de correspondência por tarefa para apresentação (spec 05, RF-17).
MatchField? matchFieldFor(Task task, TaskFilters filters) {
  if (!filters.hasText) return null;
  return locateMatch(task, normalizeForSearch(filters.query.trim()));
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _before(DateTime date, DateTime reference) {
  final ref = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(date.year, date.month, date.day);
  return day.isBefore(ref);
}

bool _after(DateTime date, DateTime reference) {
  final ref = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(date.year, date.month, date.day);
  return day.isAfter(ref);
}

DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
