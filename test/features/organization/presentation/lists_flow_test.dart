import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('criar lista e atribuir tarefa (CA-01, CA-03, CA-04)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      // CA-01 — criar lista na aba Listas.
      await tester.tap(find.text('Listas'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma lista. Crie a primeira!'), findsOneWidget);

      await tester.tap(find.byTooltip('Nova lista'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nome'),
        'Projetos',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Projetos'), findsOneWidget);

      // CA-03 — tarefa criada sem lista fica na inbox.
      await tester.tap(find.text('Tarefas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'O que precisa ser feito?'),
        'Sem lista ainda',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Filtro "Sem lista" enxerga a tarefa.
      await tester.tap(find.widgetWithText(FilterChip, 'Sem lista'));
      await tester.pumpAndSettle();
      expect(find.text('Sem lista ainda'), findsOneWidget);

      // CA-04 — atribuir à lista pela edição.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'O que precisa ser feito?'),
        'Na lista',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Na lista'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes da tarefa'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Sem lista')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projetos').last);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Projetos'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lista: Projetos'), findsOneWidget);
      // pageBack procura tooltip 'Back' fixo em inglês; usamos o botão direto.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // "Sem lista" não mostra mais; a lista sim.
      await tester.tap(find.widgetWithText(FilterChip, 'Sem lista'));
      await tester.pumpAndSettle();
      expect(find.text('Na lista'), findsNothing);
      expect(find.text('Sem lista ainda'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Projetos'));
      await tester.pumpAndSettle();
      expect(find.text('Na lista'), findsOneWidget);
      expect(find.text('Sem lista ainda'), findsNothing);
    });
  });

  testWidgets('rejeitar nome de lista duplicado (CA-02)', (tester) async {
    await urutauWidgetTest(tester, () async {
      await tester.tap(find.text('Listas'));
      await tester.pumpAndSettle();

      Future<void> createList(String name) async {
        await tester.tap(find.byTooltip('Nova lista'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'Nome'), name);
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();
      }

      await createList('Casa');
      await createList('  casa ');
      expect(find.text('Já existe um nome equivalente.'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
    });
  });
}
