import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:urutau_tasks/main.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/data/providers.dart';

import 'fake_notification_adapter.dart';
import 'test_database.dart';

/// Adaptador falso do teste em execução (spec 08).
FakeNotificationAdapter? lastFakeNotificationAdapter;

/// Banco em memória do teste em execução — permitido reutilizá-lo ao
/// simular reinícios da árvore sem cair no banco real.
AppDatabase? currentTestDatabase;

/// Executa um teste de widget com o app completo, banco isolado em memória
/// (spec 06, RF-26) e locale `pt-BR`, desmontando a árvore e drenando os
/// timers internos do Drift ao final do corpo do teste.
Future<AppDatabase> urutauWidgetTest(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final dispatcher = tester.binding.platformDispatcher;
  dispatcher.localeTestValue = const Locale('pt', 'BR');
  dispatcher.localesTestValue = const [Locale('pt', 'BR')];
  addTearDown(dispatcher.clearLocaleTestValue);
  addTearDown(dispatcher.clearLocalesTestValue);

  // Preferência de idioma isolada por teste (spec 09, RF-03).
  SharedPreferences.setMockInitialValues({});

  final database = createMemoryDatabase();
  currentTestDatabase = database;
  final fakeAdapter = FakeNotificationAdapter();
  lastFakeNotificationAdapter = fakeAdapter;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        notificationAdapterProvider.overrideWithValue(fakeAdapter),
      ],
      child: const UrutauApp(),
    ),
  );
  await tester.pumpAndSettle();

  // A shell abre no My Day (foco do dia); os testes de fluxo partem da
  // aba Tarefas.
  final tasksTab = find.text('Tarefas');
  if (tasksTab.evaluate().isNotEmpty) {
    await tester.tap(tasksTab.first);
    await tester.pumpAndSettle();
  }

  try {
    await body();
  } finally {
    // Desmonta provedores e drena os timers do Drift antes da verificação
    // de invariantes do framework (ver aviso em StreamQueryStore).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
    currentTestDatabase = null;
  }
  return database;
}
