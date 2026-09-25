import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/organization/application/organization_service.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_recurrence_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/task_fixtures.dart';

void main() {
  late InMemoryOrganizationRepository organization;
  late InMemoryTaskRepository tasks;
  late OrganizationService service;
  late TasksService tasksService;

  setUp(() {
    tasks = InMemoryTaskRepository();
    organization = InMemoryOrganizationRepository(tasks);
    service = OrganizationService(
      organization,
      tasks,
      clock: () => kTestNow,
    );
    tasksService = TasksService(
      tasks,
      InMemoryMyDayRepository(),
      InMemoryRecurrenceRepository(),
      clock: () => kTestNow,
    );
  });

  group('Unicidade de nomes (RF-01, CA-02)', () {
    test('rejeita nomes duplicados dentro do tipo', () async {
      await service.createList(name: 'Casa');
      expect(
        () => service.createList(name: ' Casa '),
        throwsA(isA<OrganizationException>().having(
          (e) => e.failure,
          'failure',
          OrganizationFailure.duplicateName,
        )),
      );
      // Tipos diferentes não colidem entre si.
      expect(() => service.createGroup(name: 'Casa'), returnsNormally);
      expect(() => service.createCategory(name: 'Casa'), returnsNormally);
    });

    test('renomear para nome existente é rejeitado', () async {
      await service.createList(name: 'Casa');
      final work = await service.createList(name: 'Trabalho');
      expect(
        () => service.renameList(work.id, name: 'Casa'),
        throwsA(isA<OrganizationException>()),
      );
    });
  });

  group('Listas e inbox (RF-02, RF-03, CA-01, CA-03, CA-04)', () {
    test('criar lista e tarefa sem lista (inbox implícita)', () async {
      final list = await service.createList(name: 'Casa');
      final task = await tasksService.createTask(title: 'Solta');
      expect(task.listId, isNull);

      final assigned = await service.assignListToTask(task.id, list.id);
      expect(assigned.listId, list.id);
      expect(assigned.title, 'Solta');
    });

    test('remover lista devolve a tarefa à inbox', () async {
      final list = await service.createList(name: 'Casa');
      final task = await tasksService.createTask(title: 'T');
      await service.assignListToTask(task.id, list.id);
      final back = await service.assignListToTask(task.id, null);
      expect(back.listId, isNull);
    });
  });

  group('Exclusão de lista (RF-06, CA-06, CA-07, CA-08)', () {
    test('lista vazia é excluída diretamente', () async {
      final list = await service.createList(name: 'Vazia');
      await service.deleteList(list.id);
      expect(organization.allLists, isEmpty);
    });

    test('lista com tarefas exige destino', () async {
      final list = await service.createList(name: 'Com tarefas');
      await service.createList(name: 'Destino');
      final task = await tasksService.createTask(title: 'T');
      await service.assignListToTask(task.id, list.id);

      expect(
        () => service.deleteList(list.id),
        throwsA(isA<OrganizationException>().having(
          (e) => e.failure,
          'failure',
          OrganizationFailure.listNotEmpty,
        )),
      );
    });

    test('sem outra lista a exclusão fica bloqueada', () async {
      final list = await service.createList(name: 'Única');
      final task = await tasksService.createTask(title: 'T');
      await service.assignListToTask(task.id, list.id);

      expect(
        () => service.deleteList(list.id),
        throwsA(isA<OrganizationException>().having(
          (e) => e.failure,
          'failure',
          OrganizationFailure.listNotEmpty,
        )),
      );
    });

    test('destino não pode ser a própria lista', () async {
      final list = await service.createList(name: 'A');
      await service.createList(name: 'B');
      final task = await tasksService.createTask(title: 'T');
      await service.assignListToTask(task.id, list.id);

      expect(
        () => service.deleteList(list.id, destinationListId: list.id),
        throwsA(isA<OrganizationException>().having(
          (e) => e.failure,
          'failure',
          OrganizationFailure.sameDestination,
        )),
      );
    });

    test('exclui migrando a hierarquia preservando tudo (CA-05, CA-08)',
        () async {
      final source = await service.createList(name: 'Origem');
      final destination = await service.createList(name: 'Destino');
      var task = await tasksService.createTask(title: 'Migrada', notes: 'N');
      task = await tasksService.addSubtask(task.id, description: 'Etapa');
      final subtask = task.subtasks.single;
      await tasksService.setSubtaskCompleted(
        task.id,
        subtask.id,
        completed: true,
      );
      await service.assignListToTask(task.id, source.id);

      await service.deleteList(source.id, destinationListId: destination.id);

      final migrated = await tasksService.fetchTask(task.id);
      expect(migrated!.listId, destination.id);
      expect(migrated.notes, 'N');
      expect(migrated.subtasks.single.description, 'Etapa');
      expect(migrated.subtasks.single.isCompleted, isTrue);
      expect(organization.allLists.map((l) => l.id), [destination.id]);
    });
  });

  group('Grupos (RF-04, RF-05, CA-09)', () {
    test('excluir grupo mantém as listas sem grupo', () async {
      final group = await service.createGroup(name: 'Projeto');
      final list = await service.createList(name: 'Casa', groupId: group.id);
      await service.deleteGroup(group.id);

      expect(organization.allGroups, isEmpty);
      final remaining = organization.allLists.single;
      expect(remaining.id, list.id);
      expect(remaining.groupId, isNull);
    });

    test('lista pertence a no máximo um grupo', () async {
      final g1 = await service.createGroup(name: 'Um');
      final g2 = await service.createGroup(name: 'Dois');
      final list = await service.createList(name: 'Casa');
      await service.moveListToGroup(list.id, g1.id);
      final moved = await service.moveListToGroup(list.id, g2.id);
      expect(moved.groupId, g2.id);
    });
  });

  group('Categorias (RF-08, CA-10, CA-11)', () {
    test('aplicar, substituir e remover categoria', () async {
      final work = await service.createCategory(name: 'Trabalho');
      final home = await service.createCategory(name: 'Casa');
      final task = await tasksService.createTask(title: 'T');

      var updated = await service.assignCategoryToTask(task.id, work.id);
      expect(updated.categoryId, work.id);

      updated = await service.assignCategoryToTask(task.id, home.id);
      expect(updated.categoryId, home.id);

      updated = await service.assignCategoryToTask(task.id, null);
      expect(updated.categoryId, isNull);
    });

    test('excluir categoria apenas desvincula (CA-11)', () async {
      final category = await service.createCategory(name: 'Temporária');
      final task = await tasksService.createTask(title: 'T');
      await service.assignCategoryToTask(task.id, category.id);

      await service.deleteCategory(category.id);

      final updated = await tasksService.fetchTask(task.id);
      expect(updated!.categoryId, isNull);
      expect(updated.title, 'T');
      expect(organization.allCategories, isEmpty);
    });
  });

  group('Tags (RF-09, CA-12, CA-13)', () {
    test('nomes equivalentes após normalização reutilizam a tag', () async {
      final first = await service.ensureTag(name: ' Trabalho ');
      final second = await service.ensureTag(name: 'trabalho');
      expect(second.id, first.id);
      expect(organization.allTags.length, 1);
    });

    test('criar tag duplicada é rejeitado', () async {
      await service.createTag(name: 'Trabalho');
      expect(
        () => service.createTag(name: 'TRABALHO'),
        throwsA(isA<OrganizationException>().having(
          (e) => e.failure,
          'failure',
          OrganizationFailure.duplicateName,
        )),
      );
    });

    test('adicionar e remover tag na tarefa (CA-13)', () async {
      final tag = await service.ensureTag(name: 'trabalho');
      final task = await tasksService.createTask(title: 'T');

      var updated = await service.addTagToTask(task.id, tag.id);
      expect(updated.tagIds, [tag.id]);

      updated = await service.removeTagFromTask(task.id, tag.id);
      expect(updated.tagIds, isEmpty);
      expect(organization.allTags.length, 1);
    });

    test('excluir tag remove apenas as associações', () async {
      final tag = await service.ensureTag(name: 'temporária');
      final task = await tasksService.createTask(title: 'T');
      await service.addTagToTask(task.id, tag.id);

      await service.deleteTag(tag.id);

      final updated = await tasksService.fetchTask(task.id);
      expect(updated!.tagIds, isEmpty);
      expect(updated.title, 'T');
    });
  });

  group('Ordenação (RF-10, CA-14)', () {
    test('reordenar listas preserva a ordem entre sessões', () async {
      final a = await service.createList(name: 'A');
      final b = await service.createList(name: 'B');
      final c = await service.createList(name: 'C');

      await service.reorderLists([c.id, a.id, b.id]);

      final snapshot = await service.fetchSnapshot();
      expect(snapshot.lists.map((l) => l.id), [c.id, a.id, b.id]);
      expect(snapshot.lists.map((l) => l.position), [0, 1, 2]);
    });

    test('reordenar grupos', () async {
      final g1 = await service.createGroup(name: 'Um');
      final g2 = await service.createGroup(name: 'Dois');
      await service.reorderGroups([g2.id, g1.id]);
      final snapshot = await service.fetchSnapshot();
      expect(snapshot.groups.map((g) => g.id), [g2.id, g1.id]);
    });
  });

  group('Atribuições preservam a hierarquia (RF-07)', () {
    test('mover tarefa com subtarefas para outra lista', () async {
      final l1 = await service.createList(name: 'Uma');
      final l2 = await service.createList(name: 'Duas');
      var task = await tasksService.createTask(title: 'T');
      task = await tasksService.addSubtask(task.id, description: 'Etapa');
      await service.assignListToTask(task.id, l1.id);

      final moved = await service.assignListToTask(task.id, l2.id);
      expect(moved.listId, l2.id);
      expect(moved.subtasks.single.description, 'Etapa');
      expect(moved.id, task.id);
    });
  });
}
