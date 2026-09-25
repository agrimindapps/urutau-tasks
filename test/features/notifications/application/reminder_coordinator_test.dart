import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/notifications/application/reminder_coordinator.dart';
import 'package:urutau_tasks/src/features/notifications/domain/reminder_delivery.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/fake_notification_adapter.dart';
import '../../../support/in_memory_task_repository.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late FakeNotificationAdapter adapter;
  late ReminderCoordinator coordinator;
  var now = DateTime(2026, 9, 24, 12);

  setUp(() {
    tasks = InMemoryTaskRepository();
    adapter = FakeNotificationAdapter();
    coordinator = ReminderCoordinator(
      adapter: adapter,
      tasks: tasks,
      now: () => now,
    );
  });

  tearDown(() => coordinator.dispose());

  Future<String> seedTask({
    DateTime? reminder,
    TaskStatus status = TaskStatus.active,
    DateTime? deletedAt,
    String title = 'Lembrete',
  }) async {
    final id = 'task-${tasks.allTasks.length}';
    final task = Task(
      id: id,
      title: title,
      createdAt: DateTime(2026, 9, 1),
      status: status,
      deletedAt: deletedAt,
      reminder: reminder,
    );
    await tasks.insertTask(task);
    return id;
  }

  group('RF-05/CA-10 — reconciliação idempotente', () {
    test('repetir não duplica agendamentos nem avisos', () async {
      adapter.supportsScheduling = true;
      final id = await seedTask(reminder: now.add(const Duration(hours: 1)));

      await coordinator.reconcile(); // foreground: cancela
      coordinator.setPhase(AppLifecycleState.paused); // agenda no sistema
      await coordinator.reconcile();
      await coordinator.reconcile(); // idempotente

      expect(adapter.scheduled, hasLength(1));
      expect(adapter.scheduled.keys.single, notificationIdFor(id));
      expect(adapter.cancelled, contains(notificationIdFor(id)));
    });

    test('CA-10 revogação: cancela avisos e preserva a configuração',
        () async {
      adapter.supportsScheduling = true;
      adapter.capability = const NotificationCapability(
        supported: true,
        permission: NotificationPermission.denied,
        canRequestPermission: false,
        supportsScheduling: true,
      );
      final id = await seedTask(reminder: now.add(const Duration(hours: 1)));
      coordinator.setPhase(AppLifecycleState.paused);
      await coordinator.reconcile();

      expect(adapter.scheduled, isEmpty);
      expect(adapter.cancelled, contains(notificationIdFor(id)));
      final task = await tasks.getTask(id);
      expect(task!.reminder, isNotNull); // configuração preservada
    });

    test('CA-08 vencido: sem agendamento e sem catch-up', () async {
      adapter.supportsScheduling = true;
      final id =
          await seedTask(reminder: now.subtract(const Duration(hours: 1)));
      coordinator.setPhase(AppLifecycleState.paused);
      await coordinator.reconcile();

      expect(adapter.scheduled, isEmpty);
      expect(
        await coordinator.deliveryState((await tasks.getTask(id))!),
        ReminderDeliveryState.expired,
      );
    });
  });

  group('RF-01 a RF-03/CA-03, CA-04 — agenda, atualiza e cancela', () {
    test('CA-03 atualizar lembrete substitui o mesmo identificador',
        () async {
      adapter.supportsScheduling = true;
      final id = await seedTask(reminder: now.add(const Duration(hours: 1)));
      coordinator.setPhase(AppLifecycleState.paused);
      await coordinator.reconcile();
      expect(adapter.scheduled.keys, [notificationIdFor(id)]);

      // Editar o instante (mesma tarefa).
      final task = await tasks.getTask(id);
      tasks.updateTask(
        task!.copyWith(reminder: now.add(const Duration(hours: 2))),
      );
      await coordinator.reconcile();

      expect(adapter.scheduled, hasLength(1)); // sem duplicata (CA-03)
      expect(
        adapter.scheduled.values.single.whenUtc,
        now.add(const Duration(hours: 2)).toUtc(),
      );
    });

    test('CA-04 concluir cancela o aviso e mantém a configuração',
        () async {
      adapter.supportsScheduling = true;
      final id = await seedTask(reminder: now.add(const Duration(hours: 1)));
      coordinator.setPhase(AppLifecycleState.paused);
      await coordinator.reconcile();
      expect(adapter.scheduled, hasLength(1));

      final task = await tasks.getTask(id);
      tasks.updateTask(task!.copyWith(
        status: TaskStatus.completed,
        completedAt: now,
      ));
      await coordinator.reconcile();

      expect(adapter.scheduled, isEmpty);
      expect(adapter.cancelled, contains(notificationIdFor(id)));
      expect((await tasks.getTask(id))!.reminder, isNotNull); // configuração
    });

    test('CA-04 tarefa enviada à lixeira cancela o aviso', () async {
      adapter.supportsScheduling = true;
      final id = await seedTask(reminder: now.add(const Duration(hours: 1)));
      coordinator.setPhase(AppLifecycleState.paused);
      await coordinator.reconcile();

      final task = await tasks.getTask(id);
      tasks.updateTask(task!.copyWith(deletedAt: now));
      await coordinator.reconcile();

      expect(adapter.scheduled, isEmpty);
      expect((await tasks.getTask(id))!.deletedAt, now);
    });
  });

  group('CA-05/CA-13 — primeiro plano x sistema', () {
    test('CA-05 em primeiro plano emite aviso no app, sem sistema', () async {
      adapter.supportsScheduling = true;
      final id = await seedTask(
        reminder: now.add(const Duration(milliseconds: 150)),
        title: 'Beber água',
      );
      await coordinator.reconcile(); // phase inical: resumed

      expect(adapter.scheduled, isEmpty); // sem sistema em foreground
      final reminder = await coordinator.inAppReminders
          .timeout(const Duration(seconds: 3))
          .first;
      expect(reminder.taskId, id);
      expect(reminder.title, 'Beber água');
      expect(adapter.shown, isEmpty);
    });

    test(
        'CA-13 em segundo plano com agendamento do sistema: não duplica',
        () async {
      adapter.supportsScheduling = true;
      await seedTask(
        reminder: now.add(const Duration(milliseconds: 150)),
      );
      coordinator.setPhase(AppLifecycleState.paused); // reconcilia
      await coordinator.reconcile();
      expect(adapter.scheduled, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(adapter.shown, isEmpty); // o sistema cuida do aviso
    });

    test('CA-13 Web/Linux em segundo plano: aviso imediato único', () async {
      adapter.supportsScheduling = false;
      await seedTask(
        reminder: now.add(const Duration(milliseconds: 150)),
        title: 'Abrir app',
      );
      coordinator.setPhase(AppLifecycleState.paused);
      await coordinator.reconcile();

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(adapter.shown, hasLength(1));
      expect(adapter.scheduled, isEmpty);
    });
  });

  group('estados de entrega (spec 08, seção 3.2)', () {
    Future<ReminderDeliveryState> stateOf(NotificationCapability cap) async {
      adapter.capability = cap;
      final id = await seedTask(reminder: now.add(const Duration(hours: 1)));
      final task = await tasks.getTask(id);
      return coordinator.deliveryState(task!);
    }

    test('agendado com permissão concedida (CA-12)', () async {
      expect(
        await stateOf(const NotificationCapability(
          supported: true,
          permission: NotificationPermission.granted,
          canRequestPermission: false,
          supportsScheduling: true,
        )),
        ReminderDeliveryState.scheduled,
      );
    });

    test('permissão necessária', () async {
      expect(
        await stateOf(const NotificationCapability(
          supported: true,
          permission: NotificationPermission.denied,
          canRequestPermission: false,
          supportsScheduling: true,
        )),
        ReminderDeliveryState.permissionNeeded,
      );
    });

    test('indisponível nesta plataforma', () async {
      expect(
        await stateOf(NotificationCapability.unsupported),
        ReminderDeliveryState.unavailable,
      );
    });

    test('pendente quando a consulta falha', () async {
      final broken = BrokenCapabilityAdapter();
      final c = ReminderCoordinator(
        adapter: broken,
        tasks: tasks,
        now: () => now,
      );
      addTearDown(c.dispose);
      await seedTask(reminder: now.add(const Duration(hours: 1)));
      final task = await tasks.getTask('task-0');
      expect(
        await c.deliveryState(task!),
        ReminderDeliveryState.pending,
      );
    });
  });

  group('CA-06 — toque na notificação', () {
    test('encaminha o payload para a navegação', () async {
      String? opened;
      coordinator.onNotificationOpened = (taskId) => opened = taskId;
      adapter.triggerOpened('task-abc');
      expect(opened, 'task-abc');
    });
  });

  group('identificador estável (spec 08, seção 5)', () {
    test('mesmo UUID gera o mesmo id e tarefas distintas diferem', () {
      expect(notificationIdFor('abc12345-0000'), notificationIdFor('abc12345-0000'));
      expect(notificationIdFor('abc12345-0000'), isNot(notificationIdFor('bbc12345-0000')));
      expect(notificationIdFor('abc12345-0000'), inInclusiveRange(0, 0x7FFFFFFF));
    });
  });
}

/// Adaptador cuja consulta de capacidade falha (estado pendente).
class BrokenCapabilityAdapter implements NotificationAdapter {
  @override
  bool get supportsScheduling => false;

  @override
  Future<NotificationCapability> checkCapability() async =>
      throw StateError('indisponível');

  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.unavailable;

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required DateTime whenUtc,
    required String payload,
  }) async =>
      false;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> showImmediate({
    required int id,
    required String title,
    required String payload,
  }) async {}

  @override
  void setOnOpened(void Function(String payload)? callback) {}
}
