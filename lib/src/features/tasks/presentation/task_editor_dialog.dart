import 'package:flutter/material.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/device_format.dart';
import '../../../data/providers.dart';
import '../../notifications/presentation/permission_flow.dart';
import '../../organization/domain/organization.dart';
import '../../recurrence/domain/recurrence.dart';
import '../../organization/presentation/name_dialog.dart';
import '../domain/task.dart';

/// Diálogo de criação/edição de tarefa com lista, categoria e tags
/// (spec 01 RF-03; spec 02 RF-03/RF-08/RF-09).
Future<bool> showTaskEditorDialog(
  BuildContext context, {
  Task? task,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _TaskEditorDialog(task: task),
  );
  return result ?? false;
}

class _TaskEditorDialog extends ConsumerStatefulWidget {
  const _TaskEditorDialog({this.task});

  final Task? task;

  @override
  ConsumerState<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends ConsumerState<_TaskEditorDialog> {
  static const _noList = '';

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagController;
  String? _errorText;
  late String? _listId;
  late String? _categoryId;
  late List<Tag> _tags;
  late Priority _priority;
  DateTime? _dueDate;
  DateTime? _reminder;
  RecurrenceFrequency? _frequency;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title);
    _notesController = TextEditingController(text: task?.notes);
    _tagController = TextEditingController();
    _listId = task?.listId;
    _categoryId = task?.categoryId;
    _tags = List.of(task?.tags ?? const <Tag>[]);
    _priority = task?.priority ?? Priority.medium;
    _dueDate = task?.dueDate;
    _reminder = task?.reminder;
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final task = widget.task;
    if (task?.seriesId == null) return;
    final series = await ref
        .read(recurrenceRepositoryProvider)
        .getSeries(task!.seriesId!);
    if (!mounted) return;
    setState(() {
      if (series != null && series.active) _frequency = series.frequency;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final tasksService = ref.read(tasksServiceProvider);
    // Spec 08, CA-01: primeiro lembrete explica e pede autorização
    // antes de agendar; depois disso nenhum pedido automático (CA-02).
    if (_reminder != null && widget.task?.reminder == null && mounted) {
      await runFirstReminderPermissionFlow(context, ref);
    }
    if (!mounted) return;
    try {
      if (_isEditing) {
        final task = widget.task!;
        await tasksService.editTask(
          task.id,
          title: _titleController.text,
          notes: _notesController.text,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null && task.dueDate != null,
          reminder: _reminder,
          clearReminder: _reminder == null && task.reminder != null,
        );
        await tasksService.moveTaskToList(task.id, _listId);
        await tasksService.setTaskCategory(task.id, _categoryId);
        await tasksService.setTaskTags(task.id, _tags);
        await tasksService.setRecurrence(task.id, _frequency);
      } else {
        final id = await tasksService.createTask(
          title: _titleController.text,
          notes: _notesController.text,
          listId: _listId,
          categoryId: _categoryId,
          priority: _priority,
          dueDate: _dueDate,
          reminder: _reminder,
        );
        if (_tags.isNotEmpty) {
          await tasksService.setTaskTags(id, _tags);
        }
        await tasksService.setRecurrence(id, _frequency);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on InvalidTitleException {
      if (mounted) setState(() => _errorText = l10n.titleRequired);
    } on ReminderInPastException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.reminderInPast)));
      }
    } on RecurrenceRequiresDueDateException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recurrenceRequiresDueDate)),
        );
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
        Navigator.of(context).pop(false);
      }
    }
  }

  Future<void> _addTag() async {
    final raw = _tagController.text;
    if (raw.trim().isEmpty) return;
    final org = ref.read(organizationServiceProvider);
    try {
      final tag = await org.ensureTag(raw);
      if (_tags.any((t) => t.id == tag.id)) {
        _tagController.clear();
        return;
      }
      setState(() => _tags = [..._tags, tag]);
      _tagController.clear();
    } catch (error) {
      if (mounted) showDomainError(context, error);
    }
  }

  Future<void> _addCategory() async {
    final l10n = AppLocalizations.of(context);
    final name = await showNameDialog(context, title: l10n.newCategory);
    if (name == null || !mounted) return;
    final org = ref.read(organizationServiceProvider);
    try {
      final id = await org.createCategory(name);
      setState(() => _categoryId = id);
    } catch (error) {
      if (mounted) showDomainError(context, error);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminder?.toLocal() ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminder?.toLocal() ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _reminder = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ).toUtc();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];

    return AlertDialog(
      title: Text(_isEditing ? l10n.edit : l10n.addTask),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.taskTitleLabel,
                  hintText: l10n.taskTitleHint,
                  errorText: _errorText,
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.notesLabel,
                  hintText: l10n.notesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _listId ?? _noList,
                decoration: InputDecoration(
                  labelText: l10n.listLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: _noList, child: Text(l10n.noList)),
                  for (final list in lists)
                    DropdownMenuItem(
                      value: list.id,
                      child: Text(list.name),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _listId = (value == null || value == _noList)
                      ? null
                      : value,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoryId ?? _noList,
                      decoration: InputDecoration(
                        labelText: l10n.categoryLabel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: _noList,
                          child: Text(l10n.noCategory),
                        ),
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => setState(
                        () => _categoryId = (value == null || value == _noList)
                            ? null
                            : value,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.newCategory,
                    icon: const Icon(Icons.add),
                    onPressed: _addCategory,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                initialValue: _priority,
                decoration: InputDecoration(
                  labelText: l10n.priorityLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final priority in Priority.values)
                    DropdownMenuItem(
                      value: priority,
                      child: Text(switch (priority) {
                        Priority.low => l10n.priorityLow,
                        Priority.medium => l10n.priorityMedium,
                        Priority.high => l10n.priorityHigh,
                        Priority.urgent => l10n.priorityUrgent,
                      }),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _priority = value ?? Priority.medium,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: l10n.dueDateLabel,
                      emptyText: l10n.noDueDate,
                      valueText: _dueDate == null
                          ? null
                          : formatDeviceDate(_dueDate!),
                      onPick: _pickDueDate,
                      onClear: _dueDate == null
                          ? null
                          : () => setState(() => _dueDate = null),
                      clearTooltip: l10n.clearDueDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateField(
                      label: l10n.reminderLabel,
                      emptyText: l10n.noReminder,
                      valueText: _reminder == null
                          ? null
                          : formatDeviceDateTime(_reminder!),
                      onPick: _pickReminder,
                      onClear: _reminder == null
                          ? null
                          : () => setState(() => _reminder = null),
                      clearTooltip: l10n.clearReminder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RecurrenceFrequency?>(
                initialValue: _frequency,
                decoration: InputDecoration(
                  labelText: l10n.recurrenceLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.recurrenceNone),
                  ),
                  for (final frequency in RecurrenceFrequency.values)
                    DropdownMenuItem(
                      value: frequency,
                      child: Text(switch (frequency) {
                        RecurrenceFrequency.daily => l10n.recurrenceDaily,
                        RecurrenceFrequency.weekdays => l10n.recurrenceWeekdays,
                        RecurrenceFrequency.weekly => l10n.recurrenceWeekly,
                        RecurrenceFrequency.monthly => l10n.recurrenceMonthly,
                        RecurrenceFrequency.yearly => l10n.recurrenceYearly,
                      }),
                    ),
                ],
                onChanged: (value) => setState(() => _frequency = value),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.tagsLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in _tags)
                        Chip(
                          label: Text(tag.name),
                          onDeleted: () => setState(
                            () => _tags =
                                _tags.where((t) => t.id != tag.id).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: l10n.addTagHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l10n.addTagHint,
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.emptyText,
    required this.valueText,
    required this.onPick,
    required this.onClear,
    required this.clearTooltip,
  });

  final String label;
  final String emptyText;
  final String? valueText;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String clearTooltip;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: clearTooltip,
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(valueText ?? emptyText),
      ),
    );
  }
}
