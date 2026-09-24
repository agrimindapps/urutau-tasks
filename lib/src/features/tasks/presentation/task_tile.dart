import 'package:flutter/material.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import 'task_editor_dialog.dart';
import '../domain/task.dart';

/// Ação de My Day exibida no menu da tarefa (spec 03, RF-06/RF-08).
enum MyDayAction { addToMyDay, removeFromMyDay }

class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.myDayAction,
  });

  final Task task;
  final VoidCallback? onTap;
  final MyDayAction? myDayAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progress = task.progress;
    final lists = ref.watch(listsProvider).value ?? const [];
    String? listName;
    for (final list in lists) {
      if (list.id == task.listId) listName = list.name;
    }
    final subtitleParts = [
      ?listName,
      if (progress != null)
        '${l10n.progressLabel}: ${formatProgress(progress)}',
    ];

    return ListTile(
      key: key,
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) =>
            ref.read(tasksServiceProvider).toggleCompletion(task.id),
      ),
      title: Text(
        task.title,
        style: task.isCompleted
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      trailing: PopupMenuButton<String>(
        tooltip: l10n.edit,
        onSelected: (action) async {
          final service = ref.read(tasksServiceProvider);
          switch (action) {
            case 'edit':
              await showTaskEditorDialog(context, task: task);
            case 'trash':
              await service.moveToTrash(task.id);
            case 'myDayAdd':
              await ref.read(myDayServiceProvider).addToMyDay(task.id);
            case 'myDayRemove':
              await ref.read(myDayServiceProvider).removeFromMyDay(task.id);
          }
        },
        itemBuilder: (context) => [
          if (myDayAction == MyDayAction.addToMyDay && task.isActive)
            PopupMenuItem(value: 'myDayAdd', child: Text(l10n.addToMyDay)),
          if (myDayAction == MyDayAction.removeFromMyDay)
            PopupMenuItem(
              value: 'myDayRemove',
              child: Text(l10n.removeFromMyDay),
            ),
          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
          if (!task.isDeleted)
            PopupMenuItem(value: 'trash', child: Text(l10n.moveToTrash)),
        ],
      ),
      onTap: onTap,
    );
  }
}
