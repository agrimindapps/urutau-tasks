import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/app_settings_page.dart';
import '../../organization/presentation/organization_page.dart';
import '../application/task_providers.dart';
import '../domain/task.dart';
import '../domain/task_ordering.dart';
import 'task_detail_page.dart';
import 'task_card_metadata.dart';
import 'task_search_page.dart';
import 'task_title_dialog.dart';

enum _TaskCollection { myDay, important, planned, active, completed, trash }

class TaskHomePage extends ConsumerStatefulWidget {
  const TaskHomePage({super.key});

  @override
  ConsumerState<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends ConsumerState<TaskHomePage>
    with WidgetsBindingObserver {
  _TaskCollection _collection = _TaskCollection.myDay;
  Timer? _rolloverTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_rolloverMyDay());
    _scheduleRolloverCheck();
  }

  @override
  void dispose() {
    _rolloverTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_rolloverMyDay());
      _scheduleRolloverCheck();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    _scheduleRolloverCheck();
    unawaited(_rolloverMyDay());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (_collection) {
      _TaskCollection.myDay => l10n.myDay,
      _TaskCollection.important => l10n.importantTasks,
      _TaskCollection.planned => l10n.plannedTasks,
      _TaskCollection.active => l10n.allTasks,
      _TaskCollection.completed => l10n.completedTasks,
      _TaskCollection.trash => l10n.trash,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: l10n.searchTasks,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const TaskSearchPage(),
              ),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AppSettingsPage(),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: l10n.manageOrganization,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const OrganizationPage(),
              ),
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final content = _TaskCollectionView(
            collection: _collection,
            onOpenTask: _openTask,
            onTaskChanged: _runTaskAction,
          );
          if (!wide) return content;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _collection.index,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: _selectCollection,
                destinations: _railDestinations(l10n),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          );
        },
      ),
      drawer: MediaQuery.sizeOf(context).width < 840
          ? Drawer(child: _mobileNavigation(l10n))
          : null,
      floatingActionButton:
          _collection != _TaskCollection.completed &&
              _collection != _TaskCollection.trash
          ? FloatingActionButton.extended(
              onPressed: _createTask,
              icon: const Icon(Icons.add),
              label: Text(l10n.newTask),
            )
          : null,
    );
  }

  List<NavigationRailDestination> _railDestinations(AppLocalizations l10n) => [
    NavigationRailDestination(
      icon: const Icon(Icons.wb_sunny_outlined),
      selectedIcon: const Icon(Icons.wb_sunny),
      label: Text(l10n.myDay),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.star_border),
      selectedIcon: const Icon(Icons.star),
      label: Text(l10n.importantTasks),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.event_outlined),
      selectedIcon: const Icon(Icons.event),
      label: Text(l10n.plannedTasks),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.inbox_outlined),
      selectedIcon: const Icon(Icons.inbox),
      label: Text(l10n.allTasks),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.task_alt_outlined),
      selectedIcon: const Icon(Icons.task_alt),
      label: Text(l10n.completedTasks),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.delete_outline),
      selectedIcon: const Icon(Icons.delete),
      label: Text(l10n.trash),
    ),
  ];

  Widget _mobileNavigation(AppLocalizations l10n) => SafeArea(
    child: ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final collection in _TaskCollection.values)
          ListTile(
            selected: collection == _collection,
            leading: Icon(_iconFor(collection)),
            title: Text(_labelFor(collection, l10n)),
            onTap: () {
              _selectCollection(collection.index);
              Navigator.of(context).pop();
            },
          ),
      ],
    ),
  );

  IconData _iconFor(_TaskCollection collection) => switch (collection) {
    _TaskCollection.myDay => Icons.wb_sunny_outlined,
    _TaskCollection.important => Icons.star_border,
    _TaskCollection.planned => Icons.event_outlined,
    _TaskCollection.active => Icons.inbox_outlined,
    _TaskCollection.completed => Icons.task_alt_outlined,
    _TaskCollection.trash => Icons.delete_outline,
  };

  String _labelFor(_TaskCollection collection, AppLocalizations l10n) =>
      switch (collection) {
        _TaskCollection.myDay => l10n.myDay,
        _TaskCollection.important => l10n.importantTasks,
        _TaskCollection.planned => l10n.plannedTasks,
        _TaskCollection.active => l10n.allTasks,
        _TaskCollection.completed => l10n.completedTasks,
        _TaskCollection.trash => l10n.trash,
      };

  void _selectCollection(int index) {
    setState(() => _collection = _TaskCollection.values[index]);
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
    Task? createdTask;
    await _runTaskAction(() async {
      final repository = ref.read(taskRepositoryProvider);
      if (_collection == _TaskCollection.myDay) {
        createdTask = await repository.createTaskAndAddToMyDay(
          title,
          _todayIso(),
        );
      } else {
        createdTask = await repository.createTask(title);
      }
    });
    if (!mounted || createdTask == null) return;
    if (_collection == _TaskCollection.important ||
        _collection == _TaskCollection.planned) {
      _openTask(createdTask!.id);
    }
  }

  String _todayIso() => formatDateOnly(DateTime.now());

  void _scheduleRolloverCheck() {
    _rolloverTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _rolloverTimer = Timer(nextMidnight.difference(now), () {
      unawaited(_rolloverMyDay());
      _scheduleRolloverCheck();
    });
  }

  Future<void> _rolloverMyDay() async {
    try {
      await ref.read(taskRepositoryProvider).rolloverMyDay(_todayIso());
    } catch (_) {
      // Preserve the application shell if a local database operation fails.
    }
    if (!mounted) return;
    // My Day providers are keyed by the local calendar date. Rebuild after
    // rollover or resume so they watch the current date instead of yesterday.
    setState(() {});
  }

  Future<void> _runTaskAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
      );
    }
  }

  void _openTask(String taskId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailPage(taskId: taskId),
      ),
    );
  }
}

class _TaskCollectionView extends ConsumerWidget {
  const _TaskCollectionView({
    required this.collection,
    required this.onOpenTask,
    required this.onTaskChanged,
  });

  final _TaskCollection collection;
  final ValueChanged<String> onOpenTask;
  final Future<void> Function(Future<void> Function()) onTaskChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(taskGroupsProvider).asData?.value ?? const [];
    final lists = ref.watch(taskListsProvider).asData?.value ?? const [];
    final groupsById = {for (final group in groups) group.id: group};
    final listsById = {for (final list in lists) list.id: list};
    final groupOrder = {
      for (var index = 0; index < groups.length; index++)
        groups[index].id: index,
    };
    final allSubtasks = ref.watch(allSubtasksProvider).asData?.value;
    final progressByTask = <String, _TaskProgress>{};
    for (final subtask in allSubtasks ?? const <Subtask>[]) {
      final current =
          progressByTask[subtask.taskId] ?? const _TaskProgress(0, 0);
      progressByTask[subtask.taskId] = _TaskProgress(
        current.completed + (subtask.isCompleted ? 1 : 0),
        current.total + 1,
      );
    }
    final today = formatDateOnly(DateTime.now());
    final tasks = collection == _TaskCollection.myDay
        ? ref.watch(myDayTasksProvider(today))
        : ref.watch(tasksProvider);
    return tasks.when(
      loading: () => Center(child: Text(l10n.loading)),
      error: (error, _) => _EmptyCollection(
        message: switch (error) {
          NewerDatabaseSchemaException() => l10n.databaseFromNewerVersion,
          DatabaseMigrationFailedException() => l10n.databaseMigrationFailed,
          _ => l10n.unableToLoadTasks,
        },
      ),
      data: (allTasks) {
        final todayDate = formatDateOnly(DateTime.now());
        final visibleTasks = switch (collection) {
          _TaskCollection.myDay => List<Task>.of(allTasks),
          _TaskCollection.important =>
            allTasks
                .where(
                  (task) =>
                      task.status == TaskStatus.active &&
                      task.priority.index >= TaskPriority.high.index,
                )
                .toList(),
          _TaskCollection.planned =>
            allTasks
                .where(
                  (task) =>
                      task.status == TaskStatus.active &&
                      (task.dueDateIso != null || task.reminderAtUtc != null),
                )
                .toList(),
          _TaskCollection.active =>
            allTasks.where((task) => task.status == TaskStatus.active).toList(),
          _TaskCollection.completed =>
            allTasks
                .where((task) => task.status == TaskStatus.completed)
                .toList(),
          _TaskCollection.trash =>
            allTasks
                .where((task) => task.status == TaskStatus.trashed)
                .toList(),
        };
        if (collection != _TaskCollection.myDay) {
          visibleTasks.sort((first, second) {
            final firstRank = _dueRank(first, todayDate);
            final secondRank = _dueRank(second, todayDate);
            var comparison = firstRank.compareTo(secondRank);
            if (comparison != 0) return comparison;
            if (first.dueDateIso != null && second.dueDateIso != null) {
              comparison = first.dueDateIso!.compareTo(second.dueDateIso!);
              if (comparison != 0) return comparison;
            }
            comparison = second.priority.index.compareTo(first.priority.index);
            if (comparison != 0) return comparison;
            if (first.status == TaskStatus.completed &&
                second.status == TaskStatus.completed) {
              comparison = (second.completedAtUtc ?? DateTime(0)).compareTo(
                first.completedAtUtc ?? DateTime(0),
              );
              if (comparison != 0) return comparison;
            }
            return compareTaskOrigin(
              first,
              second,
              listsById: listsById,
              groupsById: groupsById,
              groupOrder: groupOrder,
              groupCount: groups.length,
            );
          });
        }
        if (visibleTasks.isEmpty) {
          final message = switch (collection) {
            _TaskCollection.myDay => l10n.myDayEmpty,
            _TaskCollection.important => l10n.noImportantTasks,
            _TaskCollection.planned => l10n.noPlannedTasks,
            _TaskCollection.active => l10n.noActiveTasks,
            _TaskCollection.completed => l10n.noCompletedTasks,
            _TaskCollection.trash => l10n.trashEmpty,
          };
          return _EmptyCollection(message: message);
        }

        Widget buildTaskCard(Task task) {
          final progress = progressByTask[task.id];
          final progressText = allSubtasks == null || progress == null
              ? null
              : l10n.taskProgress(progress.completed, progress.total);
          final sourceText = taskOriginLabel(
            task: task,
            listsById: listsById,
            groupsById: groupsById,
            l10n: l10n,
          );
          return _TaskCard(
            key: ValueKey(task.id),
            task: task,
            collection: collection,
            progressText: progressText,
            sourceText: sourceText,
            onOpen: () => onOpenTask(task.id),
            onCompleteChanged: (completed) => onTaskChanged(() async {
              await ref
                  .read(taskRepositoryProvider)
                  .setTaskCompleted(task.id, completed);
            }),
            onTaskDayChanged: (isInMyDay) => onTaskChanged(() async {
              final repository = ref.read(taskRepositoryProvider);
              if (isInMyDay) {
                await repository.addTaskToMyDay(task.id, today);
              } else {
                await repository.removeTaskFromMyDay(task.id, today);
              }
            }),
            onTrash: collection == _TaskCollection.trash
                ? null
                : () => onTaskChanged(() async {
                    await ref
                        .read(taskRepositoryProvider)
                        .moveTaskToTrash(task.id);
                  }),
            onRestore: collection == _TaskCollection.trash
                ? () => onTaskChanged(() async {
                    await ref.read(taskRepositoryProvider).restoreTask(task.id);
                  })
                : null,
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: collection == _TaskCollection.myDay
                ? ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: visibleTasks.length,
                    onReorderItem: (oldIndex, newIndex) =>
                        onTaskChanged(() async {
                          final reordered = List.of(visibleTasks);
                          final item = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, item);
                          await ref
                              .read(taskRepositoryProvider)
                              .reorderMyDay(
                                today,
                                reordered.map((task) => task.id).toList(),
                              );
                        }),
                    itemBuilder: (context, index) =>
                        buildTaskCard(visibleTasks[index]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        buildTaskCard(visibleTasks[index]),
                  ),
          ),
        );
      },
    );
  }

  int _dueRank(Task task, String today) {
    final dueDate = task.dueDateIso;
    if (dueDate == null) return 3;
    if (dueDate.compareTo(today) < 0 && task.status == TaskStatus.active) {
      return 0;
    }
    if (dueDate == today) return 1;
    return 2;
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.collection,
    required this.progressText,
    required this.sourceText,
    required this.onOpen,
    required this.onCompleteChanged,
    required this.onTaskDayChanged,
    this.onTrash,
    this.onRestore,
  });

  final Task task;
  final _TaskCollection collection;
  final String? progressText;
  final String? sourceText;
  final VoidCallback onOpen;
  final ValueChanged<bool> onCompleteChanged;
  final ValueChanged<bool> onTaskDayChanged;
  final VoidCallback? onTrash;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myDayTasks = ref.watch(
      myDayTasksProvider(formatDateOnly(DateTime.now())),
    );
    final isInMyDay =
        collection == _TaskCollection.myDay ||
        myDayTasks.when(
          data: (tasks) => tasks.any((myDayTask) => myDayTask.id == task.id),
          error: (_, _) => false,
          loading: () => false,
        );
    return Card(
      key: key,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.only(left: 8, right: 8),
        leading: task.status == TaskStatus.trashed
            ? const Icon(Icons.delete_outline)
            : Checkbox(
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
        subtitle: TaskCardMetadata.maybe(
          task,
          progressText: progressText,
          sourceText: sourceText,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.status == TaskStatus.active)
              IconButton(
                tooltip: isInMyDay ? l10n.removeFromMyDay : l10n.addToMyDay,
                onPressed: () => onTaskDayChanged(!isInMyDay),
                icon: Icon(
                  isInMyDay ? Icons.wb_sunny : Icons.wb_sunny_outlined,
                ),
              ),
            if (onRestore != null)
              IconButton(
                tooltip: l10n.restore,
                onPressed: onRestore,
                icon: const Icon(Icons.restore),
              )
            else
              IconButton(
                tooltip: l10n.moveToTrash,
                onPressed: onTrash,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskProgress {
  const _TaskProgress(this.completed, this.total);

  final int completed;
  final int total;
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}
