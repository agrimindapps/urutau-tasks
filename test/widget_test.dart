import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_task_repository.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('aplicativo inicializa e navega entre áreas (spec 10, RF-01)',
      (tester) async {
    final repository = InMemoryTaskRepository();
    await pumpApp(tester, repository: repository);

    expect(find.text('Tarefas'), findsWidgets);
    expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);
    expect(find.text('Nenhuma tarefa ainda. Crie a primeira!'), findsOneWidget);

    await tapNav(tester, icon: Icons.delete_outline);
    expect(find.text('A lixeira está vazia.'), findsOneWidget);

    await tapNav(tester, icon: Icons.checklist_outlined);
    expect(find.text('Nenhuma tarefa ainda. Crie a primeira!'), findsOneWidget);
  });
}
