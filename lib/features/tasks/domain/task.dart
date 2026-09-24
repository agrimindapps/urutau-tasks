enum TaskStatus {
  active(0),
  completed(1),
  trashed(2);

  const TaskStatus(this.databaseValue);

  final int databaseValue;

  static TaskStatus fromDatabaseValue(int value) => switch (value) {
    0 => TaskStatus.active,
    1 => TaskStatus.completed,
    2 => TaskStatus.trashed,
    _ => throw StateError('Unknown task status: $value'),
  };
}

enum TaskPriority {
  none(0),
  low(1),
  medium(2),
  high(3),
  urgent(4);

  const TaskPriority(this.databaseValue);

  final int databaseValue;

  static TaskPriority fromDatabaseValue(int value) => switch (value) {
    0 => TaskPriority.none,
    1 => TaskPriority.low,
    2 => TaskPriority.medium,
    3 => TaskPriority.high,
    4 => TaskPriority.urgent,
    _ => throw StateError('Unknown task priority: $value'),
  };
}

enum RecurrenceFrequency {
  daily(0),
  weekdays(1),
  weekly(2),
  monthly(3),
  yearly(4);

  const RecurrenceFrequency(this.databaseValue);

  final int databaseValue;

  static RecurrenceFrequency fromDatabaseValue(int value) => switch (value) {
    0 => RecurrenceFrequency.daily,
    1 => RecurrenceFrequency.weekdays,
    2 => RecurrenceFrequency.weekly,
    3 => RecurrenceFrequency.monthly,
    4 => RecurrenceFrequency.yearly,
    _ => throw StateError('Unknown recurrence frequency: $value'),
  };
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.position,
    this.notes,
    this.listId,
    this.categoryId,
    this.dueDateIso,
    this.reminderAtUtc,
    this.recurringSeriesId,
    this.recurrenceFrequency,
    this.recurrenceActive = false,
    this.completedAtUtc,
    this.statusBeforeTrash,
    this.deletedAtUtc,
  });

  final String id;
  final String title;
  final String? notes;
  final TaskStatus status;
  final TaskPriority priority;
  final String? listId;
  final String? categoryId;
  final String? dueDateIso;
  final DateTime? reminderAtUtc;
  final String? recurringSeriesId;
  final RecurrenceFrequency? recurrenceFrequency;
  final bool recurrenceActive;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? completedAtUtc;
  final int position;
  final TaskStatus? statusBeforeTrash;
  final DateTime? deletedAtUtc;
}

class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.position,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int position;
}

class InvalidTitleException implements Exception {
  const InvalidTitleException();
}

class TaskNotFoundException implements Exception {
  const TaskNotFoundException();
}

class TaskUnavailableException implements Exception {
  const TaskUnavailableException();
}

class InvalidDateOnlyException implements Exception {
  const InvalidDateOnlyException();
}

class ReminderMustBeFutureException implements Exception {
  const ReminderMustBeFutureException();
}

class TaskRecurrenceRequiresDueDateException implements Exception {
  const TaskRecurrenceRequiresDueDateException();
}

class TaskRecurrenceHistoryException implements Exception {
  const TaskRecurrenceHistoryException();
}

String normalizeRequiredTitle(String title) {
  final normalized = title.trim();
  if (normalized.isEmpty) {
    throw const InvalidTitleException();
  }
  return normalized;
}

String formatDateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String normalizeDateOnly(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw const InvalidDateOnlyException();
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  // Date-only values represent Gregorian calendar fields, not local midnight.
  // UTC construction prevents a local time-zone transition from normalizing
  // an otherwise valid date to a different day.
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw const InvalidDateOnlyException();
  }
  return value;
}

DateTime parseDateOnly(String value) {
  final normalized = normalizeDateOnly(value);
  final parts = normalized.split('-').map(int.parse).toList(growable: false);
  return DateTime.utc(parts[0], parts[1], parts[2]);
}
