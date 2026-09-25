// Adaptador nativo: Android, iOS, macOS, Windows e Linux (ADR-0004).
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_delivery.dart';

/// Fábrica do adaptador desta plataforma.
NotificationAdapter createAdapter() => IoNotificationAdapter();

class IoNotificationAdapter implements NotificationAdapter {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String payload)? _onOpened;
  bool _initialized = false;
  bool _tzReady = false;

  @override
  bool get supportsScheduling {
    // Linux: freedesktop não agenda no serviço (spec 08, matriz) —
    // entrega com o processo vivo via coordenador (ADR-0004).
    if (Platform.isLinux) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        macOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: const WindowsInitializationSettings(
          appName: 'Urutau Tasks',
          appUserModelId: 'UrutauTasks',
          guid: '{7E1A4B2C-9C41-4E8F-9B6D-2F3E5A7C9D01}',
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onOpened?.call(payload);
        }
      },
    );
    _initialized = true;
  }

  Future<void> _ensureTimezones() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Exception {
      // Sem identificador IANA: mantém o local padrão do pacote.
    }
    _tzReady = true;
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Lembretes',
          channelDescription: 'Avisos de lembretes de tarefas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

  @override
  Future<NotificationCapability> checkCapability() async {
    try {
      await _ensureInitialized();
    } on Exception {
      return NotificationCapability.unsupported;
    }

    if (Platform.isAndroid) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      if (enabled == null) return NotificationCapability.unsupported;
      return NotificationCapability(
        supported: true,
        permission: enabled
            ? NotificationPermission.granted
            : NotificationPermission.notDetermined,
        canRequestPermission: !enabled,
        supportsScheduling: supportsScheduling,
        limitationKey: enabled ? null : 'reminderStatePermission',
      );
    }

    NotificationsEnabledOptions? options;
    if (Platform.isIOS) {
      options = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
    } else if (Platform.isMacOS) {
      options = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
    }
    if (Platform.isIOS || Platform.isMacOS) {
      if (options == null) {
        return NotificationCapability(
          supported: true,
          permission: NotificationPermission.notDetermined,
          canRequestPermission: true,
          supportsScheduling: supportsScheduling,
        );
      }
      return NotificationCapability(
        supported: true,
        permission: options.isEnabled
            ? NotificationPermission.granted
            : NotificationPermission.denied,
        canRequestPermission: false,
        supportsScheduling: supportsScheduling,
        limitationKey: options.isEnabled ? null : 'reminderStatePermission',
      );
    }

    // Windows e Linux: sem diálogo de permissão equivalente no plugin.
    return NotificationCapability(
      supported: true,
      permission: NotificationPermission.granted,
      canRequestPermission: false,
      supportsScheduling: supportsScheduling,
      limitationKey: supportsScheduling ? null : 'reminderStateUnavailable',
    );
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted == true
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted == true
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    if (Platform.isMacOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted == true
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    return NotificationPermission.granted;
  }

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required DateTime whenUtc,
    required String payload,
  }) async {
    if (!supportsScheduling) return false;
    try {
      await _ensureInitialized();
      await _ensureTimezones();
      final when = whenUtc.toLocal();
      await _plugin.zonedSchedule(
        id: id,
        // Modo aproximado sem acesso a alarmes exatos (spec 08, CA-11).
        androidScheduleMode: AndroidScheduleMode.inexact,
        scheduledDate: tz.TZDateTime(
          tz.local,
          when.year,
          when.month,
          when.day,
          when.hour,
          when.minute,
          when.second,
        ),
        title: title,
        body: '',
        payload: payload,
        notificationDetails: _details(),
      );
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: id);
    } on Exception {
      // Idempotente: cancelar algo inexistente ou sem permissão não falha
      // o fluxo (spec 08, seção 5).
    }
  }

  @override
  Future<void> showImmediate({
    required int id,
    required String title,
    required String payload,
  }) async {
    try {
      await _ensureInitialized();
      await _plugin.show(
        id: id,
        title: title,
        body: '',
        notificationDetails: _details(),
        payload: payload,
      );
    } on Exception {
      // Best effort (spec 08, matriz).
    }
  }

  @override
  void setOnOpened(void Function(String payload)? callback) {
    _onOpened = callback;
  }
}
