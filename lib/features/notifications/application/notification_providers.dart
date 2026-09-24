import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/application/task_providers.dart';
import '../data/local_notification_service.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  final service = LocalNotificationService(
    ref.watch(appDatabaseProvider),
    ref.watch(taskRepositoryProvider),
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final reminderDeliveryStatusProvider =
    StreamProvider.family<ReminderDeliveryStatus, String>(
      (ref, taskId) => ref
          .watch(localNotificationServiceProvider)
          .watchDeliveryStatus(taskId),
    );
