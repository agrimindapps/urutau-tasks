import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:urutau_tasks/src/features/views/domain/smart_views.dart';

import '../../../support/task_fixtures.dart';

void main() {
  const today = '2026-09-25';

  Task task(
    String id, {
    TaskStatus status = TaskStatus.active,
    TaskPriority? priority,
    String? dueDate,
    DateTime? reminder,
    int position = 0,
    DateTime? completedAt,
  }) {
    return buildTask(
      id: id,
      title: 'T $id',
      status: status,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      position: position,
      completedAt: completedAt,
    );
  }

  group('Todas (RF-01)', () {
    test('mostra somente tarefas principais ativas, inclusive sem lista', () {
      final tasks = [
        task('a'),
        task('b', status: TaskStatus.completed),
        task('c', status: TaskStatus.trash),
      ];
      final view = selectSmartView(SmartView.all, tasks, today: today);
      expect(view.map((t) => t.id), ['a']);
    });
  });

  group('Importante (RF-02)', () {
    test('prioridade alta ou urgente, qualquer lista', () {
      final tasks = [
        task('low', priority: TaskPriority.low),
        task('med', priority: TaskPriority.medium),
        task('high', priority: TaskPriority.high),
        task('urg', priority: TaskPriority.urgent),
        task('none'),
        task('done', status: TaskStatus.completed, priority: TaskPriority.urgent),
      ];
      final view = selectSmartView(SmartView.important, tasks, today: today);
      expect(view.map((t) => t.id).toSet(), {'high', 'urg'});
    });
  });

  group('Planejado (RF-03)', () {
    test('prazo ou lembrete, sem duplicação quando tem os dois', () {
      final tasks = [
        task('due', dueDate: '2026-09-30'),
        task('rem', reminder: DateTime.utc(2026, 9, 26)),
        task('both', dueDate: '2026-09-30', reminder: DateTime.utc(2026, 9, 26)),
        task('none'),
      ];
      final view = selectSmartView(SmartView.planned, tasks, today: today);
      expect(view.map((t) => t.id).toSet(), {'due', 'rem', 'both'});
      expect(view.length, 3);
    });

    test('atrasadas permanecem', () {
      final tasks = [task('late', dueDate: '2026-09-01')];
      final view = selectSmartView(SmartView.planned, tasks, today: today);
      expect(view.map((t) => t.id), ['late']);
    });
  });

  group('Concluídas (RF-04)', () {
    test('inclui ocorrências concluídas, mais recentes primeiro', () {
      final tasks = [
        task('old',
            status: TaskStatus.completed,
            completedAt: DateTime.utc(2026, 9, 1)),
        task('new',
            status: TaskStatus.completed,
            completedAt: DateTime.utc(2026, 9, 20)),
        task('active'),
      ];
      final view = selectSmartView(SmartView.completed, tasks, today: today);
      expect(view.map((t) => t.id), ['new', 'old']);
    });
  });

  group('Lixeira fora de todas as visões (RF-05)', () {
    test('tarefa na lixeira não aparece', () {
      final tasks = [
        task('t', status: TaskStatus.trash, priority: TaskPriority.urgent),
      ];
      for (final view in const [
        SmartView.all,
        SmartView.important,
        SmartView.planned,
        SmartView.completed,
      ]) {
        expect(selectSmartView(view, tasks, today: today), isEmpty);
      }
    });
  });

  group('My Day (RF-06, RF-12)', () {
    test('ordem manual do dia é preservada', () {
      final tasks = [
        task('a', position: 0),
        task('b', position: 1),
        task('c', position: 2),
      ];
      final view = selectSmartView(
        SmartView.myDay,
        tasks,
        today: today,
        myDayTaskIds: {'b', 'a'},
        myDayOrder: ['b', 'a'],
      );
      expect(view.map((t) => t.id), ['b', 'a']);
    });

    test('concluída ou lixeira não aparece no My Day', () {
      final tasks = [
        task('done', status: TaskStatus.completed),
        task('trashed', status: TaskStatus.trash),
        task('ok'),
      ];
      final view = selectSmartView(
        SmartView.myDay,
        tasks,
        today: today,
        myDayTaskIds: {'done', 'trashed', 'ok'},
        myDayOrder: ['done', 'trashed', 'ok'],
      );
      expect(view.map((t) => t.id), ['ok']);
    });
  });

  group('Ordenação das visões (RF-11)', () {
    test('atrasadas, hoje, próximas, prioridade, origem; sem prazo no fim', () {
      final tasks = [
        task('no-due-1', position: 0),
        task('late', dueDate: '2026-09-10', position: 1),
        task('today', dueDate: '2026-09-25', position: 2),
        task('future-low',
            dueDate: '2026-10-01',
            priority: TaskPriority.low,
            position: 3),
        task('future-urgent',
            dueDate: '2026-10-01',
            priority: TaskPriority.urgent,
            position: 4),
        task('future-none', dueDate: '2026-10-05', position: 5),
        task('no-due-2', priority: TaskPriority.high, position: 6),
      ];
      final view = selectSmartView(SmartView.all, tasks, today: today);
      expect(view.map((t) => t.id), [
        'late',
        'today',
        'future-urgent',
        'future-low',
        'future-none',
        'no-due-2',
        'no-due-1',
      ]);
    });
  });
}
