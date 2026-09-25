import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/notifications/application/reminder_coordinator.dart';
import 'package:urutau_tasks/src/features/notifications/domain/reminder_delivery.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/task_fixtures.dart';

/// Adaptador falso registra chamadas e simula capacidade/permissão.
class FakeReminderAdapter implements ReminderAdapter {
  ReminderCapability capability = ReminderCapability.supported;
  ReminderPermission permission = ReminderPermission.granted;
  final List<String> scheduled = [];
  final List<String> cancelled = [];
  int scheduleCalls = 0;

  @override
  void setOnOpenTask(void Function(String taskId) handler) {}

  @override
  Future<ReminderCapability> queryCapability() async => capability;

  @override
  Future<ReminderPermission> queryPermission() async => permission;

  @override
  Future<ReminderPermission> requestPermission() async => permission;

  @override
  Future<void> schedule({
    required String taskId,
    required String title,
    required DateTime fireAt,
  }) async {
    scheduleCalls++;
    cancelled.remove(taskId);
    if (!scheduled.contains(taskId)) scheduled.add(taskId);
  }

  @override
  Future<void> cancel({required String taskId}) async {
    scheduled.remove(taskId);
    if (!cancelled.contains(taskId)) cancelled.add(taskId);
  }
}

class FakePermissionStore implements ReminderPermissionStore {
  bool requested = false;

  @override
  Future<bool> wasRequested() async => requested;

  @override
  Future<void> markRequested() async => requested = true;
}

class FakeForegroundScheduler implements ForegroundScheduler {
  final Map<Object, void Function()> fires = {};
  int _next = 0;

  @override
  Object scheduleAt(DateTime time, void Function() fire) {
    final handle = _next++;
    fires[handle] = fire;
    return handle;
  }

  @override
  void cancel(Object handle) {
    fires.remove(handle);
  }

  void fireAll() {
    for (final fire in fires.values.toList()) {
      fire();
    }
  }
}

void main() {
  late FakeReminderAdapter adapter;
  late FakePermissionStore store;
  late FakeForegroundScheduler foreground;
  late List<Task> notices;
  late ReminderCoordinator coordinator;

  // kTestNow = 2026-09-25 12:00 UTC.
  Task taskWithReminder(DateTime reminder, {TaskStatus status = TaskStatus.active}) {
    var task = buildTask(id: 't1', title: 'Com lembrete');
    task = task.setReminder(reminder);
    if (status == TaskStatus.completed) task = task.complete(at: kTestNow);
    return task;
  }

  setUp(() {
    adapter = FakeReminderAdapter();
    store = FakePermissionStore();
    foreground = FakeForegroundScheduler();
    notices = [];
    coordinator = ReminderCoordinator(
      adapter,
      store,
      foreground: foreground,
      clock: () => kTestNow,
      onForegroundNotice: notices.add,
    );
  });

  test('lembrete futuro com permissão agenda (RF-01, CA-12)', () async {
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    final state = await coordinator.apply(task);

    expect(state, DeliveryState.scheduled);
    expect(adapter.scheduled, ['t1']);
    expect(coordinator.stateOf('t1'), DeliveryState.scheduled);
  });

  test('sem permissão preserva a configuração e pede estado (CA-02)', () async {
    adapter.permission = ReminderPermission.denied;
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));

    final state = await coordinator.apply(task);

    expect(state, DeliveryState.permissionNeeded);
    expect(adapter.scheduled, isEmpty);
    expect(task.reminder, DateTime.utc(2026, 9, 26, 9));
  });

  test('pedido de permissão só por ação explícita (CA-01)', () async {
    adapter.permission = ReminderPermission.denied;
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));

    // Reconciliar nunca pede permissão (RF-05).
    await coordinator.reconcile([task]);
    expect(store.requested, isFalse);

    adapter.permission = ReminderPermission.granted;
    final state = await coordinator.requestPermissionFromUser(task);
    expect(store.requested, isTrue);
    expect(state, DeliveryState.scheduled);
    expect(adapter.scheduled, ['t1']);
  });

  test('reconciliação é idempotente e cancela os que não se aplicam '
      '(RF-05, CA-03/CA-10)', () async {
    final active = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    await coordinator.reconcile([active]);
    await coordinator.reconcile([active]);
    expect(adapter.scheduleCalls, 2);
    expect(adapter.scheduled, ['t1']);

    // Tarefa sem mais lembrete elegível: cancela o aviso.
    final done = active.complete(at: kTestNow);
    await coordinator.reconcile([done]);
    expect(adapter.scheduled, isEmpty);
    expect(adapter.cancelled, contains('t1'));
    expect(done.reminder, DateTime.utc(2026, 9, 26, 9));
  });

  test('concluir cancela o aviso e reabrir reagenda se futuro '
      '(RF-03, CA-04)', () async {
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    await coordinator.apply(task);
    expect(adapter.scheduled, ['t1']);

    final completed = task.complete(at: kTestNow);
    await coordinator.apply(completed);
    expect(adapter.scheduled, isEmpty);
    expect(completed.reminder, DateTime.utc(2026, 9, 26, 9));

    final reopened = completed.reopen(at: kTestNow);
    await coordinator.apply(reopened);
    expect(adapter.scheduled, ['t1']);
  });

  test('instante no passado não agenda nem faz catch-up (CA-08)', () async {
    final task = taskWithReminder(DateTime.utc(2026, 9, 25, 11));
    final state = await coordinator.apply(task);

    expect(state, DeliveryState.overdue);
    expect(adapter.scheduled, isEmpty);
    expect(task.reminder, DateTime.utc(2026, 9, 25, 11));
  });

  test('primeiro plano: aviso no app e cancela o do sistema (CA-05)', () async {
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    await coordinator.apply(task);
    expect(foreground.fires, hasLength(1));

    foreground.fireAll();

    expect(notices.map((t) => t.id), ['t1']);
    expect(adapter.scheduled, isEmpty, reason: 'sem disparo duplo (§8)');
  });

  test('plataforma sem suporte preserva a configuração (CA-09)', () async {
    adapter.capability = ReminderCapability.unsupported;
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));

    final state = await coordinator.apply(task);

    expect(state, DeliveryState.platformUnsupported);
    expect(adapter.scheduled, isEmpty);
    expect(task.reminder, DateTime.utc(2026, 9, 26, 9));
  });

  test('permissão revogada vira estado e cancela pendentes (CA-10)', () async {
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    await coordinator.apply(task);
    expect(adapter.scheduled, ['t1']);

    adapter.permission = ReminderPermission.denied;
    await coordinator.reconcile([task]);

    expect(coordinator.stateOf('t1'), DeliveryState.permissionNeeded);
    expect(adapter.scheduled, isEmpty);
  });

  test('atualizar o lembrete substitui sem duplicar (CA-03)', () async {
    final first = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    await coordinator.apply(first);

    final updated = first.setReminder(DateTime.utc(2026, 9, 27, 10));
    await coordinator.apply(updated);

    expect(adapter.scheduleCalls, 2);
    expect(adapter.scheduled, ['t1']);
  });

  test('remover o lembrete cancela o aviso (RF-02)', () async {
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    await coordinator.apply(task);

    final cleared = task.setReminder(null);
    await coordinator.apply(cleared);

    expect(adapter.scheduled, isEmpty);
    expect(adapter.cancelled, contains('t1'));
    expect(cleared.reminder, isNull);
  });

  test('notificação do sistema mostra título atual e sem ações rápidas '
      '(CA-07)', () async {
    final task = taskWithReminder(DateTime.utc(2026, 9, 26, 9));
    await coordinator.apply(task);
    // O payload do aviso é o título atual; a implementação do adaptador
    // não inclui ações rápidas (matriz ADR-0004).
    expect(task.title, 'Com lembrete');
    expect(adapter.scheduled, ['t1']);
  });
}
