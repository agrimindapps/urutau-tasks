import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/task_providers.dart';
import '../domain/task.dart';
import 'task_detail_page.dart';
import 'task_title_dialog.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({required this.listId, super.key});

  final String listId;

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(taskListsProvider).asData?.value ?? const [];
    String? listName;
    for (final item in lists) {
      if (item.id == widget.listId) {
        listName = item.name;
        break;
      }
    }
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(listName ?? l10n.lists),
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.activeTasks),
                  Tab(text: l10n.completedTasks),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _TasksInList(listId: widget.listId, status: TaskStatus.active),
                _TasksInList(
                  listId: widget.listId,
                  status: TaskStatus.completed,
                ),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: tabs,
              builder: (context, child) => tabs.index == 0
                  ? FloatingActionButton.extended(
                      onPressed: _createTask,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newTask),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createTask() async {
    final l10n = AppLocalizations.of(context);
    final title = await showTaskTitleDialog(
      context,
      title: l10n.newTask,
      fieldLabel: l10n.taskTitle,
      submitLabel: l10n.add,
    );
    if (title == null || !mounted) return;
    await _performListAction(context, () async {
      await ref
          .read(taskRepositoryProvider)
          .createTask(title, listId: widget.listId);
    });
  }
}

class _TasksInList extends ConsumerWidget {
  const _TasksInList({required this.listId, required this.status});

  final String listId;
  final TaskStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(tasksProvider)
        .when(
          loading: () => Center(child: Text(l10n.loading)),
          error: (_, _) => Center(child: Text(l10n.unableToLoadTasks)),
          data: (tasks) {
            final visible = tasks
                .where((task) => task.listId == listId && task.status == status)
                .toList(growable: false);
            if (visible.isEmpty) {
              return Center(
                child: Text(
                  status == TaskStatus.active
                      ? l10n.noActiveTasks
                      : l10n.noCompletedTasks,
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = visible[index];
                return _ListTaskCard(
                  task: task,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => TaskDetailPage(taskId: task.id),
                    ),
                  ),
                  onCompleteChanged: (completed) => _performListAction(
                    context,
                    () => ref
                        .read(taskRepositoryProvider)
                        .setTaskCompleted(task.id, completed),
                  ),
                  onTrash: () => _performListAction(
                    context,
                    () => ref
                        .read(taskRepositoryProvider)
                        .moveTaskToTrash(task.id),
                  ),
                );
              },
            );
          },
        );
  }
}

class _ListTaskCard extends ConsumerWidget {
  const _ListTaskCard({
    required this.task,
    required this.onOpen,
    required this.onCompleteChanged,
    required this.onTrash,
  });

  final Task task;
  final VoidCallback onOpen;
  final ValueChanged<bool> onCompleteChanged;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subtasks = ref.watch(taskSubtasksProvider(task.id));
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: (value) => onCompleteChanged(value ?? false),
        ),
        title: Text(
          task.title,
          style: task.status == TaskStatus.completed
              ? TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                )
              : null,
        ),
        subtitle: subtasks.when(
          data: (steps) => steps.isEmpty
              ? null
              : Text(
                  l10n.taskProgress(
                    steps.where((step) => step.isCompleted).length,
                    steps.length,
                  ),
                ),
          loading: () => null,
          error: (_, _) => null,
        ),
        trailing: IconButton(
          tooltip: l10n.moveToTrash,
          onPressed: onTrash,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

Future<void> _performListAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
    );
  }
}
