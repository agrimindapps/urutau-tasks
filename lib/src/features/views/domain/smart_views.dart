// Visões inteligentes derivadas (spec 03).
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// Conjunto de visões do MVP (spec 03, RF-01 a RF-04).
enum SmartView {
  all,
  important,
  planned,
  completed,
}

/// Data local no formato `yyyy-MM-dd` (específica de calendário, sem UTC —
/// spec 06, RF-13).
String localDateString(DateTime moment) {
  final local = moment.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// Critérios das visões (spec 03, regras comuns + RF-01 a RF-05).
///
/// Somente tarefas principais fora da lixeira; nunca duplica dados
/// (CA-06): o mesmo objeto de tarefa é referenciado por cada visão.
bool taskMatchesView(Task task, SmartView view) {
  return switch (view) {
    SmartView.all => task.isActive,
    SmartView.important => task.isImportant,
    SmartView.planned => task.isPlanned,
    SmartView.completed => !task.isDeleted && task.isCompleted,
  };
}

/// Ordenação padrão das visões (spec 03, RF-11):
/// atrasadas → vencendo hoje → próximos → sem prazo; depois prioridade
/// decrescente; ordem de origem como desempate.
int compareForSmartView(Task a, Task b, DateTime today) {
  final todayString = localDateString(today);

  int dueRank(Task task) {
    final due = task.dueDate;
    if (due == null) return 3;
    final dueString = localDateString(due);
    if (dueString.compareTo(todayString) < 0) return 0; // atrasada
    if (dueString == todayString) return 1; // vence hoje
    return 2; // futuro
  }

  final byDue = dueRank(a).compareTo(dueRank(b));
  if (byDue != 0) return byDue;

  // Sem prazo depois das com prazo já está no dueRank (null = 3).
  final byPriority = b.priority.rank.compareTo(a.priority.rank);
  if (byPriority != 0) return byPriority;

  final byOrigin = a.position.compareTo(b.position);
  if (byOrigin != 0) return byOrigin;
  return a.createdAt.compareTo(b.createdAt);
}

/// Concluídas mais recentes primeiro (spec 03, RF-11).
int compareCompleted(Task a, Task b) {
  final aTime = a.completedAt ?? a.updatedAt ?? a.createdAt;
  final bTime = b.completedAt ?? b.updatedAt ?? b.createdAt;
  final byCompleted = bTime.compareTo(aTime);
  if (byCompleted != 0) return byCompleted;
  return a.position.compareTo(b.position);
}

/// Aplica critério + ordenação da visão (Concluídas usa a ordem própria).
List<Task> tasksForView(
  SmartView view,
  Iterable<Task> tasks, {
  required DateTime today,
}) {
  final filtered = tasks.where((task) => taskMatchesView(task, view)).toList();
  if (view == SmartView.completed) {
    filtered.sort(compareCompleted);
  } else {
    filtered.sort((a, b) => compareForSmartView(a, b, today));
  }
  return filtered;
}
