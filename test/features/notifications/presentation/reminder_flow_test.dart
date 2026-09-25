import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/notifications/application/reminder_coordinator.dart';
import 'package:urutau_tasks/src/features/notifications/domain/reminder_delivery.dart';
import 'package:urutau_tasks/src/features/notifications/platform/reminder_permission_store.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_recurrence_repository.dart';
import '../../../support/in_memory_task_repository.dart';
import '../../../support/pump_app.dart';
import '../../../support/task_fixtures.dart';

/// Adaptador falso para o teste de UI.
class _UiFakeAdapter implements ReminderAdapter {
  ReminderPermission permission = ReminderPermission.denied;
  void Function(String taskId)? onOpenTask;

  @override
  void setOnOpenTask(void Function(String taskId) handler) {
    onOpenTask = handler;
  }

  @override
  Future<ReminderCapability> queryCapability() async =>
      ReminderCapability.supported;

  @override
  Future<ReminderPermission> queryPermission() async => permission;

  @override
  Future<ReminderPermission> requestPermission() async {
    permission = ReminderPermission.granted;
    return permission;
  }

  @override
  Future<void> schedule({
    required String taskId,
    required String title,
    required DateTime fireAt,
  }) async {}

  @override
  Future<void> cancel({required String taskId}) async {}
}

class _NoopForegroundScheduler implements ForegroundScheduler {
  @override
  Object scheduleAt(DateTime time, void Function() fire) => Object();

  @override
  void cancel(Object handle) {}
}

void main() {
  testWidgets('estado de entrega e fluxo de permissão (CA-01/CA-02/CA-12)',
      (tester) async {
    final taskStore = InMemoryTaskRepository();
    final adapter = _UiFakeAdapter();
    final permissionStore = InMemoryReminderPermissionStore();
    final tasksService = TasksService(
      taskStore,
      InMemoryMyDayRepository(),
      InMemoryRecurrenceRepository(),
      clock: () => kTestNow,
    );
    final task = await tasksService.createTask(title: 'Com lembrete');
    await tasksService.setReminder(task.id, DateTime.utc(2026, 10, 1, 9));

    await pumpApp(
      tester,
      repository: taskStore,
      organization: InMemoryOrganizationRepository(taskStore),
      myDay: InMemoryMyDayRepository(),
      reminderAdapter: adapter,
      permissionStore: permissionStore,
      foregroundScheduler: _NoopForegroundScheduler(),
    );

    await tapNav(tester, icon: Icons.checklist_outlined);
    await tester.tap(find.text('Com lembrete'));
    await tester.pumpAndSettle();

    // Sem permissão: estado visível e configuração preservada (CA-02).
    await tester.ensureVisible(find.byKey(const Key('delivery-state')));
    await tester.pumpAndSettle();
    expect(find.text('Permissão necessária'), findsOneWidget);

    // Pedido de permissão com explicação (CA-01).
    await tester.tap(find.byKey(const Key('allow-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('Notificações de lembrete'), findsOneWidget);
    expect(
      find.text(
          'O Urutau Tasks usa notificações locais para avisar sobre lembretes. Nada é enviado a servidores.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Permitir notificações'));
    await tester.pumpAndSettle();

    // Concedida: estado Agendado (CA-12).
    expect(find.text('Agendado'), findsOneWidget);
    expect(adapter.permission, ReminderPermission.granted);
  });

  testWidgets('tocar no aviso navega para o detalhe da tarefa (CA-06)',
      (tester) async {
    final taskStore = InMemoryTaskRepository();
    final adapter = _UiFakeAdapter();
    final tasksService = TasksService(
      taskStore,
      InMemoryMyDayRepository(),
      InMemoryRecurrenceRepository(),
      clock: () => kTestNow,
    );
    final task = await tasksService.createTask(title: 'Abrir pelo aviso');

    await pumpApp(
      tester,
      repository: taskStore,
      organization: InMemoryOrganizationRepository(taskStore),
      myDay: InMemoryMyDayRepository(),
      reminderAdapter: adapter,
      permissionStore: InMemoryReminderPermissionStore(),
      foregroundScheduler: _NoopForegroundScheduler(),
    );

    expect(find.text('Detalhes da tarefa'), findsNothing);
    adapter.onOpenTask?.call(task.id);
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da tarefa'), findsOneWidget);
    expect(find.text('Abrir pelo aviso'), findsOneWidget);
  });
}
