import 'task.dart';

/// Returns the first occurrence date after [currentDueDateIso] that is also
/// strictly later than [todayIso], keeping the series anchored to its original
/// calendar date for monthly and yearly rules.
String nextOccurrenceDueDate({
  required RecurrenceFrequency frequency,
  required String anchorDueDateIso,
  required String currentDueDateIso,
  required String todayIso,
}) {
  final anchor = parseDateOnly(anchorDueDateIso);
  final current = parseDateOnly(currentDueDateIso);
  final today = parseDateOnly(todayIso);
  late DateTime candidate;

  switch (frequency) {
    case RecurrenceFrequency.daily:
      candidate = current.add(const Duration(days: 1));
      while (!candidate.isAfter(today)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    case RecurrenceFrequency.weekdays:
      candidate = current.add(const Duration(days: 1));
      while (candidate.weekday > DateTime.friday ||
          candidate.weekday < DateTime.monday ||
          !candidate.isAfter(today)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    case RecurrenceFrequency.weekly:
      candidate = current.add(const Duration(days: 7));
      while (!candidate.isAfter(today)) {
        candidate = candidate.add(const Duration(days: 7));
      }
    case RecurrenceFrequency.monthly:
      var monthsAfterAnchor =
          (current.year - anchor.year) * 12 + current.month - anchor.month + 1;
      candidate = _monthlyAnchorDate(anchor, monthsAfterAnchor);
      while (!candidate.isAfter(today)) {
        monthsAfterAnchor++;
        candidate = _monthlyAnchorDate(anchor, monthsAfterAnchor);
      }
    case RecurrenceFrequency.yearly:
      var yearsAfterAnchor = current.year - anchor.year + 1;
      candidate = _yearlyAnchorDate(anchor, yearsAfterAnchor);
      while (!candidate.isAfter(today)) {
        yearsAfterAnchor++;
        candidate = _yearlyAnchorDate(anchor, yearsAfterAnchor);
      }
  }

  return formatDateOnly(candidate);
}

DateTime _monthlyAnchorDate(DateTime anchor, int monthsAfterAnchor) {
  final firstOfMonth = DateTime.utc(
    anchor.year,
    anchor.month + monthsAfterAnchor,
    1,
  );
  final lastDay = DateTime.utc(
    firstOfMonth.year,
    firstOfMonth.month + 1,
    0,
  ).day;
  return DateTime.utc(
    firstOfMonth.year,
    firstOfMonth.month,
    anchor.day < lastDay ? anchor.day : lastDay,
  );
}

DateTime _yearlyAnchorDate(DateTime anchor, int yearsAfterAnchor) {
  final year = anchor.year + yearsAfterAnchor;
  final lastDay = DateTime.utc(year, anchor.month + 1, 0).day;
  return DateTime.utc(
    year,
    anchor.month,
    anchor.day < lastDay ? anchor.day : lastDay,
  );
}
