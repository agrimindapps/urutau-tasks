import 'package:urutau_tasks/src/features/notifications/domain/reminder_delivery.dart';
import 'package:urutau_tasks/src/features/notifications/platform/reminder_permission_store.dart';

/// Adaptador falso para testes (spec 08): grava agendamentos, cancels,
/// avisos imediatos e pedidos de permissão em memória.
class FakeNotificationAdapter implements NotificationAdapter {
  @override
  bool supportsScheduling;

  NotificationCapability capability;

  final scheduled = <int, ({String title, DateTime whenUtc, String payload})>{};
  final cancelled = <int>[];
  final shown = <int>[];
  int requestPermissionCalls = 0;
  NotificationPermission nextRequestResult = NotificationPermission.granted;

  void Function(String payload)? _onOpened;

  FakeNotificationAdapter({
    this.supportsScheduling = false,
    NotificationCapability? capability,
  }) : capability = capability ??
            const NotificationCapability(
              supported: true,
              permission: NotificationPermission.granted,
              canRequestPermission: false,
              supportsScheduling: false,
            );

  @override
  Future<NotificationCapability> checkCapability() async => capability;

  @override
  Future<NotificationPermission> requestPermission() async {
    requestPermissionCalls += 1;
    return nextRequestResult;
  }

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required DateTime whenUtc,
    required String payload,
  }) async {
    scheduled[id] = (title: title, whenUtc: whenUtc, payload: payload);
    return true;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    cancelled.add(id);
  }

  @override
  Future<void> showImmediate({
    required int id,
    required String title,
    required String payload,
  }) async {
    shown.add(id);
  }

  @override
  void setOnOpened(void Function(String payload)? callback) {
    _onOpened = callback;
  }

  /// Simula o toque do usuário em uma notificação do sistema (CA-06).
  void triggerOpened(String payload) => _onOpened?.call(payload);
}

/// Armazenamento falso da permissão (spec 08, seção 6).
class InMemoryReminderPermissionStore implements ReminderPermissionStore {
  bool explained = false;

  @override
  Future<bool> isExplained() async => explained;

  @override
  Future<void> markExplained() async {
    explained = true;
  }
}
