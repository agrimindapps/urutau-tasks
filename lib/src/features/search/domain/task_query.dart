/// Domínio de busca e filtros (spec 05).
///
/// A busca é projeção dos dados: não cria cópias nem resultados
/// persistentes e nunca altera as tarefas (RF-18/RF-19).
library;

import '../../tasks/domain/task.dart';

/// Sentinela para a opção "Sem lista" (spec 05, RF-10).
const String kNoList = '__no_list__';

/// Sentinela para a opção "Sem categoria" (spec 05, RF-11).
const String kNoCategory = '__no_category__';

/// Sentinela para a opção "Sem tags" (spec 05, RF-11).
const String kNoTags = '__no_tags__';

/// Filtro de prazo (spec 05, RF-13).
enum DueDateKind {
  /// Sem prazo.
  none,

  /// Atrasadas: **ativas** com prazo anterior a hoje (CA-20).
  overdue,

  /// Vencem hoje.
  today,

  /// Próximos 7 dias: de amanhã até +7, limites inclusivos.
  next7Days,

  /// Intervalo personalizado, limites inclusivos.
  range,
}

/// Filtro de lembrete (spec 05, RF-14).
enum ReminderFilter { any, withReminder, withoutReminder }

/// Filtro de recorrência (spec 05, RF-15).
enum RecurrenceFilter { any, active, cancelled, none }

/// Onde a busca textual encontrou a tarefa (spec 05, RF-17).
enum MatchField { title, notes, subtask }

/// Combinação de filtros: categorias diferentes são AND;
/// opções dentro da mesma categoria são OR (spec 05, RF-08).
class TaskFilter {
  const TaskFilter({
    this.statuses,
    this.listIds,
    this.groupIds,
    this.categoryIds,
    this.tagIds,
    this.priorities,
    this.dueDateKind,
    this.dueDateFrom,
    this.dueDateTo,
    this.reminderFilter,
    this.recurrenceFilter,
  });

  /// `active`/`completed`; nulo mostra os dois (RF-02). Lixeira nunca entra.
  final Set<TaskStatus>? statuses;

  /// Listas selecionadas; inclui [kNoList] para tarefas sem lista (RF-10).
  final Set<String>? listIds;

  /// Grupos selecionados: tarefas das listas do grupo; sem lista nunca
  /// entra (RF-10).
  final Set<String>? groupIds;

  /// Categorias; inclui [kNoCategory] (RF-11).
  final Set<String>? categoryIds;

  /// Tags; inclui [kNoTags] (RF-11).
  final Set<String>? tagIds;

  /// Prioridades (RF-12).
  final Set<TaskPriority>? priorities;

  final DueDateKind? dueDateKind;
  final String? dueDateFrom;
  final String? dueDateTo;

  final ReminderFilter? reminderFilter;
  final RecurrenceFilter? recurrenceFilter;

  bool get isEmpty =>
      statuses == null &&
      listIds == null &&
      groupIds == null &&
      categoryIds == null &&
      tagIds == null &&
      priorities == null &&
      dueDateKind == null &&
      (reminderFilter == null || reminderFilter == ReminderFilter.any) &&
      (recurrenceFilter == null || recurrenceFilter == RecurrenceFilter.any);
}

/// Contexto de consultas: relações fora do agregado de tarefa.
class QueryContext {
  const QueryContext({
    this.listGroupId = const {},
    this.seriesCancelled = const {},
  });

  /// Grupo de cada lista (id da lista → id do grupo ou nulo).
  final Map<String, String?> listGroupId;

  /// Séries canceladas (id da série → cancelada).
  final Map<String, bool> seriesCancelled;
}

/// Resultado de uma busca: tarefa e campo da correspondência (RF-17).
class TaskMatch {
  const TaskMatch(this.task, this.field);

  final Task task;
  final MatchField field;
}

/// Normaliza texto para comparação: minúsculas e sem acentos
/// (spec 05, RF-05), sem alterar o texto armazenado.
String normalizeSearchText(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    buffer.writeCharCode(_foldTable[rune] ?? rune);
  }
  return buffer.toString();
}

const Map<int, int> _foldTable = {
  // a
  0x00E0: 0x61, 0x00E1: 0x61, 0x00E2: 0x61, 0x00E3: 0x61, 0x00E4: 0x61,
  // e
  0x00E8: 0x65, 0x00E9: 0x65, 0x00EA: 0x65, 0x00EB: 0x65,
  // i
  0x00EC: 0x69, 0x00ED: 0x69, 0x00EE: 0x69, 0x00EF: 0x69,
  // o
  0x00F2: 0x6F, 0x00F3: 0x6F, 0x00F4: 0x6F, 0x00F5: 0x6F, 0x00F6: 0x6F,
  // u
  0x00F9: 0x75, 0x00FA: 0x75, 0x00FB: 0x75, 0x00FC: 0x75,
  // c, n, y
  0x00E7: 0x63, 0x00F1: 0x6E, 0x00FD: 0x79, 0x00FF: 0x79,
};

/// Busca textual + filtros combinados sobre a lista de tarefas.
///
/// Somente tarefas principais fora da lixeira (RF-01/RF-02); descrições de
/// subtarefas participam da busca, mas o resultado é a tarefa principal
/// (RF-03/RF-04). Correspondência parcial, sem maiúsculas e sem acentos
/// (RF-05).
List<TaskMatch> searchTasks(
  List<Task> tasks, {
  String text = '',
  TaskFilter filter = const TaskFilter(),
  QueryContext context = const QueryContext(),
  required String today,
}) {
  final query = normalizeSearchText(text.trim());
  final results = <TaskMatch>[];

  for (final task in tasks) {
    if (task.status == TaskStatus.trash) continue; // RF-01/RF-02
    if (!_passesFilters(task, filter, context, today)) continue;

    if (query.isEmpty) {
      results.add(TaskMatch(task, MatchField.title));
      continue;
    }

    final field = _matchField(task, query);
    if (field != null) {
      results.add(TaskMatch(task, field));
    }
  }

  results.sort((a, b) => _compare(a, b, query.isNotEmpty));
  return results;
}

bool _passesFilters(
  Task task,
  TaskFilter filter,
  QueryContext context,
  String today,
) {
  // Status (RF-09); lixeira já foi excluída.
  if (filter.statuses != null && !filter.statuses!.contains(task.status)) {
    return false;
  }

  // Lista e grupo (RF-10): cumulativos entre si (AND).
  if (filter.listIds != null) {
    final wanted = filter.listIds!;
    final matchesList = task.listId != null
        ? wanted.contains(task.listId)
        : wanted.contains(kNoList);
    if (!matchesList) return false;
  }
  if (filter.groupIds != null) {
    final groupId = task.listId == null
        ? null
        : context.listGroupId[task.listId];
    if (groupId == null || !filter.groupIds!.contains(groupId)) {
      return false;
    }
  }

  // Categoria (RF-11).
  if (filter.categoryIds != null) {
    final wanted = filter.categoryIds!;
    final matches = task.categoryId != null
        ? wanted.contains(task.categoryId)
        : wanted.contains(kNoCategory);
    if (!matches) return false;
  }

  // Tags (RF-11): opções da mesma categoria em OR.
  if (filter.tagIds != null) {
    final wanted = filter.tagIds!;
    final matchesTags = task.tagIds.any(wanted.contains) ||
        (wanted.contains(kNoTags) && task.tagIds.isEmpty);
    if (!matchesTags) return false;
  }

  // Prioridade (RF-12).
  if (filter.priorities != null &&
      !filter.priorities!.contains(task.priority)) {
    return false;
  }

  // Prazo (RF-13).
  if (filter.dueDateKind != null &&
      !_matchesDueDate(task, filter, today)) {
    return false;
  }

  // Lembrete (RF-14).
  if (filter.reminderFilter == ReminderFilter.withReminder &&
      task.reminder == null) {
    return false;
  }
  if (filter.reminderFilter == ReminderFilter.withoutReminder &&
      task.reminder != null) {
    return false;
  }

  // Recorrência (RF-15).
  if (filter.recurrenceFilter != null &&
      filter.recurrenceFilter != RecurrenceFilter.any) {
    final seriesId = task.seriesId;
    switch (filter.recurrenceFilter!) {
      case RecurrenceFilter.none:
        if (seriesId != null) return false;
      case RecurrenceFilter.active:
        if (seriesId == null || context.seriesCancelled[seriesId] == true) {
          return false;
        }
      case RecurrenceFilter.cancelled:
        if (seriesId == null || context.seriesCancelled[seriesId] != true) {
          return false;
        }
      case RecurrenceFilter.any:
        break;
    }
  }

  return true;
}

bool _matchesDueDate(Task task, TaskFilter filter, String today) {
  final kind = filter.dueDateKind;
  if (kind == null) return true;
  final due = task.dueDate;
  switch (kind) {
    case DueDateKind.none:
      return due == null;
    case DueDateKind.overdue:
      // Atraso é condição de ativa (RF-13/CA-20).
      return task.status == TaskStatus.active &&
          due != null &&
          due.compareTo(today) < 0;
    case DueDateKind.today:
      return due == today;
    case DueDateKind.next7Days:
      if (due == null) return false;
      final tomorrow = _addDays(today, 1);
      final limit = _addDays(today, 7);
      return due.compareTo(tomorrow) >= 0 && due.compareTo(limit) <= 0;
    case DueDateKind.range:
      if (due == null) return false;
      final from = filter.dueDateFrom;
      final to = filter.dueDateTo;
      if (from != null && due.compareTo(from) < 0) return false;
      if (to != null && due.compareTo(to) > 0) return false;
      return true;
  }
}

MatchField? _matchField(Task task, String query) {
  if (normalizeSearchText(task.title).contains(query)) return MatchField.title;
  if (normalizeSearchText(task.notes).contains(query)) return MatchField.notes;
  for (final subtask in task.subtasks) {
    if (normalizeSearchText(subtask.description).contains(query)) {
      return MatchField.subtask;
    }
  }
  return null;
}

/// Relevância (RF-16): com texto, título > notas > subtarefas, com ordem de
/// origem como desempate; sem texto, ordem de origem.
int _compare(TaskMatch a, TaskMatch b, bool byRelevance) {
  if (byRelevance) {
    const rank = {
      MatchField.title: 0,
      MatchField.notes: 1,
      MatchField.subtask: 2,
    };
    final byField = rank[a.field]!.compareTo(rank[b.field]!);
    if (byField != 0) return byField;
  }
  return a.task.position.compareTo(b.task.position);
}

String _addDays(String isoDate, int days) {
  final date = DateTime.parse(isoDate).add(Duration(days: days));
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
