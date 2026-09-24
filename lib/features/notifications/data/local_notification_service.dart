import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../../core/database/app_database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task.dart';

enum ReminderDeliveryStatus {
  noReminder,
  pendingVerification,
  cancellationPending,
  scheduled,
  permissionRequired,
  unavailable,
  expired,
  paused,
}

enum _NativeScheduleResult { scheduled, unavailable, cancellationPending }

class LocalNotificationService {
  LocalNotificationService(this._database, this._tasks);

  final AppDatabase _database;
  final TaskRepository _tasks;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, ReminderDeliveryStatus> _statuses = {};
  final Map<String, StreamController<ReminderDeliveryStatus>> _statusStreams =
      {};
  final Map<String, _InProcessReminder> _timers = {};
  final Map<String, _NativeReminder> _nativeReminders = {};

  StreamSubscription<List<Task>>? _taskSubscription;
  Future<void> _reconcileQueue = Future<void>.value();
  Future<void> _localeRefreshQueue = Future<void>.value();
  List<Task> _latestTasks = const [];
  Future<void>? _startFuture;
  void Function(String taskId)? _onOpenTask;
  void Function(String taskId, String title)? _onForegroundReminder;
  bool _foreground = true;
  bool _started = false;
  bool _disposed = false;
  bool _systemNotificationsAvailable = true;
  AppLocalizations? _localizations;

  Stream<ReminderDeliveryStatus> watchDeliveryStatus(String taskId) async* {
    yield _statuses[taskId] ?? ReminderDeliveryStatus.pendingVerification;
    yield* _statusStreams
        .putIfAbsent(
          taskId,
          () => StreamController<ReminderDeliveryStatus>.broadcast(),
        )
        .stream;
  }

  Future<bool> shouldExplainPermissionPrompt() async {
    await ensureStarted();
    if (!_systemNotificationsAvailable) return false;
    if (await _readBooleanSetting(_permissionRequestedKey)) return false;
    return !await _permissionGranted();
  }

  Future<void> requestPermissionFromUser({bool explicitRetry = false}) async {
    if (kIsWeb) {
      if (!_systemNotificationsAvailable) return;
      final webPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >();
      Future<bool?>? permissionRequest;
      try {
        if (webPlugin?.permissionStatus != WebNotificationPermission.granted) {
          // Invoke the Web API before the first await so the browser still
          // sees the explicit button press that initiated this request.
          permissionRequest = webPlugin?.requestNotificationsPermission();
        }
      } catch (_) {
        // Permission requests are best effort and never block saving a reminder.
      }
      final persistRequest = _writeBooleanSetting(
        _permissionRequestedKey,
        true,
      );
      try {
        await permissionRequest;
      } catch (_) {
        // A browser may reject the request when notifications are unavailable.
      }
      await persistRequest;
      _enqueueReconcile(_latestTasks);
      return;
    }

    await ensureStarted();
    final requested = await _readBooleanSetting(_permissionRequestedKey);
    if (await _permissionGranted()) {
      await _writeBooleanSetting(_permissionRequestedKey, true);
      _enqueueReconcile(_latestTasks);
      return;
    }
    if (requested && !explicitRetry) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {
      // Permission requests are best effort and never block saving a reminder.
    }
    await _writeBooleanSetting(_permissionRequestedKey, true);
    _enqueueReconcile(_latestTasks);
  }

  Future<void> openPermissionSettings() async {
    if (kIsWeb) {
      await requestPermissionFromUser(explicitRetry: true);
      return;
    }
    await ensureStarted();
    try {
      await _plugin.openAppNotificationSettings();
    } catch (_) {
      // Some platforms have no app-specific notification settings screen.
    }
  }

  Future<void> ensureStarted({
    void Function(String taskId)? onOpenTask,
    void Function(String taskId, String title)? onForegroundReminder,
  }) {
    if (onOpenTask != null) _onOpenTask = onOpenTask;
    if (onForegroundReminder != null) {
      _onForegroundReminder = onForegroundReminder;
    }
    return _startFuture ??= _start();
  }

  /// Rebuilds notification delivery from the committed task state.
  ///
  /// Import and restore operations replace several tables in one transaction.
  /// Reading a fresh task snapshot here avoids reconciling against a stale
  /// stream value while the database watch is still delivering its update.
  Future<void> reconcileNow() async {
    try {
      await ensureStarted();
      final tasks = await _tasks.watchTasks().first;
      if (_disposed) return;
      _latestTasks = tasks;
      _enqueueReconcile(tasks);
      await _reconcileQueue;
    } catch (_) {
      // Notification delivery is best effort and must not undo a restore.
    }
  }

  Future<void> refreshLocalization() {
    _localeRefreshQueue = _localeRefreshQueue
        .then((_) => _refreshLocalization())
        .catchError((Object _) {});
    return _localeRefreshQueue;
  }

  Future<void> _refreshLocalization() async {
    try {
      await ensureStarted();
      if (_disposed) return;
      _localizations = await AppLocalizations.delegate.load(
        await _notificationLocale(),
      );
      _systemNotificationsAvailable = await _initializePlatformNotifications();
      if (_systemNotificationsAvailable) {
        await _syncAndroidNotificationChannelLocalization();
      }
    } catch (_) {
      _systemNotificationsAvailable = false;
    }
    _enqueueReconcile(_latestTasks);
  }

  Future<void> onLifecycleChanged(AppLifecycleState state) async {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      await ensureStarted();
      await _refreshNotificationPlatformAvailability();
      _enqueueReconcile(_latestTasks);
    } else if (_started) {
      _enqueueReconcile(_latestTasks);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _taskSubscription?.cancel();
    for (final timer in _timers.values) {
      timer.timer.cancel();
    }
    _timers.clear();
    for (final stream in _statusStreams.values) {
      await stream.close();
    }
    _statusStreams.clear();
  }

  Future<void> _start() async {
    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.UTC);
    _localizations = await AppLocalizations.delegate.load(
      await _notificationLocale(),
    );
    try {
      _systemNotificationsAvailable = await _initializePlatformNotifications();
      if (_systemNotificationsAvailable) {
        await _syncAndroidNotificationChannelLocalization();
        final launch = await _plugin.getNotificationAppLaunchDetails();
        final payload = launch?.notificationResponse?.payload;
        if (launch?.didNotificationLaunchApp == true && payload != null) {
          _onOpenTask?.call(payload);
        }
      }
    } catch (_) {
      _systemNotificationsAvailable = false;
    }
    if (_disposed) return;
    _started = true;
    _taskSubscription = _tasks.watchTasks().listen(
      (tasks) {
        _latestTasks = tasks;
        _enqueueReconcile(tasks);
      },
      onError: (_) {
        for (final task in _latestTasks) {
          if (task.reminderAtUtc != null) {
            _setStatus(task.id, ReminderDeliveryStatus.pendingVerification);
          }
        }
      },
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId != null && taskId.isNotEmpty) _onOpenTask?.call(taskId);
  }

  void _enqueueReconcile(List<Task> tasks) {
    if (_disposed || !_started) return;
    _latestTasks = tasks;
    _reconcileQueue = _reconcileQueue
        .then((_) => _reconcile(_latestTasks))
        .catchError((Object _) {});
  }

  Future<void> _reconcile(List<Task> tasks) async {
    if (_disposed) return;
    final pendingNativeCounts = _supportsNativeScheduling
        ? await _pendingNativeNotificationCounts()
        : null;
    final tasksById = {for (final task in tasks) task.id: task};
    final mappings = await _database
        .select(_database.notificationMappings)
        .get();
    final notificationIds = {
      for (final mapping in mappings) mapping.taskId: mapping.notificationId,
    };
    final usedIds = notificationIds.values.toSet();
    for (final task in tasks.where((item) => item.reminderAtUtc != null)) {
      if (notificationIds.containsKey(task.id)) continue;
      final id = _nextNotificationId(usedIds);
      usedIds.add(id);
      await _database
          .into(_database.notificationMappings)
          .insert(
            NotificationMappingsCompanion.insert(
              taskId: task.id,
              notificationId: id,
            ),
          );
      notificationIds[task.id] = id;
    }

    for (final taskId in notificationIds.keys.where(
      (taskId) => !tasksById.containsKey(taskId),
    )) {
      final notificationId = notificationIds[taskId]!;
      final cancelled = await _cancelTaskDelivery(
        taskId,
        notificationId,
        scheduledCopies: pendingNativeCounts?[notificationId] ?? 1,
      );
      if (cancelled) {
        await (_database.delete(
          _database.notificationMappings,
        )..where((row) => row.taskId.equals(taskId))).go();
      } else {
        _setStatus(taskId, ReminderDeliveryStatus.cancellationPending);
      }
    }

    for (final task in tasks) {
      final reminder = task.reminderAtUtc;
      final notificationId = notificationIds[task.id];
      final nativeCopies = notificationId == null
          ? 1
          : pendingNativeCounts?[notificationId] ?? 1;
      if (reminder == null) {
        var cancelled = true;
        if (notificationId != null) {
          cancelled = await _cancelTaskDelivery(
            task.id,
            notificationId,
            scheduledCopies: nativeCopies,
          );
        } else {
          _cancelTimer(task.id);
        }
        _setStatus(
          task.id,
          cancelled
              ? ReminderDeliveryStatus.noReminder
              : ReminderDeliveryStatus.cancellationPending,
        );
        continue;
      }
      if (task.status != TaskStatus.active) {
        var cancelled = true;
        if (notificationId != null) {
          cancelled = await _cancelTaskDelivery(
            task.id,
            notificationId,
            scheduledCopies: nativeCopies,
          );
        } else {
          _cancelTimer(task.id);
        }
        _setStatus(
          task.id,
          cancelled
              ? ReminderDeliveryStatus.paused
              : ReminderDeliveryStatus.cancellationPending,
        );
        continue;
      }
      if (!reminder.isAfter(DateTime.now().toUtc())) {
        var cancelled = true;
        if (notificationId != null) {
          cancelled = await _cancelTaskDelivery(
            task.id,
            notificationId,
            scheduledCopies: nativeCopies,
          );
        } else {
          _cancelTimer(task.id);
        }
        _setStatus(
          task.id,
          cancelled
              ? ReminderDeliveryStatus.expired
              : ReminderDeliveryStatus.cancellationPending,
        );
        continue;
      }

      if (!_systemNotificationsAvailable) {
        var cancelled = true;
        if (notificationId != null) {
          cancelled = await _cancelNativeSchedule(
            task.id,
            notificationId,
            scheduledCopies: nativeCopies,
          );
        }
        if (cancelled &&
            (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.linux ||
                _foreground)) {
          _ensureTimer(task);
        } else {
          _cancelTimer(task.id);
        }
        _setStatus(
          task.id,
          cancelled
              ? ReminderDeliveryStatus.unavailable
              : ReminderDeliveryStatus.cancellationPending,
        );
        continue;
      }

      final permitted = await _permissionGranted();
      if (!permitted) {
        var cancelled = true;
        if (notificationId != null) {
          cancelled = await _cancelNativeSchedule(
            task.id,
            notificationId,
            scheduledCopies: nativeCopies,
          );
        }
        if (_foreground && cancelled) {
          _ensureTimer(task);
        } else {
          _cancelTimer(task.id);
        }
        _setStatus(
          task.id,
          cancelled
              ? ReminderDeliveryStatus.permissionRequired
              : ReminderDeliveryStatus.cancellationPending,
        );
        continue;
      }

      if (_supportsNativeScheduling) {
        var scheduleAccepted = true;
        var failureStatus = ReminderDeliveryStatus.unavailable;
        if (_foreground) {
          scheduleAccepted = await _cancelNativeSchedule(
            task.id,
            notificationId!,
            scheduledCopies: nativeCopies,
          );
          if (scheduleAccepted) {
            _ensureTimer(task);
          } else {
            _cancelTimer(task.id);
            failureStatus = ReminderDeliveryStatus.cancellationPending;
          }
        } else {
          _cancelTimer(task.id);
          final scheduleResult = await _ensureNativeSchedule(
            task,
            notificationId!,
            pendingNativeCounts,
          );
          scheduleAccepted = scheduleResult == _NativeScheduleResult.scheduled;
          if (scheduleResult == _NativeScheduleResult.cancellationPending) {
            failureStatus = ReminderDeliveryStatus.cancellationPending;
          }
        }
        _setStatus(
          task.id,
          scheduleAccepted ? ReminderDeliveryStatus.scheduled : failureStatus,
        );
      } else if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
        var scheduleAccepted = true;
        if (notificationId != null) {
          scheduleAccepted = await _cancelNativeSchedule(
            task.id,
            notificationId,
            scheduledCopies: nativeCopies,
          );
        }
        if (scheduleAccepted) {
          _ensureTimer(task);
        } else {
          _cancelTimer(task.id);
        }
        _setStatus(
          task.id,
          scheduleAccepted
              ? ReminderDeliveryStatus.scheduled
              : ReminderDeliveryStatus.cancellationPending,
        );
      } else {
        var cancelled = true;
        if (notificationId != null) {
          cancelled = await _cancelNativeSchedule(
            task.id,
            notificationId,
            scheduledCopies: nativeCopies,
          );
        }
        if (_foreground && cancelled) {
          _ensureTimer(task);
        } else {
          _cancelTimer(task.id);
        }
        _setStatus(
          task.id,
          cancelled
              ? ReminderDeliveryStatus.unavailable
              : ReminderDeliveryStatus.cancellationPending,
        );
      }
    }
  }

  bool get _supportsNativeScheduling {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.windows => _hasWindowsPackageIdentity,
      _ => false,
    };
  }

  bool get _hasWindowsPackageIdentity {
    try {
      return MsixUtils.hasPackageIdentity();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _initializePlatformNotifications() async {
    final initialized = await _plugin.initialize(
      settings: _initializationSettings(),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    if (kIsWeb) {
      return initialized == true &&
          WebFlutterLocalNotificationsPlugin.isSupported;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.windows => initialized == true,
      // Darwin initialization can return false when permission is denied;
      // permission is queried independently below.
      TargetPlatform.iOS || TargetPlatform.macOS => initialized != null,
      TargetPlatform.linux => _linuxNotificationServerAvailable(initialized),
      _ => false,
    };
  }

  Future<bool> _linuxNotificationServerAvailable(bool? initialized) async {
    if (initialized != true) return false;
    final linuxPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          LinuxFlutterLocalNotificationsPlugin
        >();
    if (linuxPlugin == null) return false;
    await linuxPlugin.getCapabilities();
    return true;
  }

  Future<void> _refreshNotificationPlatformAvailability() async {
    try {
      if (kIsWeb) {
        _systemNotificationsAvailable =
            await _initializePlatformNotifications();
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linuxPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              LinuxFlutterLocalNotificationsPlugin
            >();
        if (linuxPlugin == null) {
          _systemNotificationsAvailable = false;
        } else {
          await linuxPlugin.getCapabilities();
          _systemNotificationsAvailable = true;
        }
      }
    } catch (_) {
      _systemNotificationsAvailable = false;
    }
  }

  Future<bool> _permissionGranted() async {
    try {
      if (kIsWeb) {
        return _plugin
                .resolvePlatformSpecificImplementation<
                  WebFlutterLocalNotificationsPlugin
                >()
                ?.permissionStatus ==
            WebNotificationPermission.granted;
      }
      return switch (defaultTargetPlatform) {
        TargetPlatform.android =>
          await _plugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()
                  ?.areNotificationsEnabled() ??
              false,
        TargetPlatform.iOS =>
          (await _plugin
                      .resolvePlatformSpecificImplementation<
                        IOSFlutterLocalNotificationsPlugin
                      >()
                      ?.checkPermissions())
                  ?.isEnabled ??
              false,
        TargetPlatform.macOS =>
          (await _plugin
                      .resolvePlatformSpecificImplementation<
                        MacOSFlutterLocalNotificationsPlugin
                      >()
                      ?.checkPermissions())
                  ?.isEnabled ??
              false,
        TargetPlatform.windows => true,
        TargetPlatform.linux => true,
        _ => false,
      };
    } catch (_) {
      return false;
    }
  }

  Future<Map<int, int>?> _pendingNativeNotificationCounts() async {
    try {
      final requests = await _plugin.pendingNotificationRequests();
      final counts = <int, int>{};
      for (final request in requests) {
        counts.update(request.id, (count) => count + 1, ifAbsent: () => 1);
      }
      return counts;
    } catch (_) {
      return null;
    }
  }

  Future<_NativeScheduleResult> _ensureNativeSchedule(
    Task task,
    int notificationId,
    Map<int, int>? pendingCounts,
  ) async {
    final reminder = task.reminderAtUtc!;
    final previous = _nativeReminders[task.id];
    if (previous?.reminderAtUtc == reminder &&
        previous?.title == task.title &&
        pendingCounts?[notificationId] == 1) {
      return _NativeScheduleResult.scheduled;
    }
    try {
      // Replacing a Windows scheduled toast with the same tag does not
      // implicitly replace the old schedule. Clear any visible copies first;
      // on startup this also rebuilds the in-memory fingerprint safely.
      final scheduledCopies = pendingCounts?[notificationId] ?? 1;
      if (!await _cancelNativeSchedule(
        task.id,
        notificationId,
        scheduledCopies: scheduledCopies,
      )) {
        return _NativeScheduleResult.cancellationPending;
      }
      await _plugin.zonedSchedule(
        id: notificationId,
        title: task.title,
        payload: task.id,
        scheduledDate: timezone.TZDateTime.from(reminder, timezone.UTC),
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      _nativeReminders[task.id] = _NativeReminder(reminder, task.title);
      return _NativeScheduleResult.scheduled;
    } catch (_) {
      final cancelled = await _cancelNativeSchedule(task.id, notificationId);
      if (_foreground && cancelled) {
        _ensureTimer(task);
        return _NativeScheduleResult.scheduled;
      }
      return cancelled
          ? _NativeScheduleResult.unavailable
          : _NativeScheduleResult.cancellationPending;
    }
  }

  Future<bool> _cancelNativeSchedule(
    String taskId,
    int notificationId, {
    int scheduledCopies = 1,
  }) async {
    _nativeReminders.remove(taskId);
    final copies = scheduledCopies > 0 ? scheduledCopies : 1;
    for (var copy = 0; copy < copies; copy++) {
      try {
        await _plugin.cancel(id: notificationId);
      } catch (_) {
        // Avoid creating a second schedule when the previous one may remain.
        return false;
      }
    }
    return true;
  }

  Future<bool> _cancelTaskDelivery(
    String taskId,
    int notificationId, {
    int scheduledCopies = 1,
  }) async {
    _cancelTimer(taskId);
    return _cancelNativeSchedule(
      taskId,
      notificationId,
      scheduledCopies: scheduledCopies,
    );
  }

  void _ensureTimer(Task task) {
    final reminder = task.reminderAtUtc!;
    final previous = _timers[task.id];
    if (previous?.reminderAtUtc == reminder && previous?.title == task.title) {
      return;
    }
    previous?.timer.cancel();
    final timer = Timer(_boundedDelay(reminder), () {
      _timers.remove(task.id);
      unawaited(_fireTimer(task.id, task.title, reminder));
    });
    _timers[task.id] = _InProcessReminder(reminder, task.title, timer);
  }

  Duration _boundedDelay(DateTime reminder) {
    final remaining = reminder
        .difference(DateTime.now().toUtc())
        .inMilliseconds;
    return Duration(milliseconds: remaining.clamp(1, 2147483647));
  }

  void _cancelTimer(String taskId) {
    _timers.remove(taskId)?.timer.cancel();
  }

  Future<void> _fireTimer(
    String taskId,
    String title,
    DateTime reminder,
  ) async {
    if (_disposed) return;
    final task =
        await (_database.select(_database.tasks)
              ..where((row) => row.id.equals(taskId)))
            .getSingleOrNull()
            .catchError((Object _) => null);
    if (task == null ||
        task.status != TaskStatus.active.databaseValue ||
        task.reminderAtUtc != reminder.millisecondsSinceEpoch) {
      return;
    }
    if (reminder.isAfter(DateTime.now().toUtc())) {
      final domainTask = _latestTasks
          .where((item) => item.id == taskId)
          .firstOrNull;
      if (domainTask != null) _ensureTimer(domainTask);
      return;
    }
    title = task.title;
    _setStatus(taskId, ReminderDeliveryStatus.expired);
    if (_foreground) {
      _onForegroundReminder?.call(taskId, title);
      return;
    }
    final canShowSystemNotice =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        _supportsNativeScheduling;
    if (!canShowSystemNotice) return;

    int? notificationId;
    if (_supportsNativeScheduling) {
      // A lifecycle reconciliation normally moves native reminders from the
      // foreground timer to a system schedule. Wait for that transition before
      // deciding whether an immediate notice is needed, avoiding duplicates.
      await _reconcileQueue;
      if (_disposed) return;
      final pendingCounts = await _pendingNativeNotificationCounts();
      if (pendingCounts == null) return;
      notificationId = await _notificationIdFor(taskId);
      if ((pendingCounts[notificationId] ?? 0) > 0) return;
    }
    if (!await _permissionGranted()) return;

    try {
      final currentTask = await (_database.select(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).getSingleOrNull();
      if (currentTask == null ||
          currentTask.status != TaskStatus.active.databaseValue ||
          currentTask.reminderAtUtc != reminder.millisecondsSinceEpoch) {
        return;
      }
      await _plugin.show(
        id: notificationId ?? await _notificationIdFor(taskId),
        title: currentTask.title,
        payload: taskId,
        notificationDetails: _notificationDetails,
      );
    } catch (_) {
      _setStatus(taskId, ReminderDeliveryStatus.unavailable);
    }
  }

  Future<int> _notificationIdFor(String taskId) async {
    final row = await (_database.select(
      _database.notificationMappings,
    )..where((mapping) => mapping.taskId.equals(taskId))).getSingleOrNull();
    if (row == null) throw StateError('Missing notification ID for $taskId');
    return row.notificationId;
  }

  int _nextNotificationId(Set<int> used) {
    var candidate = 1;
    while (used.contains(candidate)) {
      candidate++;
      if (candidate >= 2147483647) candidate = 1;
    }
    return candidate;
  }

  Future<bool> _readBooleanSetting(String key) async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((setting) => setting.settingKey.equals(key))).getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> _writeBooleanSetting(String key, bool value) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(settingKey: key, value: '$value'),
        );
  }

  void _setStatus(String taskId, ReminderDeliveryStatus status) {
    if (_statuses[taskId] == status) return;
    _statuses[taskId] = status;
    _statusStreams[taskId]?.add(status);
  }

  static const _permissionRequestedKey = 'notifications_permission_requested';

  NotificationDetails get _notificationDetails {
    final l10n = _localizations!;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        presentBanner: false,
        presentList: false,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        presentBanner: false,
        presentList: false,
      ),
      linux: const LinuxNotificationDetails(),
      windows: const WindowsNotificationDetails(),
      web: const WebNotificationDetails(),
    );
  }

  InitializationSettings _initializationSettings() => InitializationSettings(
    android: AndroidInitializationSettings('notification_icon'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: false,
      defaultPresentBanner: false,
      defaultPresentList: false,
    ),
    macOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: false,
      defaultPresentBanner: false,
      defaultPresentList: false,
    ),
    linux: LinuxInitializationSettings(
      defaultActionName: _localizations!.openTask,
    ),
    windows: WindowsInitializationSettings(
      appName: 'Urutau Tasks',
      appUserModelId: 'com.urutau.urutautasks',
      guid: '8b58c476-1436-4ba3-a54d-7d969101f4cd',
    ),
    web: WebInitializationSettings(),
  );

  Future<void> _syncAndroidNotificationChannelLocalization() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              'task_reminders',
              _localizations!.notificationChannelName,
              description: _localizations!.notificationChannelDescription,
              importance: Importance.defaultImportance,
            ),
          );
    } catch (_) {
      // Channel metadata is platform-owned and best effort.
    }
  }

  Future<Locale> _notificationLocale() async {
    final preference =
        await (_database.select(_database.appSettings)..where(
              (setting) => setting.settingKey.equals('interface_language'),
            ))
            .getSingleOrNull();
    final language = switch (preference?.value) {
      'en' => 'en',
      'es' => 'es',
      'pt-BR' => 'pt',
      _ =>
        WidgetsBinding.instance.platformDispatcher.locales
            .map((locale) => locale.languageCode)
            .firstWhere(
              (code) => const {'pt', 'en', 'es'}.contains(code),
              orElse: () => 'pt',
            ),
    };
    return language == 'pt' ? const Locale('pt', 'BR') : Locale(language);
  }
}

class _InProcessReminder {
  _InProcessReminder(this.reminderAtUtc, this.title, this.timer);

  final DateTime reminderAtUtc;
  final String title;
  final Timer timer;
}

class _NativeReminder {
  const _NativeReminder(this.reminderAtUtc, this.title);

  final DateTime reminderAtUtc;
  final String title;
}
