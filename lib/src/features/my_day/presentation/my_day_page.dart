import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../../tasks/presentation/task_editor_dialog.dart';
import '../../tasks/presentation/task_errors.dart';

/// Foco do dia: ordem manual, entrada por tarefa/data e rollover
/// (spec 03, RF-06 a RF-10).
class MyDayPage extends ConsumerStatefulWidget {
  const MyDayPage({super.key});

  @override
  ConsumerState<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends ConsumerState<MyDayPage> {
  @override
  void initState() {
    super.initState();
    // Rollover idempotente ao abrir (spec 03, RF-10).
    Future.microtask(() => ref.read(myDayServiceProvider).rollover());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(tasksProvider);
    final entries = ref.watch(myDayEntriesProvider);
    final service = ref.watch(myDayServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myDayTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addToMyDay,
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) => entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (allEntries) {
            final today = service.todayKey;
            final todayEntries = allEntries
                .where((e) => e.date == today)
                .toList()
              ..sort((a, b) => a.position.compareTo(b.position));
            final byId = {for (final t in all) t.id: t};
            final ordered = <Task>[
              for (final entry in todayEntries)
                if (byId[entry.taskId]?.status == TaskStatus.active)
                  byId[entry.taskId]!,
            ];
            if (ordered.isEmpty) {
              return Center(child: Text(l10n.myDayEmpty));
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: ordered.length,
              onReorderItem: (oldIndex, newIndex) {
                final ids = [for (final t in ordered) t.id];
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                runTaskAction(context, () async {
                  await ref.read(myDayServiceProvider).reorderToday(ids);
                });
              },
              itemBuilder: (context, index) {
                final task = ordered[index];
                return ListTile(
                  key: ValueKey('myday-${task.id}'),
                  leading: Checkbox(
                    value: task.status == TaskStatus.completed,
                    onChanged: (checked) => runTaskAction(context, () async {
                      final tasksService = ref.read(tasksServiceProvider);
                      if (checked ?? false) {
                        await tasksService.completeTask(task.id);
                      } else {
                        await tasksService.reopenTask(task.id);
                      }
                    }),
                  ),
                  title: Text(task.title),
                  subtitle: task.dueDate == null ? null : Text(task.dueDate!),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskDetailPage(taskId: task.id),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: l10n.removeFromMyDay,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => runTaskAction(context, () async {
                      await ref
                          .read(myDayServiceProvider)
                          .removeToday(task.id);
                    }),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(l10n.addExistingTask),
              onTap: () => Navigator.of(context).pop('existing'),
            ),
            ListTile(
              leading: const Icon(Icons.add_task),
              title: Text(l10n.createTaskTitle),
              onTap: () => Navigator.of(context).pop('new'),
            ),
          ],
        ),
      ),
    );
    if (option == null || !context.mounted) return;
    if (option == 'new') {
      final draft = await TaskEditorDialog.show(context);
      if (draft == null || !context.mounted) return;
      await runTaskAction(context, () async {
        final tasksService = ref.read(tasksServiceProvider);
        final task = await tasksService.createTask(
          title: draft.title,
          notes: draft.notes,
        );
        await ref.read(myDayServiceProvider).addToday(task.id);
      });
    } else {
      await _pickExistingTask(context);
    }
  }

  Future<void> _pickExistingTask(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final all = await ref.read(tasksServiceProvider).fetchTasks();
    final candidates =
        all.where((t) => t.status == TaskStatus.active).toList();
    final today = ref.read(myDayServiceProvider).todayKey;
    final entries = await ref.read(myDayServiceProvider).fetchEntries();
    final already = {
      for (final e in entries.where((e) => e.date == today)) e.taskId,
    };
    final available = candidates
        .where((t) => !already.contains(t.id))
        .toList(growable: false);

    if (!context.mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noTasksToAdd)),
      );
      return;
    }

    final taskId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addExistingTask),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final task in available)
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
    if (taskId == null || !context.mounted) return;
    await runTaskAction(context, () async {
      await ref.read(myDayServiceProvider).addToday(taskId);
    });
  }
}
