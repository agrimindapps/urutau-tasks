import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../../../data/providers.dart';
import '../../organization/domain/organization.dart';
import '../../search/domain/task_query.dart';
import '../../tasks/domain/task.dart';

/// Abre a folha de filtros combináveis (spec 05, RF-08 a RF-15).
/// Retorna os filtros estruturados atualizados ou `null` ao cancelar.
Future<TaskFilters?> showFilterSheet(
  BuildContext context, {
  required TaskFilters current,
}) {
  return showModalBottomSheet<TaskFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});

  final TaskFilters initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TaskFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  void _update(TaskFilters Function(TaskFilters) transform) {
    setState(() => _filters = transform(_filters));
  }

  Set<TaskStatus> _toggleStatus(Set<TaskStatus> set, TaskStatus value) {
    final next = Set<TaskStatus>.of(set);
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  Set<T> _toggle<T>(Set<T> set, T value) {
    final next = Set<T>.of(set);
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _filters.customDueStart : _filters.customDueEnd) ??
        _filters.customDueStart ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final date = DateTime(picked.year, picked.month, picked.day);
    if (isStart) {
      _update((f) => f.copyWith(customDueStart: date));
    } else {
      _update((f) => f.copyWith(customDueEnd: date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final groups = ref.watch(groupsProvider).value ?? const <Group>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  _Section(
                    title: l10n.statusSection,
                    children: [
                      _chip(
                        l10n.filterActive,
                        selected: _filters.statuses.contains(TaskStatus.active),
                        onTap: () => _update(
                          (f) => f.copyWith(
                            statuses: _toggleStatus(
                                f.statuses, TaskStatus.active),
                          ),
                        ),
                      ),
                      _chip(
                        l10n.filterCompleted,
                        selected:
                            _filters.statuses.contains(TaskStatus.completed),
                        onTap: () => _update(
                          (f) => f.copyWith(
                            statuses: _toggleStatus(
                                f.statuses, TaskStatus.completed),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n.listsSectionFilter,
                    children: [
                      _chip(
                        l10n.noList,
                        selected: _filters.listIds.contains(null),
                        onTap: () => _update(
                          (f) => f.copyWith(listIds: _toggle(f.listIds, null)),
                        ),
                      ),
                      for (final list in lists)
                        _chip(
                          list.name,
                          selected: _filters.listIds.contains(list.id),
                          onTap: () => _update(
                            (f) =>
                                f.copyWith(listIds: _toggle(f.listIds, list.id)),
                          ),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.groupsSectionFilter,
                    children: [
                      for (final group in groups)
                        _chip(
                          group.name,
                          selected: _filters.groupIds.contains(group.id),
                          onTap: () => _update(
                            (f) => f.copyWith(
                                groupIds: _toggle(f.groupIds, group.id)),
                          ),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.categoriesSectionFilter,
                    children: [
                      _chip(
                        l10n.noCategory,
                        selected: _filters.categoryIds.contains(null),
                        onTap: () => _update(
                          (f) => f.copyWith(
                              categoryIds: _toggle(f.categoryIds, null)),
                        ),
                      ),
                      for (final category in categories)
                        _chip(
                          category.name,
                          selected:
                              _filters.categoryIds.contains(category.id),
                          onTap: () => _update(
                            (f) => f.copyWith(
                                categoryIds:
                                    _toggle(f.categoryIds, category.id)),
                          ),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.tagsSectionFilter,
                    children: [
                      _chip(
                        l10n.noTags,
                        selected: _filters.noTags,
                        onTap: () =>
                            _update((f) => f.copyWith(noTags: !f.noTags)),
                      ),
                      for (final tag in tags)
                        _chip(
                          tag.name,
                          selected: _filters.tagIds.contains(tag.id),
                          onTap: () => _update(
                            (f) => f.copyWith(tagIds: _toggle(f.tagIds, tag.id)),
                          ),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.prioritySection,
                    children: [
                      for (final priority in Priority.values)
                        _chip(
                          switch (priority) {
                            Priority.low => l10n.priorityLow,
                            Priority.medium => l10n.priorityMedium,
                            Priority.high => l10n.priorityHigh,
                            Priority.urgent => l10n.priorityUrgent,
                          },
                          selected: _filters.priorities.contains(priority),
                          onTap: () => _update(
                            (f) =>
                                f.copyWith(priorities: _toggle(f.priorities, priority)),
                          ),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.dueSection,
                    children: [
                      for (final due in DueFilter.values)
                        _chip(
                          switch (due) {
                            DueFilter.none => l10n.noDueDate,
                            DueFilter.overdue => l10n.dueOverdue,
                            DueFilter.today => l10n.dueToday,
                            DueFilter.next7Days => l10n.dueNext7,
                            DueFilter.customRange => l10n.dueCustom,
                          },
                          selected: _filters.due == due,
                          onTap: () => _update((f) => f.copyWith(
                                due: f.due == due ? null : due,
                                clearDue: f.due == due,
                              )),
                        ),
                      if (_filters.due == DueFilter.customRange) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event, size: 18),
                                label: Text(
                                  _filters.customDueStart == null
                                      ? l10n.dueFrom
                                      : MaterialLocalizations.of(context)
                                          .formatCompactDate(
                                              _filters.customDueStart!),
                                ),
                                onPressed: () => _pickDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event, size: 18),
                                label: Text(
                                  _filters.customDueEnd == null
                                      ? l10n.dueTo
                                      : MaterialLocalizations.of(context)
                                          .formatCompactDate(
                                              _filters.customDueEnd!),
                                ),
                                onPressed: () => _pickDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  _Section(
                    title: l10n.reminderSection,
                    children: [
                      for (final reminder in ReminderFilter.values)
                        _chip(
                          reminder == ReminderFilter.withReminder
                              ? l10n.reminderWith
                              : l10n.reminderWithout,
                          selected: _filters.reminder == reminder,
                          onTap: () => _update((f) => f.copyWith(
                                reminder: f.reminder == reminder
                                    ? null
                                    : reminder,
                              )),
                        ),
                    ],
                  ),
                  _Section(
                    title: l10n.recurrenceSection,
                    children: [
                      for (final recurrence in RecurrenceFilter.values)
                        _chip(
                          switch (recurrence) {
                            RecurrenceFilter.active =>
                              l10n.recurrenceWithActive,
                            RecurrenceFilter.none => l10n.recurrenceWithout,
                            RecurrenceFilter.canceled =>
                              l10n.recurrenceCanceled,
                          },
                          selected: _filters.recurrence == recurrence,
                          onTap: () => _update((f) => f.copyWith(
                                recurrence: f.recurrence == recurrence
                                    ? null
                                    : recurrence,
                              )),
                        ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pop(const TaskFilters()), // limpar tudo
                    child: Text(l10n.clearFilters),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_filters),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(children: children),
        ],
      ),
    );
  }
}
