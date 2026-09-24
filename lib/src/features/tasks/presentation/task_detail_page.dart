import 'package:flutter/material.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../organization/domain/organization.dart';
import '../application/tasks_service.dart';
import '../domain/task.dart';
import 'task_editor_dialog.dart';

/// Detalhe da tarefa: título, notas, conclusão e subtarefas
/// (spec 01, RF-03 a RF-08).
class TaskDetailPage extends ConsumerStatefulWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  final _subtaskController = TextEditingController();

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taskAsync = ref.watch(taskProvider(widget.taskId));
    return taskAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (task) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.emptyTasks)),
          );
        }
        final service = ref.read(tasksServiceProvider);
        final readOnly = task.isDeleted;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.taskDetail),
            actions: [
              if (!readOnly) ...[
                IconButton(
                  tooltip:
                      task.isCompleted ? l10n.markIncomplete : l10n.markComplete,
                  icon: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                  ),
                  onPressed: () => service.toggleCompletion(task.id),
                ),
                IconButton(
                  tooltip: l10n.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      showTaskEditorDialog(context, task: task),
                ),
                IconButton(
                  tooltip: l10n.moveToTrash,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await service.moveToTrash(task.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ] else
                IconButton(
                  tooltip: l10n.restore,
                  icon: const Icon(Icons.restore),
                  onPressed: () => service.restoreFromTrash(task.id),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (readOnly)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.trashBanner)),
                      ],
                    ),
                  ),
                ),
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
              ),
              if (task.notes != null && task.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.notes!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              _OrganizationSummary(task: task),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    l10n.subtasksSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (task.progress != null)
                    Text(
                      formatProgress(task.progress!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (task.subtasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.addSubtask,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorderItem: (oldIndex, newIndex) =>
                      service.moveSubtask(task.id, oldIndex, newIndex),
                  children: [
                    for (final subtask in task.subtasks)
                      ListTile(
                        key: ValueKey(subtask.id),
                        dense: true,
                        leading: readOnly
                            ? Icon(
                                subtask.isCompleted
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                              )
                            : Checkbox(
                                value: subtask.isCompleted,
                                onChanged: (_) => service
                                    .toggleSubtaskCompletion(
                                  task.id,
                                  subtask.id,
                                ),
                              ),
                        title: Text(
                          subtask.title,
                          style: subtask.isCompleted
                              ? const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                )
                              : null,
                        ),
                        trailing: readOnly
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: l10n.edit,
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    onPressed: () => _editSubtask(
                                      task,
                                      subtask,
                                      service,
                                      l10n,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.delete,
                                    icon: const Icon(Icons.close,
                                        size: 20),
                                    onPressed: () => service.removeSubtask(
                                      task.id,
                                      subtask.id,
                                    ),
                                  ),
                                  const Icon(Icons.drag_indicator, size: 20),
                                ],
                              ),
                      ),
                  ],
                ),
              if (!readOnly) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: InputDecoration(
                          hintText: l10n.subtaskTitleHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSubtask(service),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: l10n.addSubtask,
                      icon: const Icon(Icons.add),
                      onPressed: () => _addSubtask(service),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _addSubtask(TasksService service) {
    final title = _subtaskController.text;
    if (title.trim().isEmpty) return;
    service.addSubtask(widget.taskId, title: title);
    _subtaskController.clear();
  }

  Future<void> _editSubtask(
    Task task,
    Subtask subtask,
    TasksService service,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController(text: subtask.title);
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.edit),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.taskTitleLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (updated == true) {
      try {
        await service.editSubtask(
          task.id,
          subtask.id,
          title: controller.text,
        );
      } on InvalidTitleException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.titleRequired)),
          );
        }
      }
    }
    controller.dispose();
  }
}

class _OrganizationSummary extends ConsumerWidget {
  const _OrganizationSummary({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];

    String? listName;
    for (final list in lists) {
      if (list.id == task.listId) listName = list.name;
    }
    String? categoryName;
    for (final category in categories) {
      if (category.id == task.categoryId) categoryName = category.name;
    }

    final parts = [
      '${l10n.listLabel}: ${listName ?? l10n.noList}',
      '${l10n.categoryLabel}: ${categoryName ?? l10n.noCategory}',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parts.join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (task.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in task.tags)
                    Chip(
                      label: Text(tag.name),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
