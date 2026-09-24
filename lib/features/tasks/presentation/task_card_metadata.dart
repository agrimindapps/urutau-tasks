import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/task.dart';

class TaskCardMetadata extends StatelessWidget {
  const TaskCardMetadata({required this.task, this.progressText, super.key});

  final Task task;
  final String? progressText;

  static Widget? maybe(Task task, {String? progressText}) {
    if (progressText == null &&
        task.dueDateIso == null &&
        task.reminderAtUtc == null &&
        task.priority == TaskPriority.none) {
      return null;
    }
    return TaskCardMetadata(task: task, progressText: progressText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();
    final details = <Widget>[];
    if (progressText != null) details.add(Text(progressText!));

    final dueDateIso = task.dueDateIso;
    if (dueDateIso != null) {
      final dueDate = parseDateOnly(dueDateIso);
      final formattedDate = DateFormat.yMMMd(locale).format(dueDate);
      final isOverdue =
          task.status == TaskStatus.active &&
          dueDateIso.compareTo(formatDateOnly(DateTime.now())) < 0;
      details.add(
        Text(
          isOverdue
              ? '${l10n.overdue}: $formattedDate'
              : '${l10n.dueDate}: $formattedDate',
          style: isOverdue
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
      );
    }

    final reminder = task.reminderAtUtc;
    if (reminder != null) {
      details.add(
        Text(
          '${l10n.reminder}: ${DateFormat.yMMMd(locale).add_jm().format(reminder.toLocal())}',
        ),
      );
    }

    final priority = switch (task.priority) {
      TaskPriority.none => null,
      TaskPriority.low => l10n.priorityLow,
      TaskPriority.medium => l10n.priorityMedium,
      TaskPriority.high => l10n.priorityHigh,
      TaskPriority.urgent => l10n.priorityUrgent,
    };
    if (priority != null) {
      details.add(Text('${l10n.priority}: $priority'));
    }

    return Wrap(spacing: 12, runSpacing: 4, children: details);
  }
}
