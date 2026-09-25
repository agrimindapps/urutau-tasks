import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../domain/reminder_delivery.dart';

/// Adaptador Web: Notification API em modo **best effort** (spec 08, §4).
///
/// Sem servidor não há promessa de entrega com o navegador fechado; o
/// agendamento vale enquanto a página estiver aberta.
class WebReminderAdapter implements ReminderAdapter {
  final Map<String, Timer> _timers = {};
  void Function(String taskId)? _onOpenTask;

  @override
  void setOnOpenTask(void Function(String taskId) handler) {
    _onOpenTask = handler;
  }

  @override
  Future<ReminderCapability> queryCapability() async {
    return ReminderCapability.supported;
  }

  @override
  Future<ReminderPermission> queryPermission() async {
    final value = web.Notification.permission;
    return switch (value) {
      'granted' => ReminderPermission.granted,
      'denied' => ReminderPermission.denied,
      _ => ReminderPermission.notDetermined,
    };
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    final result = await web.Notification.requestPermission().toDart;
    return switch (result.toDart) {
      'granted' => ReminderPermission.granted,
      'denied' => ReminderPermission.denied,
      _ => ReminderPermission.notDetermined,
    };
  }

  /// Conversão de promessa JS para `Future`.

  @override
  Future<void> schedule({
    required String taskId,
    required String title,
    required DateTime fireAt,
  }) async {
    await cancel(taskId: taskId);
    final delay = fireAt.difference(DateTime.now());
    _timers[taskId] = Timer(delay.isNegative ? Duration.zero : delay, () {
      _timers.remove(taskId);
      // Em página visível o aviso de primeiro plano cobre o disparo (§8).
      if (web.document.visibilityState == 'hidden') {
        final notification = web.Notification(
          title,
          web.NotificationOptions(
            body: fireAt.toIso8601String(),
            tag: reminderScheduleId(taskId),
          ),
        );
        notification.onclick = ((web.Event _) {
          _onOpenTask?.call(taskId);
        }).toJS;
      }
    });
  }

  @override
  Future<void> cancel({required String taskId}) async {
    _timers.remove(taskId)?.cancel();
  }
}

/// Fábrica do adaptador Web.
ReminderAdapter createPlatformReminderAdapter() => WebReminderAdapter();
