import '../../tasks/domain/task.dart';

/// Visões inteligentes: projeções dos dados, sem duplicação (spec 03).
enum SmartView {
  /// Foco do dia (ordem manual — RF-12).
  myDay,

  /// Ativas com prioridade alta ou urgente (RF-02).
  important,

  /// Ativas com prazo ou lembrete (RF-03).
  planned,

  /// Todas as tarefas principais ativas (RF-01).
  all,

  /// Tarefas principais concluídas (RF-04).
  completed,
}

/// Seleciona e ordena as tarefas de uma visão (spec 03, RF-01 a RF-04/RF-11).
///
/// Somente tarefas principais: subtarefas nunca aparecem independentes;
/// lixeira nunca participa (regras comuns da spec 03).
List<Task> selectSmartView(
  SmartView view,
  List<Task> tasks, {
  required String today,
  Set<String> myDayTaskIds = const {},
  List<String> myDayOrder = const [],
}) {
  final visible = tasks.where((t) => t.status != TaskStatus.trash);

  switch (view) {
    case SmartView.myDay:
      final byId = {for (final t in visible) t.id: t};
      final ordered = <Task>[];
      for (final id in myDayOrder) {
        final task = byId[id];
        if (task != null &&
            task.status == TaskStatus.active &&
            myDayTaskIds.contains(id)) {
          ordered.add(task);
        }
      }
      return ordered;

    case SmartView.important:
      return _sortPlanned(
        visible
            .where((t) =>
                t.status == TaskStatus.active &&
                (t.priority == TaskPriority.high ||
                    t.priority == TaskPriority.urgent))
            .toList(),
        today,
      );

    case SmartView.planned:
      // Prazo ou lembrete; a tarefa com os dois aparece uma única vez
      // (RF-03) — a seleção é por tarefa, não por atributo.
      return _sortPlanned(
        visible
            .where((t) =>
                t.status == TaskStatus.active &&
                (t.dueDate != null || t.reminder != null))
            .toList(),
        today,
      );

    case SmartView.all:
      return _sortPlanned(
        visible.where((t) => t.status == TaskStatus.active).toList(),
        today,
      );

    case SmartView.completed:
      // Mais recentes primeiro (RF-04 permite destacar).
      final completed =
          visible.where((t) => t.status == TaskStatus.completed).toList()
            ..sort((a, b) {
              final aAt = a.completedAt ?? a.updatedAt;
              final bAt = b.completedAt ?? b.updatedAt;
              return bAt.compareTo(aAt);
            });
      return completed;
  }
}

/// Ordenação das visões (RF-11): 1) atrasadas, 2) vencem hoje,
/// 3) próximos prazos, 4) prioridade (maior→menor), 5) ordem de origem.
/// Sem prazo vai depois das com prazo.
List<Task> _sortPlanned(List<Task> tasks, String today) {
  int bucket(Task task) {
    final due = task.dueDate;
    if (due == null) return 3;
    if (due.compareTo(today) < 0) return 0;
    if (due.compareTo(today) == 0) return 1;
    return 2;
  }

  int priorityRank(Task task) => switch (task.priority) {
        TaskPriority.urgent => 4,
        TaskPriority.high => 3,
        TaskPriority.medium => 2,
        TaskPriority.low => 1,
        null => 0,
      };

  final sorted = [...tasks]..sort((a, b) {
      final byBucket = bucket(a).compareTo(bucket(b));
      if (byBucket != 0) return byBucket;
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      var byDue = 0;
      if (aDue != null && bDue != null) {
        byDue = aDue.compareTo(bDue);
      } else if (aDue != null) {
        byDue = -1;
      } else if (bDue != null) {
        byDue = 1;
      }
      if (byDue != 0) return byDue;
      final byPriority = priorityRank(b).compareTo(priorityRank(a));
      if (byPriority != 0) return byPriority;
      return a.position.compareTo(b.position);
    });
  return sorted;
}
