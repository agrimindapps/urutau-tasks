import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/organization/application/organization_service.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_recurrence_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/pump_app.dart';
import '../../../support/task_fixtures.dart';

void main() {
  late InMemoryTaskRepository taskStore;
  late InMemoryOrganizationRepository orgStore;

  setUp(() {
    taskStore = InMemoryTaskRepository();
    orgStore = InMemoryOrganizationRepository(taskStore);
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
        tester,
        repository: taskStore,
        organization: orgStore,
      );

  testWidgets('criar lista, rejeitar duplicado e excluir lista vazia '
      '(CA-01, CA-02, CA-06)', (tester) async {
    await pump(tester);
    await tapNav(tester, icon: Icons.list_alt_outlined);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova lista'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), '  Casa  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Casa'), findsWidgets);

    // Nome duplicado é rejeitado (CA-02).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova lista'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), 'Casa');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Já existe um item com esse nome.'), findsOneWidget);

    // Lista vazia é excluída diretamente (CA-06).
    await _openMenu(tester, 'Casa');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Casa'), findsNothing);
  });

  testWidgets('excluir lista com tarefas exige destino e migra '
      '(CA-07, CA-08)', (tester) async {
    final orgService = OrganizationService(orgStore, taskStore);
    final taskService = TasksService(taskStore, InMemoryMyDayRepository(), InMemoryRecurrenceRepository());
    final source = await orgService.createList(name: 'Origem');
    await orgService.createList(name: 'Destino');
    var task = await taskService.createTask(title: 'Migrada');
    task = await taskService.addSubtask(task.id, description: 'Etapa');
    await orgService.assignListToTask(task.id, source.id);

    await pump(tester);
    await tapNav(tester, icon: Icons.list_alt_outlined);

    await _openMenu(tester, 'Origem');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha a lista de destino'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Destino'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Origem'), findsNothing);
    final migrated = await taskService.fetchTask(task.id);
    expect(migrated!.listId, isNotNull);
    expect(migrated.subtasks.single.description, 'Etapa');
  });

  testWidgets('sem outra lista a exclusão fica bloqueada (RF-06)',
      (tester) async {
    final orgService = OrganizationService(orgStore, taskStore);
    final taskService = TasksService(taskStore, InMemoryMyDayRepository(), InMemoryRecurrenceRepository());
    final list = await orgService.createList(name: 'Única');
    final task = await taskService.createTask(title: 'T');
    await orgService.assignListToTask(task.id, list.id);

    await pump(tester);
    await tapNav(tester, icon: Icons.list_alt_outlined);

    await _openMenu(tester, 'Única');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(
      find.text('A lista tem tarefas. Escolha uma lista de destino.'),
      findsOneWidget,
    );
  });

  testWidgets('excluir grupo mantém as listas (CA-09)', (tester) async {
    final orgService = OrganizationService(orgStore, taskStore);
    final group = await orgService.createGroup(name: 'Projeto');
    await orgService.createList(name: 'Casa', groupId: group.id);

    await pump(tester);
    await tapNav(tester, icon: Icons.list_alt_outlined);

    // O grupo expande para revelar a lista; menu do grupo é o do ExpansionTile.
    await _openMenu(tester, 'Projeto');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Projeto'), findsNothing);
    expect(find.text('Casa'), findsOneWidget);
  });

  testWidgets('categoria e tags na tarefa (CA-10 a CA-13)', (tester) async {
    final orgService = OrganizationService(orgStore, taskStore);
    final taskService = TasksService(
      taskStore,
      InMemoryMyDayRepository(),
      InMemoryRecurrenceRepository(),
      clock: () => kTestNow,
    );
    await orgService.createCategory(name: 'Trabalho');
    final task = await taskService.createTask(title: 'Revisar');

    await pump(tester);

    // Atribui categoria pelo detalhe.
    await tapNav(tester, icon: Icons.checklist_outlined);
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('category-picker-${task.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trabalho').last);
    await tester.pumpAndSettle();
    final withCategory = await taskService.fetchTask(task.id);
    expect(withCategory!.categoryId, isNotNull);

    // Adiciona tag com espaços/caixa; identidade é normalizada (CA-12).
    await tester.enterText(find.byKey(const Key('tag-input')), ' trabalho ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('trabalho'), findsOneWidget);

    // Remove a tag (CA-13).
    await tester.tap(find.byTooltip('Remover tag'));
    await tester.pumpAndSettle();
    final withoutTag = await taskService.fetchTask(task.id);
    expect(withoutTag!.tagIds, isEmpty);
    expect(orgStore.allTags.length, 1);
  });
}

Future<void> _openMenu(WidgetTester tester, String tileTitle) async {
  final tile = find.ancestor(
    of: find.text(tileTitle),
    matching: find.byType(ListTile),
  );
  await tester.tap(
    find.descendant(of: tile, matching: find.byIcon(Icons.more_vert)),
  );
  await tester.pumpAndSettle();
}
