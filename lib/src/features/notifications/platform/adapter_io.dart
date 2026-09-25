import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_delivery.dart';

/// Adaptador nativo (Android/iOS/macOS/Windows/Linux) com
/// `flutter_local_notifications` (ADR-0004).
///
/// Matriz de capacidade (spec 08, §4): Android agenda de forma
/// aproximada (sem alarmes exatos), iOS/macOS exigem autorização e
/// Windows/Linux são best effort.
class IoReminderAdapter implements ReminderAdapter {
  IoReminderAdapter(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  void Function(String taskId)? _onOpenTask;

  @override
  void setOnOpenTask(void Function(String taskId) handler) {
    _onOpenTask = handler;
  }

  static const InitializationSettings _settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
    macOS: DarwinInitializationSettings(),
  );

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fallback: UTC quando o fuso não pôde ser lido.
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      _settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _onOpenTask?.call(payload);
        }
      },
    );
    _initialized = true;
  }

  @override
  Future<ReminderCapability> queryCapability() async {
    return ReminderCapability.supported;
  }

  @override
  Future<ReminderPermission> queryPermission() async {
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return switch (enabled) {
        true => ReminderPermission.granted,
        false => ReminderPermission.denied,
        null => ReminderPermission.notDetermined,
      };
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final darwin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await darwin?.checkPermissions();
      if (options == null) return ReminderPermission.notDetermined;
      return options.isEnabled
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    // Windows/Linux: best effort sem bloqueio de permissão.
    return ReminderPermission.granted;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted == true
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final darwin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await darwin?.requestPermissions(alert: true);
      return granted == true
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    return ReminderPermission.granted;
  }

  @override
  Future<void> schedule({
    required String taskId,
    required String title,
    required DateTime fireAt,
  }) async {
    await _ensureInitialized();
    // Substitui qualquer agendamento anterior (máx. 1 por tarefa — §5).
    await cancel(taskId: taskId);
    final when = tz.TZDateTime.from(fireAt, tz.local);
    await _plugin.zonedSchedule(
      _scheduleId(taskId),
      title,
      null,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'urutau_reminders',
          'Lembretes',
          channelDescription: 'Lembretes de tarefas do Urutau Tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: taskId,
    );
  }

  @override
  Future<void> cancel({required String taskId}) async {
    await _ensureInitialized();
    await _plugin.cancel(_scheduleId(taskId));
  }

  /// ID inteiro estável por UUID de tarefa (infraestrutura, fora do backup).
  int _scheduleId(String taskId) {
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

/// Fábrica do adaptador nativo.
ReminderAdapter createPlatformReminderAdapter() =>
    IoReminderAdapter(FlutterLocalNotificationsPlugin());
