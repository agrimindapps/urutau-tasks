import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/in_memory_task_repository.dart';
import '../../../support/pump_app.dart';

void main() {
  late InMemoryTaskRepository repository;

  setUp(() {
    repository = InMemoryTaskRepository();
  });

  testWidgets('inicia, cria, edita, conclui e reabre tarefa (CA-01 a CA-08)',
      (tester) async {
    await pumpApp(tester, repository: repository);

    expect(find.text('Nenhuma tarefa ainda. Crie a primeira!'), findsOneWidget);

    // Criação (CA-01/CA-02).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title-field')), '  Comprar café  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Comprar café'), findsOneWidget);

    // Título vazio é rejeitado (CA-02).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(
      find.text('O título não pode ficar vazio.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    // Edição (RF-03).
    await tester.tap(find.text('Comprar café'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title-field')), 'Comprar pão');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Comprar pão'), findsOneWidget);

    // Conclusão e reabertura (CA-07/CA-08).
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
    expect(checkbox.value, isTrue);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    final reopened = tester.widget<Checkbox>(find.byType(Checkbox).first);
    expect(reopened.value, isFalse);
  });

  testWidgets('subtarefas: progresso, ordem e remoção (CA-03 a CA-06)',
      (tester) async {
    await pumpApp(tester, repository: repository);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title-field')), 'Relatório');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Relatório'));
    await tester.pumpAndSettle();

    for (final name in ['Etapa um', 'Etapa dois']) {
      await tester.enterText(find.byKey(const Key('subtask-field')), name);
      await tester.tap(find.byTooltip('Adicionar etapa'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Etapa um'), findsOneWidget);
    expect(find.text('Etapa dois'), findsOneWidget);
    expect(find.text('0 de 2'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(find.text('1 de 2'), findsOneWidget);

    // Renomeia etapa (RF-05).
    await tester.tap(find.text('Etapa um'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('subtask-title-field')),
      'Etapa renomeada',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa renomeada'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover etapa').first);
    await tester.pumpAndSettle();
    expect(find.text('Etapa renomeada'), findsNothing);
    expect(find.text('0 de 1'), findsOneWidget);
  });

  testWidgets('lixeira preserva hierarquia e restaura (CA-09/CA-10)',
      (tester) async {
    await pumpApp(tester, repository: repository);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title-field')), 'Excluir depois');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir depois'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('subtask-field')), 'Etapa preservada');
    await tester.tap(find.byTooltip('Adicionar etapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    await tapNav(tester, icon: Icons.delete_outline);
    expect(find.text('Excluir depois'), findsOneWidget);

    await tester.tap(find.byTooltip('Restaurar'));
    await tester.pumpAndSettle();
    expect(find.text('A lixeira está vazia.'), findsOneWidget);

    await tapNav(tester, icon: Icons.checklist_outlined);
    await tester.tap(find.text('Excluir depois'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa preservada'), findsOneWidget);
    expect(find.text('0 de 1'), findsOneWidget);
  });

  testWidgets('persiste após reinício da árvore sem conta ou rede (RF-03)',
      (tester) async {
    await pumpApp(tester, repository: repository);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title-field')), 'Persistente');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await restartApp(tester, repository: repository);
    expect(find.text('Persistente'), findsOneWidget);
  });

  testWidgets('tarefa na lixeira não é editável (RF-01)', (tester) async {
    await pumpApp(tester, repository: repository);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title-field')), 'Protegida');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Protegida'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    await tapNav(tester, icon: Icons.delete_outline);
    await tester.tap(find.text('Protegida'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Editar tarefa'), findsNothing);
    expect(find.byTooltip('Restaurar'), findsOneWidget);
    expect(find.text('0 de 1'), findsNothing);
  });
}
