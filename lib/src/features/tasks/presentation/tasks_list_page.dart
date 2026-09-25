import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../views/domain/smart_views.dart';
import '../domain/task.dart';
import 'task_confirm.dart';
import 'task_detail_page.dart';
import 'task_editor_dialog.dart';
import 'task_errors.dart';
import 'task_tile.dart';

/// Lista de tarefas com as visões inteligentes (spec 03, RF-01 a RF-04).
class TasksListPage extends ConsumerStatefulWidget {
  const TasksListPage({super.key});

  @override
  ConsumerState<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends ConsumerState<TasksListPage> {
  SmartView _view = SmartView.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(tasksProvider);
    final entries = ref.watch(myDayEntriesProvider);
    final myDayService = ref.watch(myDayServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_title(l10n))),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newTaskTooltip,
        onPressed: () => _createTask(context),
        child: const Icon(Icons.add),
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          final myDayIds = entries.maybeWhen(
            data: (list) => {
              for (final e in list.where((e) => e.date == myDayService.todayKey))
                e.taskId,
            },
            orElse: () => <String>{},
          );
          final visible = selectSmartView(
            _view,
            all,
            today: myDayService.todayKey,
            myDayTaskIds: myDayIds,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final view in const [
                        SmartView.all,
                        SmartView.important,
                        SmartView.planned,
                        SmartView.completed,
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(_viewLabel(l10n, view)),
                            selected: _view == view,
                            onSelected: (_) =>
                                setState(() => _view = view),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: Text(l10n.emptyView))
                    : ListView(
                        children: [
                          for (final task in visible) _tile(context, task),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (_view) {
        SmartView.all => l10n.viewAll,
        SmartView.important => l10n.viewImportant,
        SmartView.planned => l10n.viewPlanned,
        SmartView.completed => l10n.viewCompleted,
        SmartView.myDay => l10n.myDayTitle,
      };

  String _viewLabel(AppLocalizations l10n, SmartView view) => switch (view) {
        SmartView.all => l10n.viewAll,
        SmartView.important => l10n.viewImportant,
        SmartView.planned => l10n.viewPlanned,
        SmartView.completed => l10n.viewCompleted,
        SmartView.myDay => l10n.myDayTitle,
      };

  Widget _tile(BuildContext context, Task task) {
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
      onEdit: () => _editTask(context, task),
      onDelete: () => _confirmDelete(context, task),
      onAddToMyDay: task.status == TaskStatus.active
          ? () => runTaskAction(context, () async {
                await ref.read(myDayServiceProvider).addToday(task.id);
              })
          : null,
    );
  }

  Future<void> _createTask(BuildContext context) async {
    final draft = await TaskEditorDialog.show(context);
    if (draft == null || !context.mounted) return;
    await runTaskAction(context, () async {
      await ref
          .read(tasksServiceProvider)
          .createTask(title: draft.title, notes: draft.notes);
    });
  }

  Future<void> _editTask(BuildContext context, Task task) async {
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

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await confirmDeleteTask(context);
    if (!confirmed || !context.mounted) return;
    await runTaskAction(context, () async {
      await ref.read(tasksServiceProvider).moveToTrash(task.id);
    });
  }
}
