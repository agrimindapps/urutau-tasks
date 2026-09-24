import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('smoke: iniciar e exibir estado vazio', (tester) async {
    await urutauWidgetTest(tester, () async {
      expect(find.text('Tarefas'), findsWidgets);
      expect(
        find.text('Nenhuma tarefa por aqui. Crie a primeira!'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  testWidgets('criar tarefa com título válido (CA-01, RF-02)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'O que precisa ser feito?'),
        'Comprar café',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Comprar café'), findsOneWidget);
      expect(
        find.text('Nenhuma tarefa por aqui. Crie a primeira!'),
        findsNothing,
      );
    });
  });

  testWidgets('rejeitar título vazio (CA-02)', (tester) async {
    await urutauWidgetTest(tester, () async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe um título.'), findsOneWidget);
      expect(
        find.text('Nenhuma tarefa por aqui. Crie a primeira!'),
        findsOneWidget,
      );
    });
  });

  testWidgets('concluir e reabrir tarefa (RF-04, visões)', (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Estudar Drift');

      // Concluir remove de Todas (spec 03, RF-01) e aparece em Concluídas.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('Estudar Drift'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Concluídas'));
      await tester.pumpAndSettle();
      expect(find.text('Estudar Drift'), findsOneWidget);

      // Reabrir remove de Concluídas e volta para Todas.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('Estudar Drift'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await tester.pumpAndSettle();
      expect(find.text('Estudar Drift'), findsOneWidget);
    });
  });

  testWidgets('subtarefas e progresso no detalhe (RF-05/RF-08)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Planejar viagem');

      await tester.tap(find.text('Planejar viagem'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes da tarefa'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nova etapa'),
        'Reservar hotel',
      );
      await tester.tap(find.byTooltip('Adicionar subtarefa'));
      await tester.pumpAndSettle();

      expect(find.text('Reservar hotel'), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);
    });
  });

  testWidgets('mover para a lixeira e restaurar (RF-09/RF-10)',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Tarefa descartável');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover para a lixeira'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma tarefa por aqui. Crie a primeira!'),
        findsOneWidget,
      );

      await tester.tap(find.text('Lixeira'));
      await tester.pumpAndSettle();
      expect(find.text('Tarefa descartável'), findsOneWidget);

      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();
      expect(find.text('A lixeira está vazia.'), findsOneWidget);

      await tester.tap(find.text('Tarefas'));
      await tester.pumpAndSettle();
      expect(find.text('Tarefa descartável'), findsOneWidget);
    });
  });

  testWidgets('editar título pela lista (RF-03)', (tester) async {
    await urutauWidgetTest(tester, () async {
      await _createTask(tester, 'Nome antigo');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Título'),
        'Nome novo',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Nome novo'), findsOneWidget);
      expect(find.text('Nome antigo'), findsNothing);
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
