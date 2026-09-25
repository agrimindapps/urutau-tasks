import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../domain/task.dart';

/// Item de tarefa com conclusão, progresso de etapas e ações.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.onAddToMyDay,
  });

  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onAddToMyDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final completed = task.status == TaskStatus.completed;

    return ListTile(
      key: ValueKey(task.id),
      onTap: onTap,
      leading: task.isTrashed
          ? const Icon(Icons.delete_outline)
          : Checkbox(
              value: completed,
              onChanged: onToggle,
            ),
      title: Text(
        task.title,
        style: completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.notes.isNotEmpty)
            Text(
              task.notes,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (task.subtaskCount > 0)
            Text(
              l10n.progressOf(task.completedSubtaskCount, task.subtaskCount),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      trailing: task.isTrashed
          ? IconButton(
              tooltip: l10n.restore,
              icon: const Icon(Icons.restore),
              onPressed: onRestore,
            )
          : PopupMenuButton<_TaskAction>(
              onSelected: (action) {
                switch (action) {
                  case _TaskAction.edit:
                    onEdit?.call();
                  case _TaskAction.addToMyDay:
                    onAddToMyDay?.call();
                  case _TaskAction.delete:
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _TaskAction.edit,
                  child: Text(l10n.editTaskTitle),
                ),
                if (onAddToMyDay != null)
                  PopupMenuItem(
                    value: _TaskAction.addToMyDay,
                    child: Text(l10n.addToMyDay),
                  ),
                PopupMenuItem(
                  value: _TaskAction.delete,
                  child: Text(l10n.delete),
                ),
              ],
            ),
    );
  }
}

enum _TaskAction { edit, addToMyDay, delete }
