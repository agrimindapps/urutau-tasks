import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_recurrence_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/pump_app.dart';

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
        myDay: InMemoryMyDayRepository(),
      );

  testWidgets('busca com debounce e indicação de correspondência '
      '(CA-01/CA-04/CA-07/CA-17)', (tester) async {
    final tasksService = TasksService(
      taskStore,
      InMemoryMyDayRepository(),
      InMemoryRecurrenceRepository(),
    );
    final task = await tasksService.createTask(title: 'Reunião de equipe');
    await tasksService.renameTask(task.id,
        title: 'Reunião de equipe', notes: 'pauta do café');
    await tasksService.createTask(title: 'Compras');

    await pump(tester);
    await tapNav(tester, icon: Icons.search);

    // Debounce: resultados só mudam após o intervalo (CA-07).
    await tester.enterText(find.byKey(const Key('search-field')), 'reuniao');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Reunião de equipe'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Reunião de equipe'), findsOneWidget);
    expect(find.text('Compras'), findsNothing);
    // Correspondência por título (CA-17).
    expect(find.text('no título'), findsOneWidget);

    // Busca em notas com acentuação diferente.
    await tester.enterText(find.byKey(const Key('search-field')), 'cafe');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Reunião de equipe'), findsOneWidget);
    expect(find.text('nas notas'), findsOneWidget);
  });

  testWidgets('filtros combinam com a busca (CA-06/CA-12)', (tester) async {
    final tasksService = TasksService(
      taskStore,
      InMemoryMyDayRepository(),
      InMemoryRecurrenceRepository(),
    );
    await tasksService.createTask(title: 'Café da manhã');
    final work = await tasksService.createTask(title: 'Café do trabalho');

    await pump(tester);
    await tapNav(tester, icon: Icons.search);

    // Busca vazia com filtro de status (CA-06).
    await tester.tap(find.byKey(const Key('filters-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Concluídas'));
    await tester.tap(find.text('Concluídas'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum resultado.'), findsOneWidget);

    // Limpa filtros e filtra por prioridade.
    await tester.tap(find.byKey(const Key('filters-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Limpar filtros'));
    await tester.pumpAndSettle();

    await tasksService.setPriority(work.id, TaskPriority.urgent);
    await tester.tap(find.byKey(const Key('filters-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Urgente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgente'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Café do trabalho'), findsOneWidget);
    expect(find.text('Café da manhã'), findsNothing);
  });
}
