import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:urutau_tasks/main.dart';
import 'package:urutau_tasks/src/data/providers.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets(
      'configurações de idioma: manual imediato, persistente e reversível '
      '(CA-04, CA-05)', (tester) async {
    await urutauWidgetTest(tester, () async {
      // Criar uma tarefa no idioma automático (pt-BR do sistema de teste).
      await _createTask(tester, 'Comprar pão');

      // Abrir configurações pela aba Listas.
      await tester.tap(find.text('Listas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configurações'));
      await tester.pumpAndSettle();
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Automático (sistema)'), findsOneWidget);

      // CA-04 — trocar para English aplica imediatamente.
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget); // diálogo reconstruído
      expect(find.text('Lists'), findsWidgets); // navegação em inglês
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Lists'), findsWidgets);

      // CA-05 — os dados do usuário permanecem ao trocar o idioma.
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Comprar pão'), findsOneWidget);

      // CA-04 — persistência após reinício da árvore.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(currentTestDatabase!),
          ],
          child: const UrutauApp(),
        ),
      );
      await tester.pumpAndSettle();
      // Preferência relida do armazenamento: UI continua em inglês
      // (a persistência da tarefa é coberta pelo smoke de reinício).
      expect(find.text('Tasks'), findsWidgets);

      // Voltar para o modo automático.
      await tester.tap(find.text('Lists'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automatic (system)'));
      await tester.pumpAndSettle();
      // Ao voltar para o sistema o rótulo já está em pt-BR.
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(find.text('Listas'), findsWidgets);
      await tester.tap(find.text('Tarefas'));
      await tester.pumpAndSettle();
      expect(find.text('Comprar pão'), findsOneWidget);
    });
  });

  testWidgets('preferência de idioma fica fora do export (CA-09)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await tester.tap(find.text('Listas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configurações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('urutau_ui_language'), 'en');

      // O arquivo exportado é um contrato fechado: a preferência nunca
      // entra nele (spec 09, RF-02/CA-09).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final json = await container
          .read(dataTransferServiceProvider)
          .exportJson();
      expect(json, isNot(contains('urutau_ui_language')));
      expect(json, isNot(contains('ui_language')));
    });
  });
}

Future<void> _createTask(WidgetTester tester, String title) async {
  // A shell abre no My Day; os testes partem da aba Tarefas.
  await tester.tap(find.text('Tarefas'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'O que precisa ser feito?'),
    title,
  );
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();
}
