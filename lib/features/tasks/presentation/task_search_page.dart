import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../organization/domain/organization.dart';
import '../../../core/dates/utc_gregorian_calendar_delegate.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/task_providers.dart';
import '../domain/task.dart';
import '../domain/task_ordering.dart';
import 'task_detail_page.dart';

enum _DueCriterion { noDueDate, overdue, today, nextSevenDays, customRange }

enum _ReminderCriterion { withReminder, withoutReminder }

enum _RecurrenceCriterion { active, none, cancelled }

class _TaskSearchFilters {
  const _TaskSearchFilters({
    this.statuses,
    this.listOptions,
    this.groupIds,
    this.categoryOptions,
    this.tagOptions,
    this.priorities,
    this.dueCriteria,
    this.reminderCriteria,
    this.recurrenceCriteria,
    this.customStartDateIso,
    this.customEndDateIso,
  });

  final Set<TaskStatus>? statuses;
  final Set<String>? listOptions;
  final Set<String>? groupIds;
  final Set<String>? categoryOptions;
  final Set<String>? tagOptions;
  final Set<TaskPriority>? priorities;
  final Set<_DueCriterion>? dueCriteria;
  final Set<_ReminderCriterion>? reminderCriteria;
  final Set<_RecurrenceCriterion>? recurrenceCriteria;
  final String? customStartDateIso;
  final String? customEndDateIso;

  int get activeCount => [
    statuses,
    listOptions,
    groupIds,
    categoryOptions,
    tagOptions,
    priorities,
    dueCriteria,
    reminderCriteria,
    recurrenceCriteria,
  ].where((filter) => filter != null).length;
}

class TaskSearchPage extends ConsumerStatefulWidget {
  const TaskSearchPage({super.key});

  @override
  ConsumerState<TaskSearchPage> createState() => _TaskSearchPageState();
}

class _TaskSearchPageState extends ConsumerState<TaskSearchPage>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  Timer? _calendarTimer;
  String _query = '';
  _TaskSearchFilters _filters = const _TaskSearchFilters();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleCalendarRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshCalendar();
  }

  @override
  void didChangeLocales(List<Locale>? locales) => _refreshCalendar();

  @override
  void dispose() {
    _debounce?.cancel();
    _calendarTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _refreshCalendar() {
    if (!mounted) return;
    setState(() {});
    _scheduleCalendarRefresh();
  }

  void _scheduleCalendarRefresh() {
    _calendarTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _calendarTimer = Timer(nextMidnight.difference(now), _refreshCalendar);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = query);
    });
  }

  Future<void> _openFilters({
    required List<TaskGroup> groups,
    required List<TaskList> lists,
    required List<TaskCategory> categories,
    required List<TaskTag> tags,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final next = await showDialog<_TaskSearchFilters>(
      context: context,
      builder: (context) => _SearchFilterDialog(
        initial: _filters,
        groups: groups,
        lists: lists,
        categories: categories,
        tags: tags,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
    if (next != null && mounted) setState(() => _filters = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(tasksProvider);
    final subtasks = ref.watch(allSubtasksProvider);
    final tagAssignments = ref.watch(allTaskTagAssignmentsProvider);
    final groups = ref.watch(taskGroupsProvider);
    final lists = ref.watch(taskListsProvider);
    final categories = ref.watch(taskCategoriesProvider);
    final tags = ref.watch(taskTagsProvider);

    final errors = [
      tasks.hasError,
      subtasks.hasError,
      tagAssignments.hasError,
      groups.hasError,
      lists.hasError,
      categories.hasError,
      tags.hasError,
    ];
    if (errors.contains(true)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.searchTasks)),
        body: Center(child: Text(l10n.unableToLoadTasks)),
      );
    }

    final taskRows = tasks.asData?.value;
    final subtaskRows = subtasks.asData?.value;
    final assignmentRows = tagAssignments.asData?.value;
    final groupRows = groups.asData?.value;
    final listRows = lists.asData?.value;
    final categoryRows = categories.asData?.value;
    final tagRows = tags.asData?.value;
    if (taskRows == null ||
        subtaskRows == null ||
        assignmentRows == null ||
        groupRows == null ||
        listRows == null ||
        categoryRows == null ||
        tagRows == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.searchTasks)),
        body: Center(child: Text(l10n.loading)),
      );
    }

    final subtasksByTask = <String, List<Subtask>>{};
    for (final subtask in subtaskRows) {
      subtasksByTask.putIfAbsent(subtask.taskId, () => []).add(subtask);
    }
    final tagsByTask = <String, Set<String>>{};
    for (final assignment in assignmentRows) {
      tagsByTask.putIfAbsent(assignment.taskId, () => {}).add(assignment.tagId);
    }

    final groupsById = {for (final group in groupRows) group.id: group};
    final listsById = {for (final list in listRows) list.id: list};
    var filterFirstDate = DateTime.utc(1900);
    var filterLastDate = DateTime.utc(2200, 12, 31);
    void includeFilterDate(DateTime date) {
      if (date.isBefore(filterFirstDate)) filterFirstDate = date;
      if (date.isAfter(filterLastDate)) filterLastDate = date;
    }

    for (final task in taskRows) {
      if (task.dueDateIso != null) {
        includeFilterDate(parseDateOnly(task.dueDateIso!));
      }
    }
    final savedRangeStart = _filters.customStartDateIso;
    if (savedRangeStart != null) {
      includeFilterDate(parseDateOnly(savedRangeStart));
    }
    final savedRangeEnd = _filters.customEndDateIso;
    if (savedRangeEnd != null) {
      includeFilterDate(parseDateOnly(savedRangeEnd));
    }
    final groupOrder = {
      for (var index = 0; index < groupRows.length; index++)
        groupRows[index].id: index,
    };
    final today = formatDateOnly(DateTime.now());
    final normalizedQuery = _foldSearchText(_query);
    final matchRanksByTask = <String, int>{};
    final matching = <Task>[];
    for (final task in taskRows) {
      if (task.status == TaskStatus.trashed ||
          !_matchesFilters(
            task: task,
            filters: _filters,
            tagsByTask: tagsByTask,
            listsById: listsById,
            todayIso: today,
          )) {
        continue;
      }
      final rank = _textMatchRank(
        task,
        normalizedQuery,
        subtasksByTask[task.id] ?? const <Subtask>[],
      );
      if (rank == null) continue;
      matching.add(task);
      matchRanksByTask[task.id] = rank;
    }
    matching.sort((first, second) {
      if (_query.isNotEmpty) {
        final relevance = matchRanksByTask[first.id]!.compareTo(
          matchRanksByTask[second.id]!,
        );
        if (relevance != 0) return relevance;
      }
      return compareTaskOrigin(
        first,
        second,
        listsById: listsById,
        groupsById: groupsById,
        groupOrder: groupOrder,
        groupCount: groupRows.length,
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTasks),
        actions: [
          TextButton.icon(
            onPressed: () => _openFilters(
              groups: groupRows,
              lists: listRows,
              categories: categoryRows,
              tags: tagRows,
              firstDate: filterFirstDate,
              lastDate: filterLastDate,
            ),
            icon: const Icon(Icons.filter_list),
            label: Text(
              _filters.activeCount == 0
                  ? l10n.filters
                  : '${l10n.filters} (${_filters.activeCount})',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          onPressed: () {
                            _debounce?.cancel();
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Expanded(
            child: matching.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.noSearchResults,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: matching.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = matching[index];
                          final rank = matchRanksByTask[task.id];
                          final deviceLocale = WidgetsBinding
                              .instance
                              .platformDispatcher
                              .locale
                              .toString();
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      TaskDetailPage(taskId: task.id),
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: task.status == TaskStatus.completed
                                    ? const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                      )
                                    : null,
                              ),
                              subtitle: _query.isNotEmpty && rank != null
                                  ? Text(
                                      rank == 1
                                          ? l10n.searchMatchInNotes
                                          : rank == 2
                                          ? l10n.searchMatchInSteps
                                          : l10n.searchMatchInTitle,
                                    )
                                  : task.dueDateIso == null
                                  ? null
                                  : Text(
                                      DateFormat.yMMMd(
                                        deviceLocale,
                                      ).format(parseDateOnly(task.dueDateIso!)),
                                    ),
                              trailing: task.status == TaskStatus.completed
                                  ? const Icon(Icons.task_alt)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

bool _matchesFilters({
  required Task task,
  required _TaskSearchFilters filters,
  required Map<String, Set<String>> tagsByTask,
  required Map<String, TaskList> listsById,
  required String todayIso,
}) {
  const noList = '\u0000no-list';
  const noCategory = '\u0000no-category';
  const noTags = '\u0000no-tags';
  if (filters.statuses != null && !filters.statuses!.contains(task.status)) {
    return false;
  }
  if (filters.listOptions != null) {
    final option = task.listId ?? noList;
    if (!filters.listOptions!.contains(option)) return false;
  }
  if (filters.groupIds != null) {
    final groupId = task.listId == null
        ? null
        : listsById[task.listId!]?.groupId;
    if (groupId == null || !filters.groupIds!.contains(groupId)) return false;
  }
  if (filters.categoryOptions != null) {
    final option = task.categoryId ?? noCategory;
    if (!filters.categoryOptions!.contains(option)) return false;
  }
  if (filters.tagOptions != null) {
    final taskTags = tagsByTask[task.id] ?? const <String>{};
    final matchesTag = taskTags.any(filters.tagOptions!.contains);
    final matchesWithoutTags =
        taskTags.isEmpty && filters.tagOptions!.contains(noTags);
    if (!matchesTag && !matchesWithoutTags) return false;
  }
  if (filters.priorities != null &&
      !filters.priorities!.contains(task.priority)) {
    return false;
  }
  if (filters.dueCriteria != null &&
      !_matchesDueCriteria(task, filters, todayIso)) {
    return false;
  }
  if (filters.reminderCriteria != null) {
    final criterion = task.reminderAtUtc == null
        ? _ReminderCriterion.withoutReminder
        : _ReminderCriterion.withReminder;
    if (!filters.reminderCriteria!.contains(criterion)) return false;
  }
  if (filters.recurrenceCriteria != null) {
    final criterion = task.recurringSeriesId == null
        ? _RecurrenceCriterion.none
        : task.recurrenceActive
        ? _RecurrenceCriterion.active
        : _RecurrenceCriterion.cancelled;
    if (!filters.recurrenceCriteria!.contains(criterion)) return false;
  }
  return true;
}

bool _matchesDueCriteria(
  Task task,
  _TaskSearchFilters filters,
  String todayIso,
) {
  final dueDate = task.dueDateIso;
  final today = parseDateOnly(todayIso);
  final nextSevenDays = formatDateOnly(today.add(const Duration(days: 7)));
  for (final criterion in filters.dueCriteria!) {
    switch (criterion) {
      case _DueCriterion.noDueDate:
        if (dueDate == null) return true;
      case _DueCriterion.overdue:
        if (task.status == TaskStatus.active &&
            dueDate != null &&
            dueDate.compareTo(todayIso) < 0) {
          return true;
        }
      case _DueCriterion.today:
        if (dueDate == todayIso) return true;
      case _DueCriterion.nextSevenDays:
        if (dueDate != null &&
            dueDate.compareTo(todayIso) > 0 &&
            dueDate.compareTo(nextSevenDays) <= 0) {
          return true;
        }
      case _DueCriterion.customRange:
        final start = filters.customStartDateIso;
        final end = filters.customEndDateIso;
        if (dueDate != null &&
            start != null &&
            end != null &&
            dueDate.compareTo(start) >= 0 &&
            dueDate.compareTo(end) <= 0) {
          return true;
        }
    }
  }
  return false;
}

int? _textMatchRank(Task task, String normalizedQuery, List<Subtask> subtasks) {
  if (normalizedQuery.isEmpty) return 0;
  if (_foldSearchText(task.title).contains(normalizedQuery)) return 0;
  if (task.notes != null &&
      _foldSearchText(task.notes!).contains(normalizedQuery)) {
    return 1;
  }
  if (subtasks.any(
    (subtask) => _foldSearchText(subtask.title).contains(normalizedQuery),
  )) {
    return 2;
  }
  return null;
}

const _searchAccentGroups = {
  'a': 'áàâãäåāăą',
  'c': 'çćč',
  'd': 'ďđ',
  'e': 'éèêëēĕėęě',
  'i': 'íìîïīĭįı',
  'l': 'ĺľł',
  'n': 'ñńň',
  'o': 'óòôõöōŏőø',
  'r': 'ŕř',
  's': 'śšş',
  't': 'ťţ',
  'u': 'úùûüūŭůűų',
  'y': 'ýÿ',
  'z': 'źžż',
};

final _searchCharacterReplacements = {
  for (final entry in _searchAccentGroups.entries)
    for (final character in entry.value.split('')) character: entry.key,
};

String _foldSearchText(String value) {
  final folded = String.fromCharCodes(
    value.toLowerCase().runes.map(
      (rune) =>
          _searchCharacterReplacements[String.fromCharCode(rune)]
              ?.runes
              .first ??
          rune,
    ),
  );
  return folded.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
}

class _SearchFilterDialog extends StatefulWidget {
  const _SearchFilterDialog({
    required this.initial,
    required this.groups,
    required this.lists,
    required this.categories,
    required this.tags,
    required this.firstDate,
    required this.lastDate,
  });

  final _TaskSearchFilters initial;
  final List<TaskGroup> groups;
  final List<TaskList> lists;
  final List<TaskCategory> categories;
  final List<TaskTag> tags;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<_SearchFilterDialog> {
  static const _noList = '\u0000no-list';
  static const _noCategory = '\u0000no-category';
  static const _noTags = '\u0000no-tags';

  late Set<TaskStatus> _statuses;
  late Set<String> _listOptions;
  late Set<String> _groupIds;
  // Explicitly selecting every available option excludes ungrouped tasks.
  late bool _groupFilterEnabled;
  late Set<String> _categoryOptions;
  late Set<String> _tagOptions;
  late Set<TaskPriority> _priorities;
  // Explicitly selecting every priority excludes tasks with no priority.
  late bool _priorityFilterEnabled;
  late Set<_DueCriterion> _dueCriteria;
  // Keep an explicit union of all date categories distinct from no filter.
  late bool _dueFilterEnabled;
  late Set<_ReminderCriterion> _reminderCriteria;
  late Set<_RecurrenceCriterion> _recurrenceCriteria;
  String? _customStartDateIso;
  String? _customEndDateIso;
  bool _dateRangeError = false;

  @override
  void initState() {
    super.initState();
    final filter = widget.initial;
    _statuses = (filter.statuses ?? {TaskStatus.active, TaskStatus.completed})
        .toSet();
    _listOptions =
        (filter.listOptions ??
                {_noList, ...widget.lists.map((list) => list.id)})
            .toSet();
    _groupIds =
        (filter.groupIds ?? widget.groups.map((group) => group.id).toSet())
            .toSet();
    _groupFilterEnabled = filter.groupIds != null;
    _categoryOptions =
        (filter.categoryOptions ??
                {
                  _noCategory,
                  ...widget.categories.map((category) => category.id),
                })
            .toSet();
    _tagOptions =
        (filter.tagOptions ?? {_noTags, ...widget.tags.map((tag) => tag.id)})
            .toSet();
    _priorities =
        (filter.priorities ??
                {
                  TaskPriority.low,
                  TaskPriority.medium,
                  TaskPriority.high,
                  TaskPriority.urgent,
                })
            .toSet();
    _priorityFilterEnabled = filter.priorities != null;
    _dueCriteria = (filter.dueCriteria ?? _DueCriterion.values.toSet()).toSet();
    _dueFilterEnabled = filter.dueCriteria != null;
    _reminderCriteria =
        (filter.reminderCriteria ?? _ReminderCriterion.values.toSet()).toSet();
    _recurrenceCriteria =
        (filter.recurrenceCriteria ?? _RecurrenceCriterion.values.toSet())
            .toSet();
    _customStartDateIso = filter.customStartDateIso;
    _customEndDateIso = filter.customEndDateIso;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statuses = <_SearchOption<TaskStatus>>[
      _SearchOption(TaskStatus.active, l10n.activeTasks),
      _SearchOption(TaskStatus.completed, l10n.completedTasks),
    ];
    final listOptions = <_SearchOption<String>>[
      _SearchOption(_noList, l10n.noList),
      for (final list in widget.lists) _SearchOption(list.id, list.name),
    ];
    final groupOptions = [
      for (final group in widget.groups) _SearchOption(group.id, group.name),
    ];
    final categoryOptions = <_SearchOption<String>>[
      _SearchOption(_noCategory, l10n.noCategory),
      for (final category in widget.categories)
        _SearchOption(category.id, category.name),
    ];
    final tagOptions = <_SearchOption<String>>[
      _SearchOption(_noTags, l10n.noTags),
      for (final tag in widget.tags) _SearchOption(tag.id, tag.name),
    ];
    final priorities = <_SearchOption<TaskPriority>>[
      _SearchOption(TaskPriority.low, l10n.priorityLow),
      _SearchOption(TaskPriority.medium, l10n.priorityMedium),
      _SearchOption(TaskPriority.high, l10n.priorityHigh),
      _SearchOption(TaskPriority.urgent, l10n.priorityUrgent),
    ];
    final dueOptions = <_SearchOption<_DueCriterion>>[
      _SearchOption(_DueCriterion.noDueDate, l10n.noDueDate),
      _SearchOption(_DueCriterion.overdue, l10n.overdue),
      _SearchOption(_DueCriterion.today, l10n.dueToday),
      _SearchOption(_DueCriterion.nextSevenDays, l10n.nextSevenDays),
      _SearchOption(_DueCriterion.customRange, l10n.customDateRange),
    ];
    final reminderOptions = <_SearchOption<_ReminderCriterion>>[
      _SearchOption(_ReminderCriterion.withReminder, l10n.withReminder),
      _SearchOption(_ReminderCriterion.withoutReminder, l10n.withoutReminder),
    ];
    final recurrenceOptions = <_SearchOption<_RecurrenceCriterion>>[
      _SearchOption(_RecurrenceCriterion.active, l10n.withRecurrence),
      _SearchOption(_RecurrenceCriterion.none, l10n.withoutRecurrence),
      _SearchOption(_RecurrenceCriterion.cancelled, l10n.cancelledRecurrence),
    ];

    return AlertDialog(
      title: Text(l10n.filters),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _section(
                l10n.status,
                statuses,
                _statuses,
                (values) => _statuses = values,
              ),
              _section(
                l10n.lists,
                listOptions,
                _listOptions,
                (values) => _listOptions = values,
              ),
              if (groupOptions.isNotEmpty)
                _section(l10n.groups, groupOptions, _groupIds, (values) {
                  _groupIds = values;
                  _groupFilterEnabled = true;
                }),
              _section(
                l10n.categories,
                categoryOptions,
                _categoryOptions,
                (values) => _categoryOptions = values,
              ),
              _section(
                l10n.tags,
                tagOptions,
                _tagOptions,
                (values) => _tagOptions = values,
              ),
              _section(l10n.priority, priorities, _priorities, (values) {
                _priorities = values;
                _priorityFilterEnabled = true;
              }),
              _section(l10n.dueDate, dueOptions, _dueCriteria, (values) {
                _dueCriteria = values;
                _dueFilterEnabled = true;
                if (!_isCustomRangeActive(values)) _dateRangeError = false;
              }),
              if (_customRangeIsActive) _customRangeControl(l10n),
              _section(
                l10n.reminder,
                reminderOptions,
                _reminderCriteria,
                (values) => _reminderCriteria = values,
              ),
              _section(
                l10n.recurrence,
                recurrenceOptions,
                _recurrenceCriteria,
                (values) => _recurrenceCriteria = values,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_clearAll),
          child: Text(l10n.clearFilters),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _applyFilters, child: Text(l10n.apply)),
      ],
    );
  }

  Widget _section<T>(
    String title,
    List<_SearchOption<T>> options,
    Set<T> selected,
    ValueChanged<Set<T>> onChanged,
  ) => ExpansionTile(
    title: Text(title),
    children: [
      for (final option in options)
        CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(option.label),
          value: selected.contains(option.value),
          onChanged: (checked) {
            final next = Set<T>.of(selected);
            if (checked == true) {
              next.add(option.value);
            } else {
              next.remove(option.value);
            }
            setState(() => onChanged(next));
          },
        ),
    ],
  );

  Widget _customRangeControl(AppLocalizations l10n) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();
    String label(String? iso) => iso == null
        ? l10n.chooseDate
        : DateFormat.yMMMd(locale).format(parseDateOnly(iso));
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: () => _chooseCustomRange(),
            child: Text(
              '${label(_customStartDateIso)} – ${label(_customEndDateIso)}',
            ),
          ),
          if (_dateRangeError) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).dateRangeRequired,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  void _applyFilters() {
    final needsDateRange =
        _customRangeIsActive &&
        (_customStartDateIso == null || _customEndDateIso == null);
    if (needsDateRange) {
      setState(() => _dateRangeError = true);
      return;
    }
    Navigator.of(context).pop(_buildFilters());
  }

  Future<void> _chooseCustomRange() async {
    final initial = _customStartDateIso == null || _customEndDateIso == null
        ? null
        : DateTimeRange(
            start: parseDateOnly(_customStartDateIso!),
            end: parseDateOnly(_customEndDateIso!),
          );
    final range = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDateRange: initial,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      calendarDelegate: const UtcGregorianCalendarDelegate(),
    );
    if (range == null || !mounted) return;
    setState(() {
      _customStartDateIso = formatDateOnly(range.start);
      _customEndDateIso = formatDateOnly(range.end);
      _dateRangeError = false;
    });
  }

  void _clearAll() {
    _statuses = {TaskStatus.active, TaskStatus.completed};
    _listOptions = {_noList, ...widget.lists.map((list) => list.id)};
    _groupIds = widget.groups.map((group) => group.id).toSet();
    _groupFilterEnabled = false;
    _categoryOptions = {
      _noCategory,
      ...widget.categories.map((category) => category.id),
    };
    _tagOptions = {_noTags, ...widget.tags.map((tag) => tag.id)};
    _priorities = {
      TaskPriority.low,
      TaskPriority.medium,
      TaskPriority.high,
      TaskPriority.urgent,
    };
    _priorityFilterEnabled = false;
    _dueCriteria = _DueCriterion.values.toSet();
    _dueFilterEnabled = false;
    _reminderCriteria = _ReminderCriterion.values.toSet();
    _recurrenceCriteria = _RecurrenceCriterion.values.toSet();
    _customStartDateIso = null;
    _customEndDateIso = null;
    _dateRangeError = false;
  }

  _TaskSearchFilters _buildFilters() => _TaskSearchFilters(
    statuses: _collapseSelection(_statuses, {
      TaskStatus.active,
      TaskStatus.completed,
    }),
    listOptions: _collapseSelection(_listOptions, {
      _noList,
      ...widget.lists.map((list) => list.id),
    }),
    groupIds: _groupFilterEnabled
        ? _groupIds
        : _collapseSelection(
            _groupIds,
            widget.groups.map((group) => group.id).toSet(),
          ),
    categoryOptions: _collapseSelection(_categoryOptions, {
      _noCategory,
      ...widget.categories.map((category) => category.id),
    }),
    tagOptions: _collapseSelection(_tagOptions, {
      _noTags,
      ...widget.tags.map((tag) => tag.id),
    }),
    priorities: _priorityFilterEnabled
        ? _priorities
        : _collapseSelection(_priorities, {
            TaskPriority.low,
            TaskPriority.medium,
            TaskPriority.high,
            TaskPriority.urgent,
          }),
    dueCriteria: _dueFilterEnabled
        ? _dueCriteria
        : _collapseSelection(_dueCriteria, _DueCriterion.values.toSet()),
    reminderCriteria: _collapseSelection(
      _reminderCriteria,
      _ReminderCriterion.values.toSet(),
    ),
    recurrenceCriteria: _collapseSelection(
      _recurrenceCriteria,
      _RecurrenceCriterion.values.toSet(),
    ),
    customStartDateIso: _customStartDateIso,
    customEndDateIso: _customEndDateIso,
  );

  bool get _customRangeIsActive => _isCustomRangeActive(_dueCriteria);

  bool _isCustomRangeActive(Set<_DueCriterion> criteria) {
    return _dueFilterEnabled && criteria.contains(_DueCriterion.customRange);
  }

  Set<T>? _collapseSelection<T>(Set<T> selected, Set<T> all) =>
      selected.containsAll(all) && all.containsAll(selected)
      ? null
      : Set<T>.of(selected);
}

class _SearchOption<T> {
  const _SearchOption(this.value, this.label);

  final T value;
  final String label;
}
