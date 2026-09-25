import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';
import 'package:urutau_tasks/src/data/providers.dart';
import 'package:urutau_tasks/src/features/notifications/presentation/permission_flow.dart';

import '../../../support/fake_notification_adapter.dart';
import '../../../support/pump_app.dart';

void main() {
  testWidgets('CA-01/CA-02 — permissão pedida uma única vez no primeiro '
      'lembrete', (tester) async {
    final store = InMemoryReminderPermissionStore();
    final adapter = FakeNotificationAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderPermissionStoreProvider.overrideWithValue(store),
          notificationAdapterProvider.overrideWithValue(adapter),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _FlowHarness(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // CA-01: explica antes de agendar.
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Permitir avisos'), findsOneWidget);
    expect(find.textContaining('autorização do sistema'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(store.explained, isTrue);
    expect(adapter.requestPermissionCalls, 1);

    // CA-02: nenhuma nova solicitação automática depois da primeira.
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Permitir avisos'), findsNothing);
    expect(adapter.requestPermissionCalls, 1);
  });

  testWidgets('CA-05 — lembrete vencido em primeiro plano mostra aviso '
      'no app com ação para abrir', (tester) async {
    await urutauWidgetTest(tester, () async {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final service = container.read(tasksServiceProvider);

      // A criação completa durante os pumps (Drift assíncrono no relógio
      // de teste) e o temporizador do lembrete dispara ao avançar o tempo.
      final creation = service.createTask(
        title: 'Beber água',
        // Folga generosa: a elegibilidade é avaliada no relógio real e a
        // criação consome alguns milissegundos (a stores também truncam
        // para segundo).
        reminder: DateTime.now().add(const Duration(seconds: 3)),
      );
      var created = false;
      unawaited(creation.then((_) => created = true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pumpAndSettle();
      expect(created, isTrue);
      expect(find.text('Beber água'), findsWidgets);
      expect(find.text('Abrir tarefa'), findsOneWidget);

      // Deixa o SnackBar expirar antes do desmonte.
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();

    });
  });

  testWidgets('CA-06 — toque na notificação do sistema abre o detalhe',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final service = container.read(tasksServiceProvider);
      String? taskId;
      unawaited(
        service.createTask(title: 'Tarefa notificada').then((id) {
          taskId = id;
        }),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(taskId, isNotNull);

      lastFakeNotificationAdapter!.triggerOpened(taskId!);
      await tester.pumpAndSettle();

      expect(find.text('Detalhes da tarefa'), findsOneWidget);
      expect(find.text('Tarefa notificada'), findsOneWidget);
    });
  });
}

class _FlowHarness extends ConsumerWidget {
  const _FlowHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => runFirstReminderPermissionFlow(context, ref),
          child: const Text('go'),
        ),
      ),
    );
  }
}
