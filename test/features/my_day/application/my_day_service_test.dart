import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/my_day/application/my_day_service.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_task_repository.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryMyDayRepository myDay;
  late MyDayService myDayService;
  late TasksService tasksService;
  var idCounter = 0;

  String newId() => 'id-${idCounter++}';

  // Meia-noite local de 2026-09-24 como "hoje" para o serviço.
  final day1 = DateTime(2026, 9, 24, 0, 30);
  final day2 = DateTime(2026, 9, 25, 0, 30);

  setUp(() {
    idCounter = 0;
    tasks = InMemoryTaskRepository();
    myDay = InMemoryMyDayRepository();
    final organization = InMemoryOrganizationRepository(tasks);
    myDayService = MyDayService(
      myDay,
      tasks,
      now: () => day1,
      generateId: newId,
    );
    tasksService = TasksService(
      tasks,
      organizationRepository: organization,
      myDayRepository: myDay,
      now: () => day1,
      generateId: newId,
    );
  });

  test('CA-09 adicionar tarefa ativa sem alterar dados de origem', () async {
    final taskId = await tasksService.createTask(
      title: 'Foco',
      notes: 'nota',
      listId: null,
    );
    final before = tasks.taskById(taskId);

    await myDayService.addToMyDay(taskId);

    final entries = await myDay.getEntries(myDayService.today);
    expect(entries.single.taskId, taskId);
    final after = tasks.taskById(taskId);
    expect(after, before);
  });

  test('CA-10 prazo permanece inalterado ao adicionar ao My Day', () async {
    final due = DateTime(2026, 9, 30);
    final taskId = await tasksService.createTask(
      title: 'Com prazo',
      dueDate: due,
      priority: Priority.high,
    );

    await myDayService.addToMyDay(taskId);

    final task = tasks.taskById(taskId);
    expect(task!.dueDate, due);
    expect(task.priority, Priority.high);
  });

  test('RF-06 rejeita tarefa concluída ou na lixeira', () async {
    final completedId = await tasksService.createTask(title: 'Feita');
    await tasksService.toggleCompletion(completedId);
    final trashedId = await tasksService.createTask(title: 'Lixeira');
    await tasksService.moveToTrash(trashedId);

    await expectLater(
      myDayService.addToMyDay(completedId),
      throwsA(isA<InactiveTaskMyDayException>()),
    );
    await expectLater(
      myDayService.addToMyDay(trashedId),
      throwsA(isA<InactiveTaskMyDayException>()),
    );
    expect(await myDay.getEntries(myDayService.today), isEmpty);
  });

  test('CA-11 reordenação manual é preservada', () async {
    final a = await tasksService.createTask(title: 'A');
    final b = await tasksService.createTask(title: 'B');
    final c = await tasksService.createTask(title: 'C');
    await myDayService.addToMyDay(a);
    await myDayService.addToMyDay(b);
    await myDayService.addToMyDay(c);

    await myDayService.reorder(2, 0);

    final entries = await myDay.getEntries(myDayService.today);
    expect(entries.map((e) => e.taskId), [c, a, b]);
    expect(entries.map((e) => e.position), [0, 1, 2]);
  });

  test('CA-12 remover do My Day mantém a tarefa na origem', () async {
    final listlessId = await tasksService.createTask(title: 'Inbox');
    await myDayService.addToMyDay(listlessId);

    await myDayService.removeFromMyDay(listlessId);

    expect(await myDay.getEntries(myDayService.today), isEmpty);
    final task = tasks.taskById(listlessId);
    expect(task, isNotNull);
    expect(task!.listId, isNull);
    expect(task.isActive, isTrue);
  });

  test('CA-13 concluir no My Day sai do foco e preserva subtarefas',
      () async {
    final taskId = await tasksService.createTask(title: 'Principal');
    await tasksService.addSubtask(taskId, title: 'Etapa pendente');
    await myDayService.addToMyDay(taskId);

    await tasksService.toggleCompletion(taskId);

    expect(await myDay.getEntries(myDayService.today), isEmpty);
    final task = tasks.taskById(taskId);
    expect(task!.status, TaskStatus.completed);
    expect(task.subtasks.single.isCompleted, isFalse);
  });

  test('CA-14/CA-15 rollover idempotente devolve inbox à origem', () async {
    final inboxId = await tasksService.createTask(title: 'Sem lista');
    final otherId = await tasksService.createTask(title: 'Outra');
    await myDayService.addToMyDay(inboxId);
    await myDayService.addToMyDay(otherId);

    // Virada do dia: o serviço passa a considerar "hoje" = dia 2.
    final nextDay = MyDayService(
      myDay,
      tasks,
      now: () => day2,
      generateId: newId,
    );
    await nextDay.rollover();
    // Idempotente: repetir não altera nada.
    await nextDay.rollover();

    expect(await myDay.getEntries(nextDay.today), isEmpty);
    expect(await myDay.getEntries(myDayService.today), isEmpty);

    final inboxTask = tasks.taskById(inboxId);
    expect(inboxTask!.listId, isNull); // CA-15: volta à inbox, sem lista
    final other = tasks.taskById(otherId);
    expect(other!.isActive, isTrue); // CA-14: dados intactos
    expect(other.listId, isNull);
  });

  test('RF-05 tarefa na lixeira sai do My Day', () async {
    final taskId = await tasksService.createTask(title: 'X');
    await myDayService.addToMyDay(taskId);

    await tasksService.moveToTrash(taskId);

    expect(await myDay.getEntries(myDayService.today), isEmpty);
  });
}
