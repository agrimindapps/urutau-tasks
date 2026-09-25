import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/app/app.dart';
import 'package:urutau_tasks/src/app/locale_preference.dart';
import 'package:urutau_tasks/src/data/providers.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day_repository.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task_repository.dart';

import 'in_memory_my_day_repository.dart';

/// Bombeia o aplicativo com repositórios isolados para testes de widget.
///
/// O tamanho da superfície é fixado em 800x600 para a navegação
/// adaptativa usar `NavigationRail` de forma determinística.
Future<void> pumpApp(
  WidgetTester tester, {
  required TaskRepository repository,
  OrganizationRepository? organization,
  MyDayRepository? myDay,
  LocalePreferenceStore? localeStore,
}) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // Idioma de teste em pt-BR (spec 09): asserções em português.
  tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        if (organization != null)
          organizationRepositoryProvider.overrideWithValue(organization),
        myDayRepositoryProvider.overrideWithValue(
          myDay ?? InMemoryMyDayRepository(),
        ),
        localePreferenceStoreProvider.overrideWithValue(
          localeStore ?? InMemoryLocalePreferenceStore(),
        ),
      ],
      child: const UrutauApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Toca um destino da navegação adaptativa, evitando colisão de textos
/// com os títulos de AppBar.
Future<void> tapNav(WidgetTester tester, {required IconData icon}) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byIcon(icon),
    ),
  );
  await tester.pumpAndSettle();
}

/// Bombeia novamente com o mesmo repositório (simula reinício da árvore,
/// verificando persistência sem conta ou rede — spec 10, RF-03).
Future<void> restartApp(
  WidgetTester tester, {
  required TaskRepository repository,
  OrganizationRepository? organization,
  MyDayRepository? myDay,
  LocalePreferenceStore? localeStore,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await pumpApp(
    tester,
    repository: repository,
    organization: organization,
    myDay: myDay,
    localeStore: localeStore,
  );
}
