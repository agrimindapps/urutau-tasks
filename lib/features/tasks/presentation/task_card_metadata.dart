import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../organization/domain/organization.dart';
import '../domain/task.dart';

class TaskCardMetadata extends StatelessWidget {
  const TaskCardMetadata({
    required this.task,
    this.progressText,
    this.sourceText,
    super.key,
  });

  final Task task;
  final String? progressText;
  final String? sourceText;

  static Widget? maybe(Task task, {String? progressText, String? sourceText}) {
    if (progressText == null &&
        sourceText == null &&
        task.dueDateIso == null &&
        task.reminderAtUtc == null &&
        task.priority == TaskPriority.none) {
      return null;
    }
    return TaskCardMetadata(
      task: task,
      progressText: progressText,
      sourceText: sourceText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();
    final details = <Widget>[];
    if (progressText != null) details.add(Text(progressText!));
    if (sourceText != null) details.add(Text(sourceText!));

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

String? taskOriginLabel({
  required Task task,
  required Map<String, TaskList> listsById,
  required Map<String, TaskGroup> groupsById,
  required AppLocalizations l10n,
}) {
  final listId = task.listId;
  if (listId == null) return l10n.noList;

  final taskList = listsById[listId];
  if (taskList == null) return null;
  final groupId = taskList.groupId;
  final group = groupId == null ? null : groupsById[groupId];
  return group == null ? taskList.name : '${group.name} · ${taskList.name}';
}
