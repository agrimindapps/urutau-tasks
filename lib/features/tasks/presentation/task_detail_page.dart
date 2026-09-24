import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/utc_gregorian_calendar_delegate.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../notifications/application/notification_providers.dart';
import '../../notifications/data/local_notification_service.dart';
import '../../organization/domain/organization.dart';
import '../application/task_providers.dart';
import '../domain/task.dart';
import 'task_title_dialog.dart';

class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final taskValue = ref.watch(taskProvider(taskId));
    final task = taskValue.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetails),
        actions: task == null ? null : _taskActions(context, ref, task),
      ),
      body: taskValue.when(
        loading: () => Center(child: Text(l10n.loading)),
        error: (_, _) => _DetailMessage(message: l10n.unableToLoadTask),
        data: (task) {
          if (task == null) return _DetailMessage(message: l10n.taskNotFound);
          return _TaskDetailContent(task: task);
        },
      ),
    );
  }

  List<Widget> _taskActions(BuildContext context, WidgetRef ref, Task task) {
    final l10n = AppLocalizations.of(context);
    if (task.status == TaskStatus.trashed) {
      return [
        IconButton(
          tooltip: l10n.restore,
          onPressed: () => _perform(context, () async {
            await ref.read(taskRepositoryProvider).restoreTask(task.id);
          }),
          icon: const Icon(Icons.restore),
        ),
      ];
    }
    return [
      IconButton(
        tooltip: l10n.edit,
        onPressed: () => _editTaskTitle(context, ref, task),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: task.status == TaskStatus.completed
            ? l10n.reopenTask
            : l10n.markComplete,
        onPressed: () => _perform(context, () async {
          await ref
              .read(taskRepositoryProvider)
              .setTaskCompleted(task.id, task.status != TaskStatus.completed);
        }),
        icon: Icon(
          task.status == TaskStatus.completed
              ? Icons.restart_alt
              : Icons.check_circle_outline,
        ),
      ),
      IconButton(
        tooltip: l10n.moveToTrash,
        onPressed: () => _perform(context, () async {
          await ref.read(taskRepositoryProvider).moveTaskToTrash(task.id);
        }),
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }

  Future<void> _editTaskTitle(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final title = await showTaskTitleDialog(
      context,
      title: l10n.editTask,
      fieldLabel: l10n.taskTitle,
      submitLabel: l10n.save,
      initialValue: task.title,
    );
    if (title == null || !context.mounted) return;
    await _perform(context, () async {
      await ref.read(taskRepositoryProvider).updateTaskTitle(task.id, title);
    });
  }
}

class _TaskDetailContent extends ConsumerWidget {
  const _TaskDetailContent({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stepsValue = ref.watch(taskSubtasksProvider(task.id));
    final taskCollection = ref.watch(tasksProvider);
    final allTasks = taskCollection.asData?.value;
    final editable = task.status != TaskStatus.trashed;
    final recurrencePositionKnown =
        task.recurringSeriesId == null || allTasks != null;
    final hasLaterOccurrence =
        allTasks?.any(
          (other) =>
              other.id != task.id &&
              other.recurringSeriesId == task.recurringSeriesId &&
              other.createdAtUtc.isAfter(task.createdAtUtc),
        ) ??
        false;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          children: [
            Text(task.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.notes,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (editable)
                          IconButton(
                            tooltip: l10n.editNotes,
                            onPressed: () => _editNotes(context, ref, task),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                      ],
                    ),
                    Text(
                      task.notes?.isNotEmpty == true
                          ? task.notes!
                          : l10n.noNotes,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TaskDateFields(task: task, editable: editable),
            const SizedBox(height: 16),
            _TaskRecurrenceField(
              task: task,
              editable: editable,
              recurrencePositionKnown: recurrencePositionKnown,
              hasLaterOccurrence: hasLaterOccurrence,
              sequenceError: taskCollection.hasError,
            ),
            const SizedBox(height: 16),
            _TaskOrganizationFields(task: task, editable: editable),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.subtasks,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (editable)
                  IconButton.filledTonal(
                    tooltip: l10n.newSubtask,
                    onPressed: () => _addSubtask(context, ref, task.id),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            stepsValue.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.loading),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.unableToLoadTask),
              ),
              data: (steps) {
                if (steps.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.noSubtasks),
                  );
                }
                final completed = steps
                    .where((step) => step.isCompleted)
                    .length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.taskProgress(completed, steps.length)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: completed / steps.length),
                    const SizedBox(height: 12),
                    for (final entry in steps.indexed)
                      _SubtaskTile(
                        subtask: entry.$2,
                        orderIndex: entry.$1,
                        editable: editable,
                        isFirst: entry.$1 == 0,
                        isLast: entry.$1 == steps.length - 1,
                        onChanged: (value) => _perform(context, () async {
                          await ref
                              .read(taskRepositoryProvider)
                              .setSubtaskCompleted(entry.$2.id, value);
                        }),
                        onEdit: () => _editSubtask(context, ref, entry.$2),
                        onMove: (position) => _perform(context, () async {
                          await ref
                              .read(taskRepositoryProvider)
                              .moveSubtask(task.id, entry.$2.id, position);
                        }),
                        onRemove: () =>
                            _confirmRemoveSubtask(context, ref, entry.$2),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSubtask(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final title = await showTaskTitleDialog(
      context,
      title: l10n.newSubtask,
      fieldLabel: l10n.subtaskTitle,
      submitLabel: l10n.add,
    );
    if (title == null || !context.mounted) return;
    await _perform(context, () async {
      await ref.read(taskRepositoryProvider).addSubtask(taskId, title);
    });
  }

  Future<void> _editNotes(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: task.notes ?? '');
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editNotes),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.notes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || !context.mounted) return;
    await _perform(context, () async {
      await ref.read(taskRepositoryProvider).updateTaskNotes(task.id, notes);
    });
  }

  Future<void> _editSubtask(
    BuildContext context,
    WidgetRef ref,
    Subtask subtask,
  ) async {
    final l10n = AppLocalizations.of(context);
    final title = await showTaskTitleDialog(
      context,
      title: l10n.editSubtask,
      fieldLabel: l10n.subtaskTitle,
      submitLabel: l10n.save,
      initialValue: subtask.title,
    );
    if (title == null || !context.mounted) return;
    await _perform(context, () async {
      await ref
          .read(taskRepositoryProvider)
          .updateSubtaskTitle(subtask.id, title);
    });
  }

  Future<void> _confirmRemoveSubtask(
    BuildContext context,
    WidgetRef ref,
    Subtask subtask,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeSubtask),
        content: Text(l10n.removeSubtaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _perform(context, () async {
      await ref.read(taskRepositoryProvider).removeSubtask(subtask.id);
    });
  }
}

class _TaskOrganizationFields extends ConsumerWidget {
  const _TaskOrganizationFields({required this.task, required this.editable});

  final Task task;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listsValue = ref.watch(taskListsProvider);
    final categoriesValue = ref.watch(taskCategoriesProvider);
    final tagsValue = ref.watch(taskTagsProvider);
    final assignedTagsValue = ref.watch(taskTagAssignmentsProvider(task.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.priority, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              initialValue: task.priority,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: TaskPriority.none,
                  child: Text(l10n.noPriority),
                ),
                DropdownMenuItem(
                  value: TaskPriority.low,
                  child: Text(l10n.priorityLow),
                ),
                DropdownMenuItem(
                  value: TaskPriority.medium,
                  child: Text(l10n.priorityMedium),
                ),
                DropdownMenuItem(
                  value: TaskPriority.high,
                  child: Text(l10n.priorityHigh),
                ),
                DropdownMenuItem(
                  value: TaskPriority.urgent,
                  child: Text(l10n.priorityUrgent),
                ),
              ],
              onChanged: editable
                  ? (priority) {
                      if (priority == null || priority == task.priority) return;
                      _perform(context, () async {
                        await ref
                            .read(taskRepositoryProvider)
                            .updateTaskPriority(task.id, priority);
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            Text(l10n.taskList, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            listsValue.when(
              loading: () => Text(l10n.loading),
              error: (_, _) => Text(l10n.unableToLoadTasks),
              data: (lists) => DropdownButtonFormField<String?>(
                initialValue: task.listId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.taskList),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.noList),
                  ),
                  for (final list in lists)
                    DropdownMenuItem<String?>(
                      value: list.id,
                      child: Text(list.name),
                    ),
                ],
                onChanged: !editable
                    ? null
                    : (listId) {
                        if (listId == task.listId) return;
                        _perform(context, () async {
                          await ref
                              .read(organizationRepositoryProvider)
                              .moveTaskToList(task.id, listId);
                        });
                      },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.taskCategory,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (editable)
                  IconButton(
                    tooltip: l10n.newCategory,
                    onPressed: () => _createCategory(context, ref),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            categoriesValue.when(
              loading: () => Text(l10n.loading),
              error: (_, _) => Text(l10n.unableToLoadTasks),
              data: (categories) => DropdownButtonFormField<String?>(
                initialValue: task.categoryId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.taskCategory),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.noCategory),
                  ),
                  for (final category in categories)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: !editable
                    ? null
                    : (categoryId) {
                        if (categoryId == task.categoryId) return;
                        _perform(context, () async {
                          await ref
                              .read(organizationRepositoryProvider)
                              .setTaskCategory(task.id, categoryId);
                        });
                      },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.taskTags,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (editable)
                  IconButton(
                    tooltip: l10n.newTag,
                    onPressed: () => _createTag(context, ref),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            tagsValue.when(
              loading: () => Text(l10n.loading),
              error: (_, _) => Text(l10n.unableToLoadTasks),
              data: (tags) => assignedTagsValue.when(
                loading: () => Text(l10n.loading),
                error: (_, _) => Text(l10n.unableToLoadTasks),
                data: (assigned) {
                  if (tags.isEmpty) return Text(l10n.noTags);
                  final assignedIds = assigned.map((tag) => tag.id).toSet();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in tags)
                        FilterChip(
                          label: Text(tag.name),
                          selected: assignedIds.contains(tag.id),
                          onSelected: !editable
                              ? null
                              : (selected) => _perform(context, () async {
                                  await ref
                                      .read(organizationRepositoryProvider)
                                      .setTaskTag(task.id, tag.id, selected);
                                }),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCategory(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTaskTitleDialog(
      context,
      title: l10n.newCategory,
      fieldLabel: l10n.categoryName,
      submitLabel: l10n.add,
    );
    if (name == null || !context.mounted) return;
    await _perform(context, () async {
      final repository = ref.read(organizationRepositoryProvider);
      await repository.createCategoryAndAssignTask(task.id, name);
    });
  }

  Future<void> _createTag(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTaskTitleDialog(
      context,
      title: l10n.newTag,
      fieldLabel: l10n.tagName,
      submitLabel: l10n.add,
    );
    if (name == null || !context.mounted) return;
    await _perform(context, () async {
      await ref
          .read(organizationRepositoryProvider)
          .createOrGetTagAndAssignTask(task.id, name);
    });
  }
}

class _TaskDateFields extends ConsumerWidget {
  const _TaskDateFields({required this.task, required this.editable});

  final Task task;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reminderStatus = ref.watch(reminderDeliveryStatusProvider(task.id));
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale
        .toString();
    final dueDate = task.dueDateIso == null
        ? null
        : parseDateOnly(task.dueDateIso!);
    final reminderLocal = task.reminderAtUtc?.toLocal();
    final showReminderStatus =
        reminderLocal != null ||
        reminderStatus.asData?.value ==
            ReminderDeliveryStatus.cancellationPending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dueDate, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dueDate == null
                        ? l10n.noDueDate
                        : DateFormat.yMMMd(deviceLocale).format(dueDate),
                  ),
                ),
                if (editable)
                  IconButton(
                    tooltip: l10n.chooseDueDate,
                    onPressed: () => _chooseDueDate(context, ref),
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                if (editable && dueDate != null && !task.recurrenceActive)
                  IconButton(
                    tooltip: l10n.removeDueDate,
                    onPressed: () => _perform(context, () async {
                      await ref
                          .read(taskRepositoryProvider)
                          .updateTaskDueDate(task.id, null);
                    }),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            const Divider(height: 24),
            Text(l10n.reminder, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    reminderLocal == null
                        ? l10n.noReminder
                        : DateFormat.yMMMd(deviceLocale)
                              .add_jm()
                              .format(reminderLocal),
                  ),
                ),
                if (editable)
                  IconButton(
                    tooltip: l10n.chooseReminder,
                    onPressed: () => _chooseReminder(context, ref),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                if (editable && reminderLocal != null)
                  IconButton(
                    tooltip: l10n.removeReminder,
                    onPressed: () => _perform(context, () async {
                      await ref
                          .read(taskRepositoryProvider)
                          .updateTaskReminder(task.id, null);
                    }),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            if (showReminderStatus) ...[
              const SizedBox(height: 8),
              reminderStatus.when(
                loading: () => Text(l10n.reminderPending),
                error: (_, _) => Text(l10n.reminderPending),
                data: (status) => _reminderDeliveryStatus(
                  context,
                  ref,
                  l10n,
                  status,
                  task.status,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _chooseDueDate(BuildContext context, WidgetRef ref) async {
    final initialDate = task.dueDateIso == null
        ? DateTime.now()
        : parseDateOnly(task.dueDateIso!);
    final initialDateOnly = DateTime.utc(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    final defaultFirstDate = DateTime.utc(1900);
    final defaultLastDate = DateTime.utc(2200, 12, 31);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDateOnly,
      firstDate: initialDateOnly.isBefore(defaultFirstDate)
          ? initialDateOnly
          : defaultFirstDate,
      lastDate: initialDateOnly.isAfter(defaultLastDate)
          ? initialDateOnly
          : defaultLastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      calendarDelegate: const UtcGregorianCalendarDelegate(),
    );
    if (selected == null || !context.mounted) return;
    await _perform(context, () async {
      await ref
          .read(taskRepositoryProvider)
          .updateTaskDueDate(task.id, formatDateOnly(selected));
    });
  }

  Future<void> _chooseReminder(BuildContext context, WidgetRef ref) async {
    final notifications = ref.read(localNotificationServiceProvider);
    if (!context.mounted) return;
    if (kIsWeb) {
      await _explainAndRequestNotificationPermission(context, notifications);
    }
    if (!context.mounted) return;

    final current = task.reminderAtUtc?.toLocal();
    final nextMinute = DateTime.now().add(const Duration(minutes: 1));
    final initialDate = current ?? nextMinute;
    final initialDateOnly = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    final defaultFirstDate = DateTime(1900);
    final defaultLastDate = DateTime(2200, 12, 31);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDateOnly,
      firstDate: initialDateOnly.isBefore(defaultFirstDate)
          ? initialDateOnly
          : defaultFirstDate,
      lastDate: initialDateOnly.isAfter(defaultLastDate)
          ? initialDateOnly
          : defaultLastDate,
    );
    if (date == null || !context.mounted) return;
    final initialTime = current == null
        ? TimeOfDay.fromDateTime(nextMinute)
        : TimeOfDay.fromDateTime(current);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time == null || !context.mounted) return;
    final localReminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!localReminder.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reminderInPast)),
      );
      return;
    }
    var saved = false;
    await _perform(context, () async {
      await ref
          .read(taskRepositoryProvider)
          .updateTaskReminder(task.id, localReminder.toUtc());
      saved = true;
    });
    if (!saved || !context.mounted) return;
    if (!kIsWeb) {
      await _explainAndRequestNotificationPermission(context, notifications);
    }
  }

  Future<void> _explainAndRequestNotificationPermission(
    BuildContext context,
    LocalNotificationService notifications,
  ) async {
    if (!await notifications.shouldExplainPermissionPrompt() ||
        !context.mounted) {
      return;
    }
    Future<void>? permissionRequest;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.reminder),
          content: Text(l10n.reminderPermissionRationale),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.notNow),
            ),
            FilledButton(
              onPressed: () {
                // On Web this call must begin in this button's user gesture.
                permissionRequest = notifications.requestPermissionFromUser();
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.continueLabel),
            ),
          ],
        );
      },
    );
    if (shouldRequest == true && permissionRequest != null) {
      await permissionRequest;
    }
  }

  Widget _reminderDeliveryStatus(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ReminderDeliveryStatus status,
    TaskStatus taskStatus,
  ) {
    final message = switch (status) {
      ReminderDeliveryStatus.noReminder => null,
      ReminderDeliveryStatus.pendingVerification => l10n.reminderPending,
      ReminderDeliveryStatus.cancellationPending =>
        l10n.reminderCancellationPending,
      ReminderDeliveryStatus.scheduled => l10n.reminderDeliveryScheduled,
      ReminderDeliveryStatus.permissionRequired =>
        l10n.reminderPermissionNeeded,
      ReminderDeliveryStatus.unavailable => l10n.reminderUnavailable,
      ReminderDeliveryStatus.expired => l10n.reminderExpired,
      ReminderDeliveryStatus.paused => l10n.reminderPaused,
    };
    if (message == null) return const SizedBox.shrink();
    final inactive = taskStatus != TaskStatus.active;
    final color =
        status == ReminderDeliveryStatus.permissionRequired ||
            status == ReminderDeliveryStatus.unavailable ||
            status == ReminderDeliveryStatus.cancellationPending
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: color)),
        if (!inactive &&
            status == ReminderDeliveryStatus.permissionRequired) ...[
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.webNotificationSettingsHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => ref
                  .read(localNotificationServiceProvider)
                  .openPermissionSettings(),
              icon: Icon(kIsWeb ? Icons.refresh : Icons.settings_outlined),
              label: Text(
                kIsWeb
                    ? l10n.checkNotificationPermission
                    : l10n.openNotificationSettings,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskRecurrenceField extends ConsumerWidget {
  const _TaskRecurrenceField({
    required this.task,
    required this.editable,
    required this.recurrencePositionKnown,
    required this.hasLaterOccurrence,
    required this.sequenceError,
  });

  final Task task;
  final bool editable;
  final bool recurrencePositionKnown;
  final bool hasLaterOccurrence;
  final bool sequenceError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canEdit =
        editable &&
        task.status == TaskStatus.active &&
        recurrencePositionKnown &&
        !hasLaterOccurrence;
    final selectedFrequency = task.recurrenceActive
        ? task.recurrenceFrequency
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.recurrence,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RecurrenceFrequency?>(
              initialValue: selectedFrequency,
              isExpanded: true,
              items: [
                DropdownMenuItem<RecurrenceFrequency?>(
                  value: null,
                  child: Text(l10n.noRecurrence),
                ),
                for (final frequency in RecurrenceFrequency.values)
                  DropdownMenuItem<RecurrenceFrequency?>(
                    value: frequency,
                    child: Text(_recurrenceLabel(frequency, l10n)),
                  ),
              ],
              onChanged: canEdit
                  ? (frequency) => _perform(context, () async {
                      await ref
                          .read(taskRepositoryProvider)
                          .updateTaskRecurrence(task.id, frequency);
                    })
                  : null,
            ),
            if (task.recurringSeriesId != null && !task.recurrenceActive) ...[
              const SizedBox(height: 8),
              Text(l10n.recurrenceCancelled),
            ],
            if (task.recurringSeriesId != null && !recurrencePositionKnown) ...[
              const SizedBox(height: 8),
              Text(sequenceError ? l10n.unableToLoadTasks : l10n.loading),
            ],
            if (hasLaterOccurrence) ...[
              const SizedBox(height: 8),
              Text(l10n.recurrenceHistoryReadOnly),
            ],
            if (task.dueDateIso == null && !task.recurrenceActive) ...[
              const SizedBox(height: 8),
              Text(
                l10n.recurrenceNeedsDueDate,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (canEdit) ...[
              const SizedBox(height: 8),
              Text(
                l10n.recurrenceHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _recurrenceLabel(
    RecurrenceFrequency frequency,
    AppLocalizations l10n,
  ) => switch (frequency) {
    RecurrenceFrequency.daily => l10n.recurrenceDaily,
    RecurrenceFrequency.weekdays => l10n.recurrenceWeekdays,
    RecurrenceFrequency.weekly => l10n.recurrenceWeekly,
    RecurrenceFrequency.monthly => l10n.recurrenceMonthly,
    RecurrenceFrequency.yearly => l10n.recurrenceYearly,
  };
}

class _SubtaskTile extends StatelessWidget {
  const _SubtaskTile({
    required this.subtask,
    required this.orderIndex,
    required this.editable,
    required this.isFirst,
    required this.isLast,
    required this.onChanged,
    required this.onEdit,
    required this.onMove,
    required this.onRemove,
  });

  final Subtask subtask;
  final int orderIndex;
  final bool editable;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: subtask.isCompleted,
          onChanged: editable ? (value) => onChanged(value ?? false) : null,
        ),
        title: Text(
          subtask.title,
          style: subtask.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        trailing: editable
            ? PopupMenuButton<_SubtaskAction>(
                tooltip: l10n.edit,
                onSelected: (action) {
                  switch (action) {
                    case _SubtaskAction.edit:
                      onEdit();
                    case _SubtaskAction.moveUp:
                      onMove(orderIndex - 1);
                    case _SubtaskAction.moveDown:
                      onMove(orderIndex + 1);
                    case _SubtaskAction.remove:
                      onRemove();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _SubtaskAction.moveUp,
                    enabled: !isFirst,
                    child: Text(l10n.moveUp),
                  ),
                  PopupMenuItem(
                    value: _SubtaskAction.moveDown,
                    enabled: !isLast,
                    child: Text(l10n.moveDown),
                  ),
                  PopupMenuItem(
                    value: _SubtaskAction.edit,
                    child: Text(l10n.edit),
                  ),
                  PopupMenuItem(
                    value: _SubtaskAction.remove,
                    child: Text(l10n.removeSubtask),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

enum _SubtaskAction { edit, moveUp, moveDown, remove }

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

Future<void> _perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final errorMessage = switch (error) {
      DuplicateOrganizationNameException() => l10n.duplicateName,
      InvalidOrganizationNameException() => l10n.taskTitleRequired,
      ReminderMustBeFutureException() => l10n.reminderInPast,
      TaskRecurrenceRequiresDueDateException() => l10n.recurrenceNeedsDueDate,
      TaskRecurrenceHistoryException() => l10n.recurrenceHistoryReadOnly,
      _ => l10n.actionFailed,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage)));
  }
}
