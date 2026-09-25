// Adaptador quando a plataforma não oferece notificações (spec 08).
import '../domain/reminder_delivery.dart';

/// Fábrica do adaptador desta plataforma.
NotificationAdapter createAdapter() => UnsupportedNotificationAdapter();

class UnsupportedNotificationAdapter implements NotificationAdapter {
  @override
  bool get supportsScheduling => false;

  @override
  Future<NotificationCapability> checkCapability() async =>
      NotificationCapability.unsupported;

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
