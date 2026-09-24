import 'dart:async';

import 'package:flutter/material.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../organization/domain/organization.dart';
import '../../recurrence/domain/recurrence.dart';
import '../../search/domain/task_query.dart';
import '../../tasks/domain/task.dart';
import '../../search/presentation/filter_sheet.dart';
import '../../views/domain/smart_views.dart';
import 'task_detail_page.dart';
import 'task_editor_dialog.dart';
import 'task_tile.dart';

/// Lista de tarefas com visões inteligentes, busca global e filtros
/// combináveis (specs 03 e 05).
class TasksListPage extends ConsumerStatefulWidget {
  const TasksListPage({super.key});

  @override
  ConsumerState<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends ConsumerState<TasksListPage> {
  SmartView _view = SmartView.all;

  /// Filtros estruturados (sem o texto — este vive no debounce).
  TaskFilters _filters = const TaskFilters();

  /// Texto confirmado após o debounce (spec 05, RF-06).
  String _committedQuery = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  static const _views = [
    SmartView.all,
    SmartView.important,
    SmartView.planned,
    SmartView.completed,
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _committedQuery = value);
    });
    // Atualiza imediatamente o estado local do campo sem revalidar ainda.
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _committedQuery = '';
      _filters = const TaskFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasksAsync = ref.watch(tasksProvider);
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final seriesById = {
      for (final series in
        ref.watch(allSeriesProvider).value ?? const <RecurrenceSeries>[])
        series.id: series,
    };
    final searchContext = TaskSearchContext(
      today: DateTime.now(),
      lists: lists,
      seriesById: seriesById,
    );

    final combined = _filters.copyWith(query: _committedQuery);
    final searchActive = combined.isActive;
    final structuredCount = _filters.hasStructuredFilters ? 1 : 0;

    String viewLabel(SmartView view) => switch (view) {
          SmartView.all => l10n.viewAll,
          SmartView.important => l10n.viewImportant,
          SmartView.planned => l10n.viewPlanned,
          SmartView.completed => l10n.viewCompleted,
        };

    return Scaffold(
      appBar: AppBar(
        title: Text(searchActive ? l10n.searchHint : viewLabel(_view)),
        actions: [
          IconButton(
            tooltip: l10n.filtersTitle,
            icon: Badge(
              isLabelVisible: structuredCount > 0,
              label: const Text(''),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () async {
              final updated = await showFilterSheet(
                context,
                current: _filters,
              );
              if (updated != null && mounted) {
                setState(() => _filters = updated);
              }
            },
          ),
          if (searchActive)
            IconButton(
              tooltip: l10n.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: _clearSearch,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditorDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTask),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      ),
              ),
            ),
          ),
          // Chips rápidos de lista (spec 02 CA-04; também filtram a busca).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.filterAll),
                  selected: _filters.listIds.isEmpty,
                  onSelected: (_) => setState(
                    () => _filters = _filters.copyWith(
                      listIds: const {},
                      query: _filters.query,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.noList),
                  selected: _filters.listIds.contains(null),
                  onSelected: (_) => setState(
                    () => _filters = _filters.copyWith(listIds: const {null}),
                  ),
                ),
                for (final list in lists) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(list.name),
                    selected: _filters.listIds.contains(list.id),
                    onSelected: (_) => setState(
                      () => _filters = _filters.copyWith(listIds: {list.id}),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Visões só no modo de navegação (spec 05, RF-01: a busca é
          // global e independe da visão aberta).
          if (!searchActive)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  for (final view in _views) ...[
                    ChoiceChip(
                      label: Text(viewLabel(view)),
                      selected: _view == view,
                      onSelected: (_) => setState(() => _view = view),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (allTasks) {
                final List<Task> visible;
                if (searchActive) {
                  visible = searchTasks(
                    tasks: allTasks,
                    filters: combined,
                    context: searchContext,
                  );
                } else {
                  visible = tasksForView(
                    _view,
                    allTasks,
                    today: DateTime.now(),
                  );
                }
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      searchActive ? l10n.emptySearch : l10n.emptyTasks,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    for (final task in visible)
                      TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        myDayAction: MyDayAction.addToMyDay,
                        onTap: () => _openDetail(context, task.id),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String taskId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(taskId: taskId),
      ),
    );
  }
}
