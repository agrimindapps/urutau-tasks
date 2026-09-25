// Adaptador Web: API Notification do navegador (ADR-0004, spec 08).
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../domain/reminder_delivery.dart';

/// Fábrica do adaptador desta plataforma.
NotificationAdapter createAdapter() => WebNotificationAdapter();

class WebNotificationAdapter implements NotificationAdapter {
  void Function(String payload)? _onOpened;

  @override
  // Web não agenda no navegador sem servidor (ADR-0002/CA-09): a
  // entrega fica com os temporizadores do coordenador.
  bool get supportsScheduling => false;

  bool get _supported =>
      web.window.hasProperty('Notification'.toJS).toDart;

  static NotificationPermission _mapPermission(String raw) => switch (raw) {
        'granted' => NotificationPermission.granted,
        'denied' => NotificationPermission.denied,
        _ => NotificationPermission.notDetermined,
      };

  @override
  Future<NotificationCapability> checkCapability() async {
    if (!_supported) return NotificationCapability.unsupported;
    final permission = _mapPermission(web.Notification.permission);
    return NotificationCapability(
      supported: true,
      permission: permission,
      // Após negativa o navegador não repete o pedido (spec 08, seção 6).
      canRequestPermission:
          permission == NotificationPermission.notDetermined,
      supportsScheduling: false,
      limitationKey: permission == NotificationPermission.granted
          ? null
          : 'reminderStatePermission',
    );
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!_supported) return NotificationPermission.unavailable;
    final result = await web.Notification.requestPermission().toDart;
    return _mapPermission(result.toDart);
  }

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required DateTime whenUtc,
    required String payload,
  }) async =>
      false;

  @override
  Future<void> cancel(int id) async {
    // Sem agendamento do sistema não há o que cancelar.
  }

  @override
  Future<void> showImmediate({
    required int id,
    required String title,
    required String payload,
  }) async {
    if (!_supported) return;
    if (web.Notification.permission != 'granted') return;
    final notification = web.Notification(
      title,
      web.NotificationOptions(body: '', tag: '$id'),
    );
    notification.onclick = ((web.Event _) {
      notification.close();
      _onOpened?.call(payload);
      web.window.focus();
    }).toJS;
  }

  @override
  void setOnOpened(void Function(String payload)? callback) {
    _onOpened = callback;
  }
}
