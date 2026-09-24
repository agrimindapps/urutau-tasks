import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:urutau_tasks/src/features/views/domain/smart_views.dart';

import '../../../support/task_fixtures.dart';

void main() {
  final today = DateTime(2026, 9, 24);
  final tomorrow = DateTime(2026, 9, 25);
  final yesterday = DateTime(2026, 9, 23);

  Task build({
    String id = 't',
    TaskStatus status = TaskStatus.active,
    DateTime? deletedAt,
    Priority priority = Priority.medium,
    DateTime? dueDate,
    DateTime? reminder,
    int position = 0,
    DateTime? completedAt,
  }) {
    return buildTestTask(
      id: id,
      title: 'Tarefa $id',
      status: status,
      deletedAt: deletedAt,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      position: position,
      completedAt: completedAt,
    );
  }

  group('RF-01 / CA-01 — Todas', () {
    test('CA-01 exibe todas as ativas, inclusive sem lista', () {
      final tasks = [
        build(id: 'a'),
        build(id: 'b'),
        build(id: 'c', status: TaskStatus.completed),
        build(id: 'd', deletedAt: DateTime(2026, 9, 24)),
      ];
      final result = tasksForView(SmartView.all, tasks, today: today);

      expect(result.map((t) => t.id), ['a', 'b']);
    });
  });

  group('RF-02 / CA-03 — Importante', () {
    test('CA-03 apenas alta e urgente ativas', () {
      final tasks = [
        build(id: 'low', priority: Priority.low),
        build(id: 'medium', priority: Priority.medium),
        build(id: 'high', priority: Priority.high),
        build(id: 'urgent', priority: Priority.urgent),
        build(id: 'highDone', priority: Priority.high,
            status: TaskStatus.completed),
        build(id: 'urgentTrash', priority: Priority.urgent,
            deletedAt: DateTime(2026, 9, 24)),
      ];
      final result = tasksForView(SmartView.important, tasks, today: today);

      // Ordem segue RF-11: urgente antes de alta (prioridade decrescente).
      expect(result.map((t) => t.id), ['urgent', 'high']);
    });
  });

  group('RF-03 / CA-04, CA-05, CA-07 — Planejado', () {
    test('CA-04 prazo ou lembrete aparecem uma única vez', () {
      final tasks = [
        build(id: 'due', dueDate: tomorrow),
        build(id: 'reminder', reminder: DateTime.utc(2026, 9, 25, 12)),
        build(id: 'both',
            dueDate: tomorrow, reminder: DateTime.utc(2026, 9, 25, 12)),
        build(id: 'none'),
      ];
      final result = tasksForView(SmartView.planned, tasks, today: today);

      // CA-04: cada tarefa uma única vez (ordem segue RF-11).
      expect(result.map((t) => t.id),
          unorderedEquals(['due', 'reminder', 'both']));
    });

    test('CA-05 tarefa atrasada permanece em Planejado', () {
      final tasks = [build(id: 'late', dueDate: yesterday)];
      final result = tasksForView(SmartView.planned, tasks, today: today);

      expect(result.single.id, 'late');
    });

    test('CA-07 concluídas ficam fora das visões de trabalho', () {
      final tasks = [
        build(id: 'x', priority: Priority.urgent, dueDate: yesterday,
            status: TaskStatus.completed),
      ];
      expect(tasksForView(SmartView.important, tasks, today: today), isEmpty);
      expect(tasksForView(SmartView.planned, tasks, today: today), isEmpty);
      expect(tasksForView(SmartView.all, tasks, today: today), isEmpty);
      expect(
        tasksForView(SmartView.completed, tasks, today: today).map((t) => t.id),
        ['x'],
      );
    });
  });

  group('RF-04 — Concluídas', () {
    test('exibe concluídas fora da lixeira, mais recentes primeiro', () {
      final tasks = [
        build(id: 'old', status: TaskStatus.completed,
            completedAt: DateTime(2026, 9, 20)),
        build(id: 'new', status: TaskStatus.completed,
            completedAt: DateTime(2026, 9, 24)),
        build(id: 'trashed', status: TaskStatus.completed,
            deletedAt: DateTime(2026, 9, 24)),
      ];
      final result = tasksForView(SmartView.completed, tasks, today: today);

      expect(result.map((t) => t.id), ['new', 'old']);
    });
  });

  group('RF-11 — ordenação', () {
    test('atrasadas → hoje → futuro → sem prazo; prioridade desempata', () {
      final tasks = [
        build(id: 'noDueHigh', priority: Priority.high),
        build(id: 'futureLow', dueDate: tomorrow, priority: Priority.low),
        build(id: 'todayLow', dueDate: today, priority: Priority.low),
        build(id: 'lateMedium', dueDate: yesterday,
            priority: Priority.medium),
        build(id: 'lateUrgent', dueDate: yesterday,
            priority: Priority.urgent),
        build(id: 'todayUrgent', dueDate: today, priority: Priority.urgent),
      ];
      final result = tasksForView(SmartView.all, tasks, today: today);

      expect(result.map((t) => t.id), [
        'lateUrgent',
        'lateMedium',
        'todayUrgent',
        'todayLow',
        'futureLow',
        'noDueHigh',
      ]);
    });

    test('CA-06 mesma tarefa referenciada sem cópias', () {
      final task = build(id: 'shared', priority: Priority.urgent,
          dueDate: tomorrow);
      final all = tasksForView(SmartView.all, [task], today: today);
      final important = tasksForView(SmartView.important, [task],
          today: today);
      final planned =
          tasksForView(SmartView.planned, [task], today: today);

      expect(identical(all.single, task), isTrue);
      expect(identical(important.single, task), isTrue);
      expect(identical(planned.single, task), isTrue);
    });
  });
}
