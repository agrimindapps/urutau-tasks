import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('My Day: adicionar, concluir e remover (CA-09/12/13)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      // Criar tarefa na aba Tarefas.
      await _createTask(tester, 'Foco do dia');

      // CA-09 — adicionar ao My Day pelo menu do tile.
      await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar ao My Day'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Day'));
      await tester.pumpAndSettle();
      expect(find.text('Foco do dia'), findsOneWidget);

      // CA-12 — remover do My Day mantém a tarefa em Todas.
      await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover do My Day'));
      await tester.pumpAndSettle();
      expect(
        find.text('My Day vazio. Adicione tarefas ao foco do dia!'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tarefas'));
      await tester.pumpAndSettle();
      expect(find.text('Foco do dia'), findsOneWidget);
    });
  });

  testWidgets('My Day: concluir no foco vai para Concluídas (CA-13)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Concluir no foco');
      await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar ao My Day'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Day'));
      await tester.pumpAndSettle();
      expect(find.text('Concluir no foco'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(
        find.text('My Day vazio. Adicione tarefas ao foco do dia!'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tarefas'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Concluídas'));
      await tester.pumpAndSettle();
      expect(find.text('Concluir no foco'), findsOneWidget);
    });
  });
}

Future<void> _createTask(WidgetTester tester, String title) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'O que precisa ser feito?'),
    title,
  );
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();
}
