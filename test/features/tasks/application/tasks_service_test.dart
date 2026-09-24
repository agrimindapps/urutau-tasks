import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_task_repository.dart';

void main() {
  late InMemoryTaskRepository repository;
  late TasksService service;
  var idCounter = 0;
  final fixedNow = DateTime.utc(2026, 9, 24, 12);

  setUp(() {
    repository = InMemoryTaskRepository();
    idCounter = 0;
    service = TasksService(
      repository,
      now: () => fixedNow,
      generateId: () => 'id-${idCounter++}',
    );
  });

  group('criação e edição (RF-01/RF-03, CA-01/CA-02)', () {
    test('CA-01 cria tarefa no estado Ativa', () async {
      final id = await service.createTask(title: '  Estudar Drift  ');
      final task = await repository.getTask(id);

      expect(task, isNotNull);
      expect(task!.title, 'Estudar Drift');
      expect(task.status, TaskStatus.active);
      expect(task.isDeleted, isFalse);
      expect(task.position, 0);
    });

    test('CA-02 rejeita título vazio ao criar e ao editar', () async {
      await expectLater(
        service.createTask(title: '   '),
        throwsA(isA<InvalidTitleException>()),
      );
      final id = await service.createTask(title: 'Válida');
      await expectLater(
        service.editTask(id, title: '  '),
        throwsA(isA<InvalidTitleException>()),
      );
      expect((await repository.getTask(id))!.title, 'Válida');
    });

    test('edição preserva identidade e subtarefas', () async {
      final id = await service.createTask(title: 'Original');
      await service.addSubtask(id, title: 'Etapa 1');
      await service.editTask(id, title: 'Renomeada', notes: 'nota');

      final task = await repository.getTask(id);
      expect(task!.id, id);
      expect(task.title, 'Renomeada');
      expect(task.notes, 'nota');
      expect(task.subtasks.single.title, 'Etapa 1');
    });

    test('itens na lixeira não podem ser editados (RF-01)', () async {
      final id = await service.createTask(title: 'Para lixeira');
      await service.moveToTrash(id);

      await expectLater(
        service.editTask(id, title: 'Nova'),
        throwsStateError,
      );
      expect((await repository.getTask(id))!.title, 'Para lixeira');
    });
  });

  group('subtarefas (RF-05 a RF-08)', () {
    test('CA-03 adicionar, editar, concluir e reabrir sem afetar a tarefa',
        () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.addSubtask(taskId, title: 'Etapa');
      final task = await repository.getTask(taskId);
      final subtaskId = task!.subtasks.single.id;

      await service.editSubtask(taskId, subtaskId, title: 'Etapa editada');
      await service.toggleSubtaskCompletion(taskId, subtaskId);
      expect((await repository.getTask(taskId))!.subtasks.single.isCompleted,
          isTrue);
      expect((await repository.getTask(taskId))!.status, TaskStatus.active);

      await service.toggleSubtaskCompletion(taskId, subtaskId);
      final reopened = await repository.getTask(taskId);
      expect(reopened!.subtasks.single.isCompleted, isFalse);
      expect(reopened.status, TaskStatus.active);
    });

    test('CA-05 remover subtarefa não afeta as demais nem a lixeira',
        () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.addSubtask(taskId, title: 'A');
      await service.addSubtask(taskId, title: 'B');
      final task = await repository.getTask(taskId);
      final first = task!.subtasks.first.id;

      await service.removeSubtask(taskId, first);

      final after = await repository.getTask(taskId);
      expect(after!.subtasks, hasLength(1));
      expect(after.subtasks.single.title, 'B');
      expect(after.subtasks.single.position, 0);
      expect(after.isDeleted, isFalse);
      expect(after.status, TaskStatus.active);
    });

    test('CA-04 mover subtarefa renumera posições', () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.addSubtask(taskId, title: 'A');
      await service.addSubtask(taskId, title: 'B');
      await service.addSubtask(taskId, title: 'C');

      await service.moveSubtask(taskId, 2, 0);

      final task = await repository.getTask(taskId);
      expect(task!.subtasks.map((s) => s.title), ['C', 'A', 'B']);
      expect(task.subtasks.map((s) => s.position), [0, 1, 2]);
    });

    test('progresso segue RF-08', () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.addSubtask(taskId, title: 'A');
      await service.addSubtask(taskId, title: 'B');
      final task = await repository.getTask(taskId);
      await service.toggleSubtaskCompletion(taskId, task!.subtasks.first.id);

      expect(formatProgress((await repository.getTask(taskId))!.progress!),
          '1/2');
    });

    test('RF-05 subtarefas não podem ser adicionadas na lixeira', () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.moveToTrash(taskId);

      await expectLater(
        service.addSubtask(taskId, title: 'Nova'),
        throwsStateError,
      );
    });
  });

  group('conclusão, lixeira e restauração (RF-04/RF-09/RF-10)', () {
    test('CA-07 concluir com subtarefas pendentes', () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.addSubtask(taskId, title: 'Pendente');

      await service.toggleCompletion(taskId);

      final task = await repository.getTask(taskId);
      expect(task!.status, TaskStatus.completed);
      expect(task.subtasks.single.isCompleted, isFalse);
      expect(task.completedAt, fixedNow);
    });

    test('CA-09 mover hierarquia para a lixeira', () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.addSubtask(taskId, title: 'A');
      await service.moveToTrash(taskId);

      final task = await repository.getTask(taskId);
      expect(task!.isDeleted, isTrue);
      expect(task.deletedAt, fixedNow);
      expect(task.subtasks.single.title, 'A');
    });

    test('CA-10 restaurar recupera estado e UUIDs', () async {
      final taskId = await service.createTask(title: 'Principal');
      await service.addSubtask(taskId, title: 'A');
      await service.toggleCompletion(taskId);
      final before = await repository.getTask(taskId);
      await service.moveToTrash(taskId);
      await service.restoreFromTrash(taskId);

      final restored = await repository.getTask(taskId);
      expect(restored!.id, before!.id);
      expect(restored.status, TaskStatus.completed);
      expect(restored.isDeleted, isFalse);
      expect(restored.subtasks.single.id, before.subtasks.single.id);
    });

    test('listagem oculta lixeira por padrão', () async {
      final id = await service.createTask(title: 'Visível');
      await service.createTask(title: 'Escondida');
      final second = (await repository.watchTasks().first)
          .firstWhere((t) => t.title == 'Escondida');
      await service.moveToTrash(second.id);

      final visible = await repository.watchTasks().first;
      expect(visible.map((t) => t.title), ['Visível']);
      expect(visible.map((t) => t.id), [id]);
    });
  });
}
