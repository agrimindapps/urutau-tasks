import '../domain/reminder_delivery.dart';

/// Adaptador para plataformas sem suporte a notificações.
class StubReminderAdapter implements ReminderAdapter {
  @override
  void setOnOpenTask(void Function(String taskId) handler) {}

  @override
  Future<ReminderCapability> queryCapability() async =>
      ReminderCapability.unsupported;

  @override
  Future<ReminderPermission> queryPermission() async =>
      ReminderPermission.granted;

  @override
  Future<ReminderPermission> requestPermission() async =>
      ReminderPermission.granted;

  @override
  Future<void> schedule({
    required String taskId,
    required String title,
    required DateTime fireAt,
  }) async {}

  @override
  Future<void> cancel({required String taskId}) async {}
}

/// Fábrica do adaptador para plataformas sem suporte.
ReminderAdapter createPlatformReminderAdapter() => StubReminderAdapter();
