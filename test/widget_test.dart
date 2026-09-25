import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_organization_repository.dart';
import 'support/in_memory_task_repository.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('aplicativo inicializa e navega entre áreas (spec 10, RF-01)',
      (tester) async {
    final repository = InMemoryTaskRepository();
    await pumpApp(
      tester,
      repository: repository,
      organization: InMemoryOrganizationRepository(repository),
    );

    expect(find.text('Meu dia'), findsWidgets);
    expect(find.text('Nenhuma tarefa no seu dia ainda.'), findsOneWidget);

    await tapNav(tester, icon: Icons.checklist_outlined);
    expect(find.text('Nada por aqui ainda.'), findsOneWidget);

    await tapNav(tester, icon: Icons.list_alt_outlined);
    expect(find.text('Nenhuma lista criada.'), findsOneWidget);

    await tapNav(tester, icon: Icons.delete_outline);
    expect(find.text('A lixeira está vazia.'), findsOneWidget);
  });
}
