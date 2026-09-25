import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../my_day/domain/my_day.dart';
import '../../recurrence/domain/recurrence.dart';
import '../../organization/domain/organization_repository.dart';
import '../domain/task.dart';
import 'task_confirm.dart';
import 'task_editor_dialog.dart';
import 'task_errors.dart';

/// Detalhe da tarefa: dados, etapas, progresso e ações do ciclo
/// (spec 01, RF-03 a RF-10).
class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(tasksProvider);

    return tasks.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (all) {
        final task = all.where((t) => t.id == taskId).firstOrNull;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.emptyTasks)),
          );
        }
        return _TaskDetailBody(task: task);
      },
    );
  }
}

class _TaskDetailBody extends ConsumerWidget {
  const _TaskDetailBody({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trashed = task.isTrashed;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetailTitle),
        actions: [
          if (trashed)
            IconButton(
              tooltip: l10n.restore,
              icon: const Icon(Icons.restore),
              onPressed: () => runTaskAction(context, () async {
                await ref.read(tasksServiceProvider).restore(task.id);
                if (context.mounted) Navigator.of(context).pop();
              }),
            )
          else ...[
            IconButton(
              tooltip: l10n.editTaskTitle,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, ref),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await confirmDeleteTask(context);
                if (!confirmed || !context.mounted) return;
                await runTaskAction(context, () async {
                  await ref.read(tasksServiceProvider).moveToTrash(task.id);
                  if (context.mounted) Navigator.of(context).pop();
                });
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (trashed)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.trashSubtitle),
              ),
            ),
          Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
          if (task.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(task.notes),
          ],
          const SizedBox(height: 16),
          if (!trashed)
            CheckboxListTile(
              value: task.status == TaskStatus.completed,
              title: Text(
                task.status == TaskStatus.completed
                    ? l10n.reopen
                    : l10n.complete,
              ),
              onChanged: (checked) => runTaskAction(context, () async {
                final service = ref.read(tasksServiceProvider);
                if (checked ?? false) {
                  await service.completeTask(task.id);
                } else {
                  await service.reopenTask(task.id);
                }
              }),
            ),
          const Divider(),
          _ScheduleSection(task: task),
          const Divider(),
          _OrganizationSection(task: task),
          const Divider(),
            _SubtasksSection(task: task),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final draft = await TaskEditorDialog.show(
      context,
      initialTitle: task.title,
      initialNotes: task.notes,
      isEditing: true,
    );
    if (draft == null || !context.mounted) return;
    await runTaskAction(context, () async {
      await ref.read(tasksServiceProvider).renameTask(
            task.id,
            title: draft.title,
            notes: draft.notes,
          );
    });
  }
}

class _SubtasksSection extends ConsumerStatefulWidget {
  const _SubtasksSection({required this.task});

  final Task task;

  @override
  ConsumerState<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends ConsumerState<_SubtasksSection> {
  final _newSubtaskController = TextEditingController();

  @override
  void dispose() {
    _newSubtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final task = widget.task;
    final trashed = task.isTrashed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.subtasksSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 12),
            if (task.subtaskCount > 0)
              Text(
                l10n.progressOf(
                  task.completedSubtaskCount,
                  task.subtaskCount,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (task.subtaskCount > 0)
          LinearProgressIndicator(
            value: task.progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        if (task.subtasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.emptySubtasks),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: !trashed,
            itemCount: task.subtasks.length,
            onReorderItem: (oldIndex, newIndex) {
              if (trashed) return;
              final ids = [
                for (final s in task.subtasks) s.id,
              ];
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              runTaskAction(context, () async {
                await ref
                    .read(tasksServiceProvider)
                    .reorderSubtasks(task.id, ids);
              });
            },
            itemBuilder: (context, index) {
              final subtask = task.subtasks[index];
              return ListTile(
                key: ValueKey(subtask.id),
                leading: Checkbox(
                  value: subtask.isCompleted,
                  onChanged: trashed
                      ? null
                      : (checked) => runTaskAction(context, () async {
                            await ref
                                .read(tasksServiceProvider)
                                .setSubtaskCompleted(
                                  task.id,
                                  subtask.id,
                                  completed: checked ?? false,
                                );
                          }),
                ),
                title: Text(
                  subtask.description,
                  style: subtask.isCompleted
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                onTap: trashed
                    ? null
                    : () => _renameSubtask(context, ref, subtask),
                trailing: trashed
                    ? null
                    : IconButton(
                        tooltip: l10n.removeSubtaskTooltip,
                        icon: const Icon(Icons.close),
                        onPressed: () => runTaskAction(context, () async {
                          await ref
                              .read(tasksServiceProvider)
                              .removeSubtask(task.id, subtask.id);
                        }),
                      ),
              );
            },
          ),
        if (!trashed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('subtask-field'),
                    controller: _newSubtaskController,
                    decoration: InputDecoration(hintText: l10n.subtaskHint),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(
                  tooltip: l10n.addSubtaskTooltip,
                  icon: const Icon(Icons.add),
                  onPressed: _addSubtask,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _addSubtask() async {
    final description = _newSubtaskController.text.trim();
    if (description.isEmpty) return;
    _newSubtaskController.clear();
    await runTaskAction(context, () async {
      await ref
          .read(tasksServiceProvider)
          .addSubtask(widget.task.id, description: description);
    });
  }

  Future<void> _renameSubtask(
    BuildContext context,
    WidgetRef ref,
    Subtask subtask,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SubtaskRenameDialog(initial: subtask.description),
    );
    if (result == null || !context.mounted) return;
    await runTaskAction(context, () async {
      await ref.read(tasksServiceProvider).renameSubtask(
            widget.task.id,
            subtask.id,
            description: result,
          );
    });
  }
}

class _SubtaskRenameDialog extends StatefulWidget {
  const _SubtaskRenameDialog({required this.initial});

  final String initial;

  @override
  State<_SubtaskRenameDialog> createState() => _SubtaskRenameDialogState();
}

class _SubtaskRenameDialogState extends State<_SubtaskRenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.subtasksSection),
      content: TextField(
        key: const Key('subtask-title-field'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.subtaskHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Seção de prioridade, prazo, lembrete e recorrência
/// (escopo MVP 3.3; spec 04, RF-01 a RF-13).
class _ScheduleSection extends ConsumerWidget {
  const _ScheduleSection({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trashed = task.isTrashed;
    final service = ref.read(tasksServiceProvider);
    final recurrence = ref.watch(recurrenceServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<TaskPriority?>(
          key: ValueKey('priority-picker-${task.id}'),
          initialValue: task.priority,
          decoration: InputDecoration(labelText: l10n.priorityLabel),
          items: [
            DropdownMenuItem<TaskPriority?>(
              value: null,
              child: Text(l10n.priorityNone),
            ),
            for (final priority in TaskPriority.values)
              DropdownMenuItem<TaskPriority?>(
                value: priority,
                child: Text(_priorityLabel(l10n, priority)),
              ),
          ],
          onChanged: trashed
              ? null
              : (value) => runTaskAction(context, () async {
                    await service.setPriority(task.id, value);
                  }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                task.dueDate == null
                    ? l10n.noDueDate
                    : '${l10n.dueDateLabel}: ${task.dueDate}',
              ),
            ),
            TextButton(
              key: const Key('due-date-button'),
              onPressed: trashed
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: task.dueDate == null
                            ? DateTime.now()
                            : DateTime.parse(task.dueDate!),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked == null || !context.mounted) return;
                      await runTaskAction(context, () async {
                        await service.setDueDate(task.id, localDateKey(picked));
                      });
                    },
              child: Text(l10n.dueDateLabel),
            ),
            if (task.dueDate != null)
              IconButton(
                tooltip: l10n.clearDueDate,
                icon: const Icon(Icons.event_busy),
                onPressed: trashed
                    ? null
                    : () => runTaskAction(context, () async {
                          await service.setDueDate(task.id, null);
                        }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                task.reminder == null
                    ? l10n.noReminder
                    : '${l10n.reminderLabel}: ${_formatReminder(task.reminder!)}',
              ),
            ),
            TextButton(
              key: const Key('reminder-button'),
              onPressed: trashed
                  ? null
                  : () async {
                      final reminder =
                          await _pickReminder(context, task.reminder);
                      if (reminder == null || !context.mounted) return;
                      await runTaskAction(context, () async {
                        await service.setReminder(task.id, reminder);
                      });
                    },
              child: Text(l10n.setReminder),
            ),
            if (task.reminder != null)
              IconButton(
                tooltip: l10n.clearReminder,
                icon: const Icon(Icons.notifications_off_outlined),
                onPressed: trashed
                    ? null
                    : () => runTaskAction(context, () async {
                          await service.setReminder(task.id, null);
                        }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<RecurringSeries?>(
          future: task.seriesId == null
              ? Future<RecurringSeries?>.value(null)
              : recurrence.fetchSeries(task.seriesId!),
          builder: (context, snapshot) {
            final series = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<RecurrenceFrequency?>(
                  key: ValueKey('recurrence-picker-${task.id}'),
                  initialValue: series?.frequency,
                  decoration: InputDecoration(labelText: l10n.recurrenceLabel),
                  items: [
                    DropdownMenuItem<RecurrenceFrequency?>(
                      value: null,
                      child: Text(l10n.noRecurrence),
                    ),
                    for (final frequency in RecurrenceFrequency.values)
                      DropdownMenuItem<RecurrenceFrequency?>(
                        value: frequency,
                        child: Text(_frequencyLabel(l10n, frequency)),
                      ),
                  ],
                  onChanged: trashed
                      ? null
                      : (value) => runTaskAction(context, () async {
                            if (value == null) return;
                            if (task.seriesId == null) {
                              await ref
                                  .read(recurrenceServiceProvider)
                                  .createSeries(
                                    task.id,
                                    frequency: value,
                                  );
                            } else {
                              await ref
                                  .read(recurrenceServiceProvider)
                                  .changeFrequency(
                                    task.seriesId!,
                                    frequency: value,
                                  );
                            }
                          }),
                ),
                if (series != null && series.cancelled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.seriesCancelledNote),
                  ),
                if (series != null && !series.cancelled)
                  TextButton(
                    key: const Key('cancel-series-button'),
                    onPressed: () async {
                      final confirmed = await _confirmCancelSeries(context);
                      if (!confirmed || !context.mounted) return;
                      await runTaskAction(context, () async {
                        await ref
                            .read(recurrenceServiceProvider)
                            .cancelSeries(series.id);
                      });
                    },
                    child: Text(l10n.cancelSeries),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatReminder(DateTime instant) {
    final local = instant.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<DateTime?> _pickReminder(
    BuildContext context,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final initialDate = current?.toLocal() ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute)
        .toUtc();
  }

  Future<bool> _confirmCancelSeries(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelSeriesTitle),
        content: Text(l10n.cancelSeriesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cancelSeries),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _priorityLabel(AppLocalizations l10n, TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => l10n.priorityLow,
      TaskPriority.medium => l10n.priorityMedium,
      TaskPriority.high => l10n.priorityHigh,
      TaskPriority.urgent => l10n.priorityUrgent,
    };
  }

  String _frequencyLabel(
    AppLocalizations l10n,
    RecurrenceFrequency frequency,
  ) {
    return switch (frequency) {
      RecurrenceFrequency.daily => l10n.freqDaily,
      RecurrenceFrequency.weekdays => l10n.freqWeekdays,
      RecurrenceFrequency.weekly => l10n.freqWeekly,
      RecurrenceFrequency.monthly => l10n.freqMonthly,
      RecurrenceFrequency.annual => l10n.freqAnnual,
    };
  }
}

/// Seção de organização: lista, categoria e tags (spec 02, RF-03/RF-08/RF-09).
class _OrganizationSection extends ConsumerStatefulWidget {
  const _OrganizationSection({required this.task});

  final Task task;

  @override
  ConsumerState<_OrganizationSection> createState() =>
      _OrganizationSectionState();
}

class _OrganizationSectionState extends ConsumerState<_OrganizationSection> {
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Task get task => widget.task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final organization = ref.watch(organizationProvider);
    final trashed = task.isTrashed;

    return organization.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (snapshot) {
        final service = ref.read(organizationServiceProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.organizationSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              key: ValueKey('list-picker-${task.id}'),
              initialValue: task.listId,
              decoration: InputDecoration(labelText: l10n.listLabel),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.semLista),
                ),
                for (final list in snapshot.lists)
                  DropdownMenuItem<String?>(
                    value: list.id,
                    child: Text(list.name),
                  ),
              ],
              onChanged: trashed
                  ? null
                  : (value) => runTaskAction(context, () async {
                        await service.assignListToTask(task.id, value);
                      }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey('category-picker-${task.id}'),
              initialValue: task.categoryId,
              decoration: InputDecoration(labelText: l10n.categoryLabel),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.noCategory),
                ),
                for (final category in snapshot.categories)
                  DropdownMenuItem<String?>(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: trashed
                  ? null
                  : (value) => runTaskAction(context, () async {
                        await service.assignCategoryToTask(task.id, value);
                      }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tagId in task.tagIds)
                  Chip(
                    key: ValueKey('tag-chip-$tagId'),
                    label: Text(_tagName(snapshot, tagId)),
                    deleteButtonTooltipMessage: l10n.removeTagTooltip,
                    onDeleted: trashed
                        ? null
                        : () => runTaskAction(context, () async {
                              await service.removeTagFromTask(task.id, tagId);
                            }),
                  ),
              ],
            ),
            if (!trashed)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('tag-input'),
                      controller: _tagController,
                      decoration: InputDecoration(hintText: l10n.tagHint),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addTag(context),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.addTagTooltip,
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(context),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  String _tagName(OrganizationSnapshot snapshot, String tagId) {
    for (final tag in snapshot.tags) {
      if (tag.id == tagId) return tag.name;
    }
    return tagId;
  }

  Future<void> _addTag(BuildContext context) async {
    final name = _tagController.text.trim();
    if (name.isEmpty) return;
    _tagController.clear();
    await runTaskAction(context, () async {
      await ref
          .read(organizationServiceProvider)
          .addTagToTaskByName(task.id, name);
    });
  }
}
