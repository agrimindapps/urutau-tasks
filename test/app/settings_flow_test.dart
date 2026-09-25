import 'package:flutter/material.dart';
import 'package:urutau_tasks/src/app/locale_preference.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_my_day_repository.dart';
import '../support/in_memory_organization_repository.dart';
import '../support/in_memory_task_repository.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('substituição de idioma é aplicada imediatamente (CA-04)',
      (tester) async {
    final taskStore = InMemoryTaskRepository();
    await pumpApp(
      tester,
      repository: taskStore,
      organization: InMemoryOrganizationRepository(taskStore),
      myDay: InMemoryMyDayRepository(),
    );

    await tapNav(tester, icon: Icons.list_alt_outlined);
    expect(find.text('Listas e grupos'), findsOneWidget);

    // Abre as configurações e troca para inglês.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('locale-en')));
    await tester.pumpAndSettle();

    // Aplicação imediata, sem reinício (RF-03).
    expect(find.text('Lists and groups'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);

    // Volta para Automático e o texto segue o sistema (pt-BR nos testes).
    await tester.tap(find.byKey(const Key('locale-system')));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Listas e grupos'), findsOneWidget);
  });

  testWidgets('escolha manual é mantida entre reinícios da árvore (CA-04)',
      (tester) async {
    final taskStore = InMemoryTaskRepository();
    final localeStore = InMemoryLocalePreferenceStore();
    await pumpApp(
      tester,
      repository: taskStore,
      organization: InMemoryOrganizationRepository(taskStore),
      myDay: InMemoryMyDayRepository(),
      localeStore: localeStore,
    );

    await tapNav(tester, icon: Icons.list_alt_outlined);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('locale-es')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    await restartApp(
      tester,
      repository: taskStore,
      organization: InMemoryOrganizationRepository(taskStore),
      myDay: InMemoryMyDayRepository(),
      localeStore: localeStore,
    );
    await tapNav(tester, icon: Icons.list_alt_outlined);
    expect(find.text('Listas y grupos'), findsOneWidget);
  });
}
