import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../../../data/providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../../tasks/presentation/task_tile.dart';

/// My Day: foco diário com ordem manual (spec 03, RF-06 a RF-12).
class MyDayPage extends ConsumerStatefulWidget {
  const MyDayPage({super.key});

  @override
  ConsumerState<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends ConsumerState<MyDayPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(myDayTodayProvider).value ?? const [];
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final myDayService = ref.read(myDayServiceProvider);

    final tasksById = {for (final task in tasks) task.id: task};
    final orderedTasks = [
      for (final entry in entries)
        if (tasksById[entry.taskId] != null) tasksById[entry.taskId]!,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myDayTab)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickExistingTask(orderedTasks),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExistingTask),
      ),
      body: orderedTasks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.emptyMyDay, textAlign: TextAlign.center),
              ),
            )
          : ReorderableListView(
              padding: const EdgeInsets.only(bottom: 96),
              onReorderItem: (oldIndex, newIndex) =>
                  myDayService.reorder(oldIndex, newIndex),
              children: [
                for (final task in orderedTasks)
                  TaskTile(
                    key: ValueKey(task.id),
                    task: task,
                    myDayAction: MyDayAction.removeFromMyDay,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TaskDetailPage(taskId: task.id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _pickExistingTask(List<Task> alreadyInMyDay) async {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final presentIds = alreadyInMyDay.map((t) => t.id).toSet();
    final candidates =
        tasks.where((t) => t.isActive && !presentIds.contains(t.id)).toList();

    final selectedId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addExistingTask),
        content: SizedBox(
          width: 400,
          child: candidates.isEmpty
              ? Text(l10n.emptyTasks)
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final task in candidates)
                      ListTile(
                        title: Text(task.title),
                        onTap: () => Navigator.of(context).pop(task.id),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (selectedId == null || !mounted) return;
    await ref.read(myDayServiceProvider).addToMyDay(selectedId);
  }
}
