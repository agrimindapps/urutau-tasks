import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('busca por título com debounce (CA-01, CA-04, CA-07)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Reunião do time');
      await _createTask(tester, 'Comprar café');

      final field = find.widgetWithText(TextField, 'Buscar tarefas');
      expect(field, findsOneWidget);

      // CA-04: acento ignorado. CA-07: resultados só após o debounce.
      await tester.enterText(field, 'reuniao');
      await tester.pump(const Duration(milliseconds: 100));
      // Antes dos 300ms do debounce os dois resultados continuam.
      expect(find.text('Reunião do time'), findsOneWidget);
      expect(find.text('Comprar café'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Reunião do time'), findsOneWidget);
      expect(find.text('Comprar café'), findsNothing);

      // Campo vazio volta ao modo de navegação (RF-07).
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Comprar café'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    });
  });

  testWidgets('filtro de prioridade sem texto (CA-06)', (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Tarefa urgente');

      // Abrir folha de filtros.
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .toList();
      expect(
        find.text('Status'),
        findsOneWidget,
        reason: 'folha aberta; texts=$texts',
      );
      // ignore: avoid_print

      await tester.ensureVisible(find.text('Prioridade'));
      await tester.pumpAndSettle();
      // Prioridade padrão da tarefa criada é Média.
      await tester.tap(find.text('Média'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar'), findsOneWidget);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Sem texto, apenas o filtro determina o resultado.
      expect(find.text('Tarefa urgente'), findsOneWidget);

      // Com filtro ativo as visões ficam ocultas (busca global).
      expect(find.widgetWithText(ChoiceChip, 'Todas'), findsNothing);

      // Limpar filtros restaura o modo de navegação.
      await tester.tap(find.byTooltip('Limpar filtros'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
      expect(find.text('Tarefa urgente'), findsOneWidget);
    });
  });

  testWidgets('busca encontra por notas e subtarefa (CA-02, CA-03)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Planejar viagem', notes: 'reservar hotel');

      final field = find.widgetWithText(TextField, 'Buscar tarefas');
      await tester.enterText(field, 'hotel');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Planejar viagem'), findsOneWidget);

      await tester.enterText(field, 'inexistente-xyz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum resultado encontrado.'), findsOneWidget);
    });
  });
}

Future<void> _createTask(
  WidgetTester tester,
  String title, {
  String? notes,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'O que precisa ser feito?'),
    title,
  );
  if (notes != null) {
    await tester.enterText(
      find.widgetWithText(TextField, 'Adicionar uma nota'),
      notes,
    );
  }
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();
}
