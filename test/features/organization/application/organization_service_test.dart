import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/organization/application/organization_service.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';

import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_task_repository.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryOrganizationRepository organization;
  late OrganizationService orgService;
  late TasksService tasksService;
  var idCounter = 0;

  String newId() => 'id-${idCounter++}';

  setUp(() {
    idCounter = 0;
    tasks = InMemoryTaskRepository();
    organization = InMemoryOrganizationRepository(tasks);
    orgService = OrganizationService(organization, generateId: newId);
    tasksService = TasksService(
      tasks,
      organizationRepository: organization,
      now: () => DateTime.utc(2026, 9, 24, 12),
      generateId: newId,
    );
  });

  group('listas (CA-01, CA-02, CA-06 a CA-08)', () {
    test('CA-01 criar lista válida', () async {
      final id = await orgService.createList('  Compras  ');
      final lists = await organization.getLists();
      expect(lists.single.name, 'Compras');
      expect(lists.single.id, id);
    });

    test('CA-02 rejeita nome duplicado sem alterar a existente', () async {
      await orgService.createList('Trabalho');
      final other = await orgService.createList('Outra');
      await expectLater(
        orgService.createList('  trabalho '),
        throwsA(isA<DuplicateNameException>()),
      );
      await expectLater(
        orgService.renameList(other, 'TRABALHO'),
        throwsA(isA<DuplicateNameException>()),
      );
      final lists = await organization.getLists();
      expect(lists.map((l) => l.name), containsAll(['Trabalho', 'Outra']));
      expect(
        lists.firstWhere((l) => l.id == other).name,
        'Outra',
      );
    });

    test('CA-06 excluir lista vazia', () async {
      final a = await orgService.createList('A');
      await orgService.createList('B');
      await orgService.deleteList(a);

      final lists = await organization.getLists();
      expect(lists.map((l) => l.name), ['B']);
    });

    test('CA-07 excluir lista com tarefas exige destino', () async {
      final a = await orgService.createList('A');
      await orgService.createList('B');
      final taskId =
          await tasksService.createTask(title: 'T', listId: a);

      await expectLater(
        orgService.deleteList(a),
        throwsA(isA<ListNotEmptyException>()),
      );
      expect((tasks.taskById(taskId))!.listId, a);
      expect((await organization.getLists()).map((l) => l.id), [a, 'id-1']);
    });

    test('CA-08 excluir lista com destino move as tarefas', () async {
      final a = await orgService.createList('A');
      final b = await orgService.createList('B');
      final taskId = await tasksService.createTask(title: 'T', listId: a);
      await tasksService.addSubtask(taskId, title: 'Etapa');
      final before = tasks.taskById(taskId);

      await orgService.deleteList(a, destinationId: b);

      final after = tasks.taskById(taskId);
      expect((await organization.getLists()).map((l) => l.id), [b]);
      expect(after!.listId, b);
      expect(after.id, before!.id);
      expect(after.subtasks, before.subtasks);
      expect(after.tags, before.tags);
      expect(after.status, before.status);
    });

    test('RF-06 bloqueia exclusão sem outra lista disponível', () async {
      final a = await orgService.createList('A');
      await tasksService.createTask(title: 'T', listId: a);

      await expectLater(
        orgService.deleteList(a),
        throwsA(isA<NoDestinationAvailableException>()),
      );
      expect((await organization.getLists()).single.id, a);
    });
  });

  group('grupos (CA-09)', () {
    test('CA-09 excluir grupo preserva listas sem grupo', () async {
      final group = await orgService.createGroup('Projetos');
      final listId = await orgService.createList('Site', groupId: group);

      await orgService.deleteGroup(group);

      expect((await organization.watchGroups().first), isEmpty);
      final lists = await organization.getLists();
      expect(lists.single.id, listId);
      expect(lists.single.groupId, isNull);
      expect(lists.single.name, 'Site');
    });
  });

  group('categorias e tags (CA-10 a CA-13)', () {
    test('CA-10 criar e aplicar categoria na edição', () async {
      final taskId = await tasksService.createTask(title: 'T');
      final categoryId = await orgService.createCategory('Casa');

      await tasksService.setTaskCategory(taskId, categoryId);

      final task = tasks.taskById(taskId);
      expect(task!.categoryId, categoryId);
      expect(
        await organization.watchCategories().first,
        hasLength(1),
      );
    });

    test('CA-11 excluir categoria desvincula sem alterar tarefas', () async {
      final taskId = await tasksService.createTask(title: 'T', notes: 'n');
      final categoryId = await orgService.createCategory('Casa');
      await tasksService.setTaskCategory(taskId, categoryId);

      await orgService.deleteCategory(categoryId);

      final task = tasks.taskById(taskId);
      expect(task!.categoryId, isNull);
      expect(task.title, 'T');
      expect(task.notes, 'n');
      expect(await organization.watchCategories().first, isEmpty);
    });

    test('CA-12 tags equivalentes não são duplicadas', () async {
      final first = await orgService.ensureTag('Trabalho');
      final second = await orgService.ensureTag('  trabalho ');
      final third = await orgService.ensureTag('TRABALHO');

      expect(second.id, first.id);
      expect(third.id, first.id);
      expect(await organization.watchTags().first, hasLength(1));
    });

    test('CA-13 excluir tag remove das tarefas preservando dados', () async {
      final taskId = await tasksService.createTask(title: 'T');
      final tag = await orgService.ensureTag('urgente');
      await tasksService.setTaskTags(taskId, [tag]);

      await orgService.deleteTag(tag.id);

      final task = tasks.taskById(taskId);
      expect(task!.tags, isEmpty);
      expect(task.title, 'T');
      expect(await organization.watchTags().first, isEmpty);
    });
  });

  group('movimentação e inbox (CA-03 a CA-05)', () {
    test('CA-03 criar tarefa sem lista permanece na inbox', () async {
      final taskId = await tasksService.createTask(title: 'Sem lista');
      final task = tasks.taskById(taskId);

      expect(task!.listId, isNull);
      expect(task.isDeleted, isFalse);
    });

    test('CA-04 atribuir tarefa à lista e removê-la do filtro sem lista',
        () async {
      final listId = await orgService.createList('Projetos');
      final taskId = await tasksService.createTask(title: 'T');
      expect((tasks.taskById(taskId))!.listId, isNull);

      await tasksService.moveTaskToList(taskId, listId);
      expect((tasks.taskById(taskId))!.listId, listId);

      await tasksService.moveTaskToList(taskId, null);
      expect((tasks.taskById(taskId))!.listId, isNull);
    });

    test('CA-05 mover hierarquia preserva subtarefas e demais dados',
        () async {
      final a = await orgService.createList('A');
      final b = await orgService.createList('B');
      final taskId =
          await tasksService.createTask(title: 'T', listId: a, notes: 'n');
      await tasksService.addSubtask(taskId, title: 'Etapa');
      final tag = await orgService.ensureTag('tag-x');
      await tasksService.setTaskTags(taskId, [tag]);
      final categoryId = await orgService.createCategory('Cat');
      await tasksService.setTaskCategory(taskId, categoryId);
      final before = tasks.taskById(taskId);

      await tasksService.moveTaskToList(taskId, b);

      final after = tasks.taskById(taskId);
      expect(after!.listId, b);
      expect(after.id, before!.id);
      expect(after.subtasks.map((s) => s.id), before.subtasks.map((s) => s.id));
      expect(after.subtasks.map((s) => s.title), ['Etapa']);
      expect(after.categoryId, categoryId);
      expect(after.tags.map((t) => t.id), [tag.id]);
      expect(after.notes, 'n');
    });

    test('mover tarefa para lista inexistente é rejeitada', () async {
      final taskId = await tasksService.createTask(title: 'T');
      await expectLater(
        tasksService.moveTaskToList(taskId, 'missing'),
        throwsStateError,
      );
    });
  });

  group('ordem manual (CA-14)', () {
    test('CA-14 reordenar listas persiste a ordem', () async {
      await orgService.createList('Um');
      await orgService.createList('Dois');
      await orgService.createList('Três');

      await orgService.reorderLists(2, 0);

      expect(
        (await organization.getLists()).map((l) => l.name),
        ['Três', 'Um', 'Dois'],
      );
      expect(
        (await organization.getLists()).map((l) => l.position),
        [0, 1, 2],
      );
    });
  });
}
