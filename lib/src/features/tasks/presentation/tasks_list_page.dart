import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../domain/task.dart';
import 'task_confirm.dart';
import 'task_detail_page.dart';
import 'task_editor_dialog.dart';
import 'task_tile.dart';
import 'task_errors.dart';

/// Lista principal: ativas e concluídas, fora da lixeira (spec 01).
class TasksListPage extends ConsumerWidget {
  const TasksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTasks)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newTaskTooltip,
        onPressed: () => _createTask(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          final active = all
              .where((t) => t.status == TaskStatus.active)
              .toList(growable: false);
          final completed = all
              .where((t) => t.status == TaskStatus.completed)
              .toList(growable: false);
          if (active.isEmpty && completed.isEmpty) {
            return Center(child: Text(l10n.emptyTasks));
          }
          return ListView(
            children: [
              for (final task in active) _tile(context, ref, task),
              if (completed.isNotEmpty) ...[
                const Divider(),
                for (final task in completed) _tile(context, ref, task),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, Task task) {
    return TaskTile(
      task: task,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailPage(taskId: task.id),
        ),
      ),
      onToggle: (checked) => runTaskAction(context, () async {
        final service = ref.read(tasksServiceProvider);
        if (checked ?? false) {
          await service.completeTask(task.id);
        } else {
          await service.reopenTask(task.id);
        }
      }),
      onEdit: () => _editTask(context, ref, task),
      onDelete: () => _confirmDelete(context, ref, task),
    );
  }

  Future<void> _createTask(BuildContext context, WidgetRef ref) async {
    final draft = await TaskEditorDialog.show(context);
    if (draft == null || !context.mounted) return;
    await runTaskAction(context, () async {
      await ref
          .read(tasksServiceProvider)
          .createTask(title: draft.title, notes: draft.notes);
    });
  }

  Future<void> _editTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final confirmed = await confirmDeleteTask(context);
    if (!confirmed || !context.mounted) return;
    await runTaskAction(context, () async {
      await ref.read(tasksServiceProvider).moveToTrash(task.id);
    });
  }
}
