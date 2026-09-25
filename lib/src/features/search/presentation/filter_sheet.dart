import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../tasks/domain/task.dart';
import '../domain/task_query.dart';

/// Folha de filtros combinados (spec 05, RF-08 a RF-15).
///
/// Retorna o [TaskFilter] selecionado; categorias diferentes são AND,
/// opções da mesma categoria são OR.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.lists,
    required this.groups,
    required this.categories,
    required this.tags,
  });

  final TaskFilter initial;
  final List<(String id, String name)> lists;
  final List<(String id, String name)> groups;
  final List<(String id, String name)> categories;
  final List<(String id, String name)> tags;

  static Future<TaskFilter?> show(
    BuildContext context, {
    required TaskFilter initial,
    required List<(String, String)> lists,
    required List<(String, String)> groups,
    required List<(String, String)> categories,
    required List<(String, String)> tags,
  }) {
    return showModalBottomSheet<TaskFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        initial: initial,
        lists: lists,
        groups: groups,
        categories: categories,
        tags: tags,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<TaskStatus> _statuses;
  late Set<String> _listIds;
  late Set<String> _groupIds;
  late Set<String> _categoryIds;
  late Set<String> _tagIds;
  late Set<TaskPriority> _priorities;
  late DueDateKind? _dueKind;
  late String? _dueFrom;
  late String? _dueTo;
  late ReminderFilter _reminder;
  late RecurrenceFilter _recurrence;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _statuses = {...?initial.statuses};
    _listIds = {...?initial.listIds};
    _groupIds = {...?initial.groupIds};
    _categoryIds = {...?initial.categoryIds};
    _tagIds = {...?initial.tagIds};
    _priorities = {...?initial.priorities};
    _dueKind = initial.dueDateKind;
    _dueFrom = initial.dueDateFrom;
    _dueTo = initial.dueDateTo;
    _reminder = initial.reminderFilter ?? ReminderFilter.any;
    _recurrence = initial.recurrenceFilter ?? RecurrenceFilter.any;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(l10n.filtersTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _section(l10n.filterStatus, [
              _chip(l10n.filterActive, _statuses.contains(TaskStatus.active),
                  (v) => _toggle(_statuses, TaskStatus.active, v)),
              _chip(l10n.filterCompleted,
                  _statuses.contains(TaskStatus.completed),
                  (v) => _toggle(_statuses, TaskStatus.completed, v)),
            ]),
            _section(l10n.filterLists, [
              _chip(l10n.semLista, _listIds.contains(kNoList),
                  (v) => _toggle(_listIds, kNoList, v)),
              for (final (id, name) in widget.lists)
                _chip(name, _listIds.contains(id),
                    (v) => _toggle(_listIds, id, v)),
            ]),
            _section(l10n.filterGroups, [
              for (final (id, name) in widget.groups)
                _chip(name, _groupIds.contains(id),
                    (v) => _toggle(_groupIds, id, v)),
            ]),
            _section(l10n.filterCategories, [
              _chip(l10n.noCategory, _categoryIds.contains(kNoCategory),
                  (v) => _toggle(_categoryIds, kNoCategory, v)),
              for (final (id, name) in widget.categories)
                _chip(name, _categoryIds.contains(id),
                    (v) => _toggle(_categoryIds, id, v)),
            ]),
            _section(l10n.filterTags, [
              _chip(l10n.noTags, _tagIds.contains(kNoTags),
                  (v) => _toggle(_tagIds, kNoTags, v)),
              for (final (id, name) in widget.tags)
                _chip(name, _tagIds.contains(id),
                    (v) => _toggle(_tagIds, id, v)),
            ]),
            _section(l10n.filterPriority, [
              for (final priority in TaskPriority.values)
                _chip(_priorityLabel(l10n, priority),
                    _priorities.contains(priority),
                    (v) => _toggle(_priorities, priority, v)),
            ]),
            _section(l10n.filterDueDate, [
              for (final kind in DueDateKind.values)
                _chip(_dueLabel(l10n, kind), _dueKind == kind,
                    (v) => setState(() => _dueKind = v ? kind : null)),
            ]),
            if (_dueKind == DueDateKind.range)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueFrom == null ? l10n.noDueDate : _dueFrom!,
                    ),
                  ),
                  TextButton(
                    key: const Key('due-from-button'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked == null) return;
                      setState(() => _dueFrom = _iso(picked));
                    },
                    child: Text(l10n.dueDateLabel),
                  ),
                  TextButton(
                    key: const Key('due-to-button'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked == null) return;
                      setState(() => _dueTo = _iso(picked));
                    },
                    child: Text(l10n.clearDueDate),
                  ),
                ],
              ),
            _section(l10n.filterReminder, [
              for (final option in ReminderFilter.values)
                _chip(_reminderLabel(l10n, option), _reminder == option,
                    (v) => setState(() => _reminder = option)),
            ]),
            _section(l10n.filterRecurrence, [
              for (final option in RecurrenceFilter.values)
                _chip(_recurrenceLabel(l10n, option), _recurrence == option,
                    (v) => setState(() => _recurrence = option)),
            ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      const TaskFilter(),
                    ),
                    child: Text(l10n.clearFilters),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_build()),
                    child: Text(l10n.applyFilters),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TaskFilter _build() {
    return TaskFilter(
      statuses: _statuses.isEmpty ? null : _statuses,
      listIds: _listIds.isEmpty ? null : _listIds,
      groupIds: _groupIds.isEmpty ? null : _groupIds,
      categoryIds: _categoryIds.isEmpty ? null : _categoryIds,
      tagIds: _tagIds.isEmpty ? null : _tagIds,
      priorities: _priorities.isEmpty ? null : _priorities,
      dueDateKind: _dueKind,
      dueDateFrom: _dueFrom,
      dueDateTo: _dueTo,
      reminderFilter: _reminder,
      recurrenceFilter: _recurrence,
    );
  }

  String _iso(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _toggle<T>(Set<T> set, T value, bool selected) {
    setState(() {
      if (selected) {
        set.add(value);
      } else {
        set.remove(value);
      }
    });
  }

  Widget _section(String title, List<Widget> chips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: chips),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
    );
  }

  String _priorityLabel(AppLocalizations l10n, TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => l10n.priorityLow,
      TaskPriority.medium => l10n.priorityMedium,
      TaskPriority.high => l10n.priorityHigh,
      TaskPriority.urgent => l10n.priorityUrgent,
    };
  }

  String _dueLabel(AppLocalizations l10n, DueDateKind kind) {
    return switch (kind) {
      DueDateKind.none => l10n.dueNone,
      DueDateKind.overdue => l10n.dueOverdue,
      DueDateKind.today => l10n.dueToday,
      DueDateKind.next7Days => l10n.dueNext7,
      DueDateKind.range => l10n.dueRange,
    };
  }

  String _reminderLabel(AppLocalizations l10n, ReminderFilter option) {
    return switch (option) {
      ReminderFilter.any => l10n.reminderAny,
      ReminderFilter.withReminder => l10n.reminderWith,
      ReminderFilter.withoutReminder => l10n.reminderWithout,
    };
  }

  String _recurrenceLabel(AppLocalizations l10n, RecurrenceFilter option) {
    return switch (option) {
      RecurrenceFilter.any => l10n.recurrenceAny,
      RecurrenceFilter.active => l10n.recurrenceActive,
      RecurrenceFilter.cancelled => l10n.recurrenceCancelled,
      RecurrenceFilter.none => l10n.recurrenceNone,
    };
  }
}
