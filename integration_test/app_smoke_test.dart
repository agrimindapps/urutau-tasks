import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:urutau_tasks/main.dart';

/// Smoke test automatizado no Chrome Stable (spec 10, RF-01 a RF-04).
///
/// Cobre inicialização, navegação, ciclo básico da tarefa (criar, editar,
/// concluir, reabrir) e persistência local após reinício da árvore de
/// widgets, sem conta ou conexão.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke Web: navegação, ciclo da tarefa e persistência',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('pt', 'BR');
    tester.binding.platformDispatcher.localesTestValue = const [
      Locale('pt', 'BR'),
    ];

    await tester.pumpWidget(const ProviderScope(child: UrutauApp()));
    await settle(tester);

    // RF-01 — inicialização e navegação entre áreas.
    expect(find.text('Tarefas'), findsWidgets);
    expect(find.text('My Day'), findsWidgets);
    await tester.tap(find.text('Lixeira'));
    await settle(tester);
    final visibleTexts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .toList();
    final spinners = find.byType(CircularProgressIndicator).evaluate().length;
    expect(
      find.text('A lixeira está vazia.'),
      findsOneWidget,
      reason: 'texts=$visibleTexts spinners=$spinners',
    );
    await tester.tap(find.text('Tarefas'));
    await settle(tester);

    // RF-02 — criar tarefa.
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'O que precisa ser feito?'),
      'Smoke test',
    );
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Smoke test'), findsOneWidget);

    // RF-02 — editar título (menu da tarefa; o ícone é adaptativo:
    // more_horiz no macOS, more_vert em outros alvos).
    final menuButton = find.byWidgetPredicate(
      (w) => w is PopupMenuButton,
      description: 'PopupMenuButton',
    );
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await settle(tester);
    await tester.tap(find.text('Editar'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Título'),
      'Smoke test editado',
    );
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Smoke test editado'), findsOneWidget);

    // RF-02 / spec 03 — concluir sai de Todas e aparece em Concluídas.
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
    expect(find.text('Smoke test editado'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Concluídas'));
    await settle(tester);
    expect(find.text('Smoke test editado'), findsOneWidget);

    // RF-02 — reabrir sai de Concluídas e volta para Todas.
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
    expect(find.text('Smoke test editado'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
    await settle(tester);
    expect(find.text('Smoke test editado'), findsOneWidget);

    // RF-03 — persistência: reinicia a árvore (novo ProviderScope e nova
    // abertura do banco) e confirma que a tarefa continua disponível.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    await tester.pumpWidget(const ProviderScope(child: UrutauApp()));
    await settle(tester);

    // A shell reabre no My Day; a tarefa vive em Todas.
    await tester.tap(find.text('Tarefas'));
    await settle(tester);

    expect(find.text('Smoke test editado'), findsOneWidget);

    // RF-04 — layout permanece utilizável após o reinício.
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Tarefas'), findsWidgets);
  });
}

/// Espera operações assíncronas reais (Drift/Web) entre frames.
Future<void> settle(WidgetTester tester, {int attempts = 6}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pumpAndSettle();
  }
}
