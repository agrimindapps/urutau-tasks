import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('recorrência exige prazo (CA-18) e gera próxima ocorrência',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      // Criar tarefa base.
      await _createTask(tester, 'Repetir todo dia');

      // CA-18 — ativar repetição sem prazo é rejeitado com aviso.
      await tester.tap(find.text('Repetir todo dia'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sem repetição'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sem repetição'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Diária'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diária'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Defina um prazo antes de ativar a repetição.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget); // diálogo aberto

      // Definir prazo (hoje) e repetição diária.
      await tester.ensureVisible(find.text('Sem prazo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sem prazo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Concluir gera a próxima ocorrência (RF-11): o histórico vai para
      // Concluídas e uma nova ocorrência ativa ocupa o lugar em Todas.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('Repetir todo dia'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Concluídas'));
      await tester.pumpAndSettle();
      expect(find.text('Repetir todo dia'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await tester.pumpAndSettle();
      // Próxima ocorrência ativa (manhã) já está em Todas.
      expect(find.text('Repetir todo dia'), findsOneWidget);
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
