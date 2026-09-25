import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/task_fixtures.dart';

void main() {
  late InMemoryTaskRepository repository;
  late TasksService service;

  late InMemoryMyDayRepository myDay;

  setUp(() {
    repository = InMemoryTaskRepository();
    myDay = InMemoryMyDayRepository();
    service = TasksService(repository, myDay, clock: () => kTestNow);
  });

  test('cria tarefa com posição incremental e título validado', () async {
    final first = await service.createTask(title: 'Primeira');
    final second = await service.createTask(title: 'Segunda', notes: 'Obs');

    expect(first.position, 0);
    expect(second.position, 1);
    expect(second.notes, 'Obs');

    expect(
      () => service.createTask(title: '   '),
      throwsA(isA<TaskException>()),
    );
  });

  test('edita, conclui, reabre e move para lixeira', () async {
    final task = await service.createTask(title: 'Original');
    final renamed = await service.renameTask(
      task.id,
      title: 'Editada',
      notes: 'Detalhes',
    );
    expect(renamed.title, 'Editada');

    final completed = await service.completeTask(task.id);
    expect(completed.status, TaskStatus.completed);

    final reopened = await service.reopenTask(task.id);
    expect(reopened.status, TaskStatus.active);

    final trashed = await service.moveToTrash(task.id);
    expect(trashed.status, TaskStatus.trash);

    final restored = await service.restore(task.id);
    expect(restored.status, TaskStatus.active);
  });

  test('ciclo de subtarefas: adicionar, renomear, concluir, remover', () async {
    final task = await service.createTask(title: 'T');
    final withSubtask = await service.addSubtask(
      task.id,
      description: 'Etapa um',
    );
    final subtaskId = withSubtask.subtasks.single.id;

    final renamed = await service.renameSubtask(
      task.id,
      subtaskId,
      description: 'Etapa renomeada',
    );
    expect(renamed.subtasks.single.description, 'Etapa renomeada');

    final completed = await service.setSubtaskCompleted(
      task.id,
      subtaskId,
      completed: true,
    );
    expect(completed.subtasks.single.isCompleted, isTrue);
    expect(completed.progress, 1.0);

    final removed = await service.removeSubtask(task.id, subtaskId);
    expect(removed.subtasks, isEmpty);
    expect(removed.progress, isNull);
  });

  test('reordena subtarefas com persistência da ordem', () async {
    var task = await service.createTask(title: 'T');
    task = await service.addSubtask(task.id, description: 'Uma');
    task = await service.addSubtask(task.id, description: 'Duas');
    final ids = [for (final s in task.subtasks) s.id];

    final reordered = await service.reorderSubtasks(
      task.id,
      [ids[1], ids[0]],
    );
    expect(reordered.subtasks.map((s) => s.id), [ids[1], ids[0]]);
  });

  test('operações em tarefa inexistente falham', () async {
    expect(
      () => service.completeTask('missing'),
      throwsA(isA<TaskException>().having(
        (e) => e.failure,
        'failure',
        TaskFailure.unknownTask,
      )),
    );
    expect(
      () => service.addSubtask('missing', description: 'Etapa'),
      throwsA(isA<TaskException>()),
    );
  });

  test('subtarefa de outra tarefa é rejeitada', () async {
    final task = await service.createTask(title: 'T');
    await service.addSubtask(task.id, description: 'Etapa');
    expect(
      () => service.renameSubtask(task.id, 'ghost', description: 'X'),
      throwsA(isA<TaskException>().having(
        (e) => e.failure,
        'failure',
        TaskFailure.unknownSubtask,
      )),
    );
  });

  test('hierarquia vai junto para a lixeira e volta restaurada', () async {
    var task = await service.createTask(title: 'T');
    task = await service.addSubtask(task.id, description: 'Uma');
    final subtaskId = task.subtasks.single.id;
    await service.setSubtaskCompleted(task.id, subtaskId, completed: true);

    await service.moveToTrash(task.id);
    final trashed = await service.fetchTask(task.id);
    expect(trashed!.status, TaskStatus.trash);
    expect(trashed.subtasks.single.isCompleted, isTrue);

    final restored = await service.restore(task.id);
    expect(restored.status, TaskStatus.active);
    expect(restored.subtasks.single.isCompleted, isTrue);
  });
}
