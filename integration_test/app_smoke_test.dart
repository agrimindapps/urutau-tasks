import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:urutau_tasks/src/app/app.dart';

/// Smoke Web automatizado (spec 10, RF-01 a RF-04).
///
/// Exercita inicialização, navegação, ciclo básico da tarefa,
/// layout/interação e persistência local sem conta ou rede.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('inicialização, navegação e ciclo básico da tarefa',
      (tester) async {
    await _pumpApp(tester);

    // RF-01: inicialização e navegação entre as áreas.
    expect(find.text('Nenhuma tarefa no seu dia ainda.'), findsOneWidget);
    await _tapNav(tester, Icons.checklist_outlined);
    expect(find.text('Nada por aqui ainda.'), findsOneWidget);
    await _tapNav(tester, Icons.delete_outline);
    expect(find.text('A lixeira está vazia.'), findsOneWidget);
    await _tapNav(tester, Icons.checklist_outlined);

    // RF-02: ciclo básico — criar, editar, concluir e reabrir.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Tarefa do smoke',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa do smoke'), findsOneWidget);

    await tester.tap(find.text('Tarefa do smoke'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Tarefa editada',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa editada'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Concluir na visão "Todas" e reabrir na visão "Concluídas".
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('Tarefa editada'), findsNothing);
    await tester.tap(find.text('Concluídas'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa editada'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa editada'), findsOneWidget);

    // RF-04: layout e interação utilizáveis (etapas + progresso).
    await tester.tap(find.text('Tarefa editada'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('subtask-field')),
      'Etapa do smoke',
    );
    await tester.ensureVisible(find.byTooltip('Adicionar etapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa do smoke'), findsOneWidget);
    expect(find.text('0 de 1'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  });

  testWidgets('persistência local após reinício sem conta ou rede (RF-03)',
      (tester) async {
    await _pumpApp(tester);

    await _tapNav(tester, Icons.checklist_outlined);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Persistente',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Persistente'), findsOneWidget);

    // Reinício da aplicação: novo ciclo de vida de providers e banco.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpApp(tester);

    await _tapNav(tester, Icons.checklist_outlined);
    expect(find.text('Persistente'), findsOneWidget);
    expect(find.text('Tarefa editada'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  // Sem overrides: persistência real via Drift (spec 10, RF-03).
  await tester.pumpWidget(const ProviderScope(child: UrutauApp()));
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> _tapNav(WidgetTester tester, IconData icon) async {
  final rail = find.descendant(
    of: find.byType(NavigationRail),
    matching: find.byIcon(icon),
  );
  if (rail.evaluate().isNotEmpty) {
    await tester.tap(rail);
  } else {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(icon),
      ),
    );
  }
  await tester.pumpAndSettle();
}
