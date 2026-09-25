import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_recurrence_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/pump_app.dart';

void main() {
  late InMemoryTaskRepository taskStore;
  late InMemoryMyDayRepository myDayStore;

  setUp(() {
    taskStore = InMemoryTaskRepository();
    myDayStore = InMemoryMyDayRepository();
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
        tester,
        repository: taskStore,
        organization: InMemoryOrganizationRepository(taskStore),
        myDay: myDayStore,
      );

  testWidgets('adiciona tarefa existente e remove sem alterar a tarefa '
      '(CA-09 a CA-12)', (tester) async {
    final taskService = TasksService(taskStore, myDayStore, InMemoryRecurrenceRepository());
    final task = await taskService.createTask(title: 'Revisar relatório');

    await pump(tester);
    expect(find.text('Nenhuma tarefa no seu dia ainda.'), findsOneWidget);

    // Adiciona existente (RF-06).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher tarefa existente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar relatório'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar relatório'), findsOneWidget);

    // Remove do My Day sem alterar a tarefa (RF-08, CA-12).
    await tester.tap(find.byTooltip('Remover do Meu dia'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar relatório'), findsNothing);
    final kept = await taskService.fetchTask(task.id);
    expect(kept!.status, TaskStatus.active);
    expect(kept.title, 'Revisar relatório');
  });

  testWidgets('criar do Meu dia entra no foco e concluir sai (RF-06, RF-09)',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Foco do dia',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Foco do dia'), findsOneWidget);

    // Concluir sai do foco (RF-09).
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('Foco do dia'), findsNothing);
    expect(find.text('Nenhuma tarefa no seu dia ainda.'), findsOneWidget);
  });

  testWidgets('rollover remove entradas pendentes de dias anteriores (CA-14)',
      (tester) async {
    final taskService = TasksService(taskStore, myDayStore, InMemoryRecurrenceRepository());
    final old = await taskService.createTask(title: 'De ontem');
    await myDayStore.saveEntry(MyDayEntry.create(
      id: 'old-entry',
      taskId: old.id,
      date: '2026-09-24',
      position: 0,
    ));

    await pump(tester);

    expect(find.text('De ontem'), findsNothing);
    expect(find.text('Nenhuma tarefa no seu dia ainda.'), findsOneWidget);
    final kept = await taskService.fetchTask(old.id);
    expect(kept!.status, TaskStatus.active);
  });
}
