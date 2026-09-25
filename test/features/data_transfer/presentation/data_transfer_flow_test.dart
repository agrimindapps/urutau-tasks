import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/pump_app.dart';

void main() {
  testWidgets('página de backup: avisos, ações e validação de senha',
      (tester) async {
    final taskStore = InMemoryTaskRepository();
    await pumpApp(
      tester,
      repository: taskStore,
      organization: InMemoryOrganizationRepository(taskStore),
      myDay: InMemoryMyDayRepository(),
    );

    await tapNav(tester, icon: Icons.list_alt_outlined);
    await tester.tap(find.byTooltip('Backup e dados'));
    await tester.pumpAndSettle();

    // Avisos e ações da spec 07 (RF-05/RF-06/RF-09).
    expect(find.text('A senha não é armazenada. Sem ela, o backup é inacessível.'),
        findsOneWidget);
    expect(find.text('O arquivo legível contém seus dados pessoais sem proteção.'),
        findsOneWidget);
    expect(find.text('Exportar backup criptografado'), findsOneWidget);
    expect(find.text('Exportar JSON legível'), findsOneWidget);
    expect(find.text('Restaurar backup'), findsOneWidget);
    expect(find.text('Importar JSON'), findsOneWidget);

    // Diálogo de senha com confirmação (RF-06).
    await tester.tap(find.byKey(const Key('export-backup')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm-password-field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password-field')), 'abc');
    await tester.enterText(
      find.byKey(const Key('confirm-password-field')),
      'xyz',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas não conferem.'), findsOneWidget);

    // Senha vazia é rejeitada.
    await tester.enterText(find.byKey(const Key('password-field')), '');
    await tester.enterText(
      find.byKey(const Key('confirm-password-field')),
      '',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Digite uma senha.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
  });
}
