import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day_repository.dart';
import 'package:urutau_tasks/src/features/recurrence/application/recurrence_service.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_recurrence_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/task_fixtures.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryRecurrenceRepository recurrence;
  late MyDayRepository myDay;
  late TasksService tasksService;
  late RecurrenceService service;

  setUp(() {
    tasks = InMemoryTaskRepository();
    recurrence = InMemoryRecurrenceRepository();
    myDay = InMemoryMyDayRepository();
    tasksService = TasksService(tasks, myDay, recurrence, clock: () => kTestNow);
    service = RecurrenceService(recurrence, tasks, clock: () => kTestNow);
  });

  group('Prazos (RF-01, RF-02, CA-01/CA-02)', () {
    test('prazo passado é válido (atrasada), futuro também', () async {
      final task = await tasksService.createTask(title: 'Com prazo');
      final late = await tasksService.setDueDate(task.id, '2026-09-01');
      expect(late.dueDate, '2026-09-01');

      final future = await tasksService.setDueDate(task.id, '2026-10-01');
      expect(future.dueDate, '2026-10-01');
    });

    test('prazo fora do formato ISO é rejeitado', () async {
      final task = await tasksService.createTask(title: 'Inválida');
      expect(
        () => tasksService.setDueDate(task.id, '25/09/2026'),
        throwsA(isA<TaskException>()),
      );
    });
  });

  group('Lembretes (RF-03 a RF-05, CA-03 a CA-08)', () {
    test('lembrete pode existir sem prazo (CA-03)', () async {
      final task = await tasksService.createTask(title: 'Só lembrete');
      final updated = await tasksService.setReminder(
        task.id,
        DateTime.utc(2026, 9, 26, 12),
      );
      expect(updated.reminder, DateTime.utc(2026, 9, 26, 12));
      expect(updated.dueDate, isNull);
    });

    test('lembrete pode ser antes ou depois do prazo (CA-04)', () async {
      final task = await tasksService.createTask(title: 'Com prazo');
      await tasksService.setDueDate(task.id, '2026-09-30');

      final before = await tasksService.setReminder(
        task.id,
        DateTime.utc(2026, 9, 26, 12),
      );
      expect(before.reminder, DateTime.utc(2026, 9, 26, 12));

      final after = await tasksService.setReminder(
        task.id,
        DateTime.utc(2026, 10, 2, 9),
      );
      expect(after.reminder, DateTime.utc(2026, 10, 2, 9));
    });

    test('lembrete no passado é rejeitado (RF-04, CA-05)', () async {
      final task = await tasksService.createTask(title: 'Atrasada');
      expect(
        () => tasksService.setReminder(
          task.id,
          DateTime.utc(2026, 9, 25, 11),
        ),
        throwsA(isA<RecurrenceException>().having(
          (e) => e.failure,
          'failure',
          RecurrenceFailure.reminderInPast,
        )),
      );
    });

    test('lembrete no instante exato também é passado (RF-04)', () async {
      final task = await tasksService.createTask(title: 'Agora');
      expect(
        () => tasksService.setReminder(task.id, kTestNow),
        throwsA(isA<RecurrenceException>()),
      );
    });

    test('concluir preserva a configuração; reabrir mantém vencido '
        '(RF-05, CA-06/CA-07/CA-08)', () async {
      final task = await tasksService.createTask(title: 'Com lembrete');
      await tasksService.setReminder(task.id, DateTime.utc(2026, 9, 26, 12));

      final completed = await tasksService.completeTask(task.id);
      expect(completed.reminder, DateTime.utc(2026, 9, 26, 12));

      final reopened = await tasksService.reopenTask(task.id);
      expect(reopened.reminder, DateTime.utc(2026, 9, 26, 12));
    });
  });

  group('Criar série (RF-07, CA-18)', () {
    test('exige prazo como data-base', () async {
      final task = await tasksService.createTask(title: 'Sem prazo');
      expect(
        () => service.createSeries(task.id,
            frequency: RecurrenceFrequency.weekly),
        throwsA(isA<RecurrenceException>().having(
          (e) => e.failure,
          'failure',
          RecurrenceFailure.dueDateRequired,
        )),
      );
    });

    test('cria série com a data-base do prazo e vincula a tarefa', () async {
      final task = await tasksService.createTask(title: 'Semanal');
      await tasksService.setDueDate(task.id, '2026-09-25');

      final series = await service.createSeries(task.id,
          frequency: RecurrenceFrequency.weekly);

      expect(series.baseDate, '2026-09-25');
      expect(series.cancelled, isFalse);
      final linked = await tasksService.fetchTask(task.id);
      expect(linked!.seriesId, series.id);
    });
  });

  group('Concluir ocorrência (RF-11, CA-11 a CA-15)', () {
    test('gera a próxima ocorrência com novo prazo e sem subtarefas '
        '(CA-11/CA-12)', () async {
      var task = await tasksService.createTask(title: 'Diária');
      task = await tasksService.addSubtask(task.id, description: 'Etapa');
      await tasksService.setDueDate(task.id, '2026-09-25');
      final series = await service.createSeries(task.id,
          frequency: RecurrenceFrequency.daily);

      await tasksService.completeTask(task.id);

      final all = await tasksService.fetchTasks();
      final occurrences =
          all.where((t) => t.seriesId == series.id).toList();
      expect(occurrences.length, 2);

      final completed = occurrences
          .firstWhere((t) => t.status == TaskStatus.completed);
      final next = occurrences.firstWhere((t) => t.status == TaskStatus.active);
      expect(completed.dueDate, '2026-09-25');
      expect(completed.subtasks.length, 1); // histórico preservado (CA-14)
      expect(next.dueDate, '2026-09-26');
      expect(next.subtasks, isEmpty); // não copia subtarefas (CA-12)
      expect(next.title, 'Diária');
    });

    test('ocorrência atrasada gera apenas a próxima futura (CA-15)', () async {
      final task = await tasksService.createTask(title: 'Atrasada');
      await tasksService.setDueDate(task.id, '2026-09-01');
      final series = await service.createSeries(task.id,
          frequency: RecurrenceFrequency.daily);

      await tasksService.completeTask(task.id);

      final all = await tasksService.fetchTasks();
      final active = all
          .where((t) =>
              t.seriesId == series.id && t.status == TaskStatus.active)
          .single;
      // kTestNow = 2026-09-25; nenhuma retroativa entre 02 e 25.
      expect(active.dueDate, '2026-09-26');
      final total = all.where((t) => t.seriesId == series.id).length;
      expect(total, 2);
    });

    test('herda o lembrete recalculado pela relação com o prazo (CA-13)',
        () async {
      final task = await tasksService.createTask(title: 'Com lembrete');
      await tasksService.setDueDate(task.id, '2026-09-25');
      // Lembrete 1 dia depois do prazo, às 09:00 UTC.
      await tasksService.setReminder(task.id, DateTime.utc(2026, 9, 26, 9));
      final series = await service.createSeries(task.id,
          frequency: RecurrenceFrequency.weekly);

      await tasksService.completeTask(task.id);

      final all = await tasksService.fetchTasks();
      final next = all.firstWhere(
        (t) => t.seriesId == series.id && t.status == TaskStatus.active,
      );
      expect(next.dueDate, '2026-10-02');
      // Relação +1 dia preservada: 03/10 às 09:00 UTC.
      expect(next.reminder, DateTime.utc(2026, 10, 3, 9));
    });

    test('série cancelada não gera próxima ocorrência (CA-17)', () async {
      final task = await tasksService.createTask(title: 'Última');
      await tasksService.setDueDate(task.id, '2026-09-25');
      final series = await service.createSeries(task.id,
          frequency: RecurrenceFrequency.daily);
      await service.cancelSeries(series.id);

      await tasksService.completeTask(task.id);

      final all = await tasksService.fetchTasks();
      expect(all.where((t) => t.seriesId == series.id).length, 1);
      expect(recurrence.allSeries.single.cancelled, isTrue);
    });
  });

  group('Alterar regra (RF-12, CA-16)', () {
    test('frequência nova vale da ocorrência atual em diante', () async {
      final task = await tasksService.createTask(title: 'Mensal');
      await tasksService.setDueDate(task.id, '2026-09-30');
      final series = await service.createSeries(task.id,
          frequency: RecurrenceFrequency.monthly);

      final updated =
          await service.changeFrequency(series.id, frequency: RecurrenceFrequency.weekly);
      expect(updated.frequency, RecurrenceFrequency.weekly);

      await tasksService.completeTask(task.id);
      final all = await tasksService.fetchTasks();
      final next = all.firstWhere(
        (t) => t.seriesId == series.id && t.status == TaskStatus.active,
      );
      expect(next.dueDate, '2026-10-07');
    });

    test('mover prazo atualiza a data-base sem reescrever histórico', () async {
      final task = await tasksService.createTask(title: 'Remarcada');
      await tasksService.setDueDate(task.id, '2026-09-25');
      final series = await service.createSeries(task.id,
          frequency: RecurrenceFrequency.daily);

      await tasksService.setDueDate(task.id, '2026-09-28');

      final stored = await service.fetchSeries(series.id);
      expect(stored!.baseDate, '2026-09-28');
      final current = await tasksService.fetchTask(task.id);
      expect(current!.dueDate, '2026-09-28');
    });
  });
}
