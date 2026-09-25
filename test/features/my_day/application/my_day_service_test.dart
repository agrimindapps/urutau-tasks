import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/my_day/application/my_day_service.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/task_fixtures.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryMyDayRepository myDay;
  late TasksService tasksService;
  late MyDayService service;

  setUp(() {
    tasks = InMemoryTaskRepository();
    myDay = InMemoryMyDayRepository();
    tasksService = TasksService(tasks, myDay, clock: () => kTestNow);
    service = MyDayService(myDay, tasks, clock: () => kTestNow);
  });

  test('adiciona tarefa ativa ao dia de hoje (RF-06, CA-09)', () async {
    final task = await tasksService.createTask(title: 'Focar');
    final entry = await service.addToday(task.id);

    expect(entry.date, '2026-09-25');
    expect(entry.taskId, task.id);
    expect(myDay.allEntries.length, 1);
  });

  test('concluída ou lixeira não entra (RF-06)', () async {
    final completed = await tasksService.createTask(title: 'Feita');
    await tasksService.completeTask(completed.id);
    expect(
      () => service.addToday(completed.id),
      throwsA(isA<MyDayException>().having(
        (e) => e.failure,
        'failure',
        MyDayFailure.taskNotEligible,
      )),
    );

    final trashed = await tasksService.createTask(title: 'Fora');
    await tasksService.moveToTrash(trashed.id);
    expect(
      () => service.addToday(trashed.id),
      throwsA(isA<MyDayException>()),
    );
  });

  test('a mesma tarefa não entra duas vezes no mesmo dia (RF-10)', () async {
    final task = await tasksService.createTask(title: 'Única');
    await service.addToday(task.id);
    expect(
      () => service.addToday(task.id),
      throwsA(isA<MyDayException>().having(
        (e) => e.failure,
        'failure',
        MyDayFailure.alreadyAdded,
      )),
    );
  });

  test('remover do My Day não altera a tarefa (RF-08, CA-12)', () async {
    final task = await tasksService.createTask(title: 'Sai do foco');
    await service.addToday(task.id);

    await service.removeToday(task.id);

    expect(myDay.allEntries, isEmpty);
    final kept = await tasksService.fetchTask(task.id);
    expect(kept!.title, 'Sai do foco');
    expect(kept.status, TaskStatus.active);
  });

  test('reordena preservando a ordem manual (RF-07, RF-12, CA-11)', () async {
    final a = await tasksService.createTask(title: 'A');
    final b = await tasksService.createTask(title: 'B');
    final c = await tasksService.createTask(title: 'C');
    await service.addToday(a.id);
    await service.addToday(b.id);
    await service.addToday(c.id);

    await service.reorderToday([c.id, a.id, b.id]);

    final entries = (await service.fetchEntries())
        .where((e) => e.date == '2026-09-25')
        .toList()
      ..sort((x, y) => x.position.compareTo(y.position));
    expect(entries.map((e) => e.taskId), [c.id, a.id, b.id]);
  });

  test('concluir remove do My Day (RF-09, CA-13)', () async {
    final task = await tasksService.createTask(title: 'Concluir aqui');
    await service.addToday(task.id);

    await tasksService.completeTask(task.id);

    expect(myDay.allEntries, isEmpty);
  });

  test('excluir para a lixeira remove do My Day (RF-05)', () async {
    final task = await tasksService.createTask(title: 'Excluir aqui');
    await service.addToday(task.id);

    await tasksService.moveToTrash(task.id);

    expect(myDay.allEntries, isEmpty);
  });

  group('Rollover (RF-10, CA-14/CA-15)', () {
    test('remove não concluídas de dias anteriores e é idempotente', () async {
      final task = await tasksService.createTask(title: 'Ontem');
      // Entrada de ontem (simulada diretamente no repositório).
      await myDay.saveEntry(MyDayEntry.create(
        id: 'old-entry',
        taskId: task.id,
        date: '2026-09-24',
        position: 0,
      ));
      final todayTask = await tasksService.createTask(title: 'Hoje');
      await service.addToday(todayTask.id);

      await service.rollover();
      await service.rollover(); // idempotente

      final remaining = await service.fetchEntries();
      expect(remaining.map((e) => e.taskId), [todayTask.id]);

      // Nada mais é alterado (RF-10).
      final kept = await tasksService.fetchTask(task.id);
      expect(kept!.status, TaskStatus.active);
    });

    test('tarefa sem lista volta à inbox sem mudança de dados (CA-15)', () async {
      final inbox = await tasksService.createTask(title: 'Inbox');
      await myDay.saveEntry(MyDayEntry.create(
        id: 'old-inbox',
        taskId: inbox.id,
        date: '2026-09-24',
        position: 0,
      ));

      await service.rollover();

      final kept = await tasksService.fetchTask(inbox.id);
      expect(kept!.listId, isNull);
      expect(kept.status, TaskStatus.active);
    });
  });
}
