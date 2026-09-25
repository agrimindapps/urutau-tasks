import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../data/providers.dart';
import '../../tasks/domain/task.dart';
import '../domain/reminder_delivery.dart';

/// Fluxo de permissão de notificação (spec 08, §6, CA-01/CA-02).
///
/// Explica o uso e solicita **uma única vez**; após negativa, o usuário
/// aciona nova tentativa explicitamente.
Future<void> requestReminderPermission(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.permissionTitle),
      content: Text(l10n.permissionExplanation),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.allowNotifications),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ref
      .read(reminderCoordinatorProvider)
      .requestPermissionFromUser(task);
}

/// Traduz o estado de entrega para o texto da interface (spec 08, §3).
String deliveryStateLabel(AppLocalizations l10n, DeliveryState state) {
  return switch (state) {
    DeliveryState.scheduled => l10n.deliveryScheduled,
    DeliveryState.permissionNeeded => l10n.deliveryPermissionNeeded,
    DeliveryState.platformUnsupported => l10n.deliveryUnsupported,
    DeliveryState.overdue => l10n.deliveryOverdue,
    DeliveryState.pendingVerification => l10n.deliveryPending,
  };
}
