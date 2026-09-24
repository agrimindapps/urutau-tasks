// Prazos, lembretes e recorrência (spec 04).
import 'dart:math';

/// Exceção: lembrete no passado é rejeitado (spec 04, RF-04 / CA-05).
class ReminderInPastException implements Exception {
  const ReminderInPastException();

  @override
  String toString() => 'Reminder must be in the future.';
}

/// Exceção: recorrência exige prazo (spec 04, RF-07 / CA-18).
class RecurrenceRequiresDueDateException implements Exception {
  const RecurrenceRequiresDueDateException();

  @override
  String toString() => 'Recurrence requires a due date.';
}

/// Frequências fixas do MVP (spec 04, RF-08).
enum RecurrenceFrequency {
  daily,
  weekdays,
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency parse(String raw) => switch (raw) {
        'weekdays' => RecurrenceFrequency.weekdays,
        'weekly' => RecurrenceFrequency.weekly,
        'monthly' => RecurrenceFrequency.monthly,
        'yearly' => RecurrenceFrequency.yearly,
        _ => RecurrenceFrequency.daily,
      };

  String get storedName => switch (this) {
        RecurrenceFrequency.daily => 'daily',
        RecurrenceFrequency.weekdays => 'weekdays',
        RecurrenceFrequency.weekly => 'weekly',
        RecurrenceFrequency.monthly => 'monthly',
        RecurrenceFrequency.yearly => 'yearly',
      };
}

/// Série recorrente ancorada no calendário original (spec 04, RF-07/RF-10).
class RecurrenceSeries {
  RecurrenceSeries({
    required this.id,
    required this.frequency,
    required String anchorDate,
    this.active = true,
  }) : anchorDate = _normalizeAnchor(anchorDate);

  final String id;
  final RecurrenceFrequency frequency;

  /// Data-base `yyyy-MM-dd` da série (spec 04, RF-07).
  final String anchorDate;

  /// Séries continuam ativas até cancelamento manual (RF-10).
  final bool active;

  static String _normalizeAnchor(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.split('-').length != 3) {
      throw const FormatException('Invalid anchor date');
    }
    return trimmed;
  }

  RecurrenceSeries copyWith({
    RecurrenceFrequency? frequency,
    String? anchorDate,
    bool? active,
  }) =>
      RecurrenceSeries(
        id: id,
        frequency: frequency ?? this.frequency,
        anchorDate: anchorDate ?? this.anchorDate,
        active: active ?? this.active,
      );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceSeries &&
      other.id == id &&
      other.frequency == frequency &&
      other.anchorDate == anchorDate &&
      other.active == active;

  @override
  int get hashCode => Object.hash(id, frequency, anchorDate, active);
}

DateTime _dateOnly(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Dia do mês com clamp para meses mais curtos (spec 04, RF-09 / CA-10):
/// 31 em fevereiro → último dia do mês; 29/02 em ano não bissexto → 28.
DateTime _dayInMonth(int year, int month, int day) =>
    DateTime(year, month, min(day, _daysInMonth(year, month)));

/// Primeira data estritamente posterior a [from] conforme a regra,
/// sempre ancorada no calendário original (spec 04, RF-08/RF-09).
DateTime _stepAfter(DateTime from, DateTime anchor, RecurrenceFrequency f) {
  return switch (f) {
    RecurrenceFrequency.daily => from.add(const Duration(days: 1)),
    RecurrenceFrequency.weekdays => _nextWeekday(from),
    RecurrenceFrequency.weekly => _nextSameWeekday(from, anchor.weekday),
    RecurrenceFrequency.monthly => _nextMonthly(from, anchor),
    RecurrenceFrequency.yearly => _nextYearly(from, anchor),
  };
}

DateTime _nextWeekday(DateTime from) {
  var candidate = from.add(const Duration(days: 1));
  while (candidate.weekday == DateTime.saturday ||
      candidate.weekday == DateTime.sunday) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

DateTime _nextSameWeekday(DateTime from, int weekday) {
  var candidate = from.add(const Duration(days: 1));
  while (candidate.weekday != weekday) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

DateTime _nextMonthly(DateTime from, DateTime anchor) {
  final anchorDay = anchor.day;
  var year = from.year;
  var month = from.month;
  for (var i = 0; i < 24; i++) {
    month += 1;
    if (month > 12) {
      month = 1;
      year += 1;
    }
    final candidate = _dayInMonth(year, month, anchorDay);
    if (candidate.isAfter(from)) return candidate;
  }
  return _dayInMonth(year + 1, month, anchorDay);
}

DateTime _nextYearly(DateTime from, DateTime anchor) {
  for (var i = 0; i < 8; i++) {
    final year = from.year + 1 + i;
    final candidate = _dayInMonth(year, anchor.month, anchor.day);
    if (candidate.isAfter(from)) return candidate;
  }
  return _dayInMonth(from.year + 9, anchor.month, anchor.day);
}

/// Calcula a próxima ocorrência futura (spec 04, RF-11/RF-12 / CA-11/CA-15).
///
/// A partir da data atual ([fromDue], a data-base da ocorrência em edição),
/// avança pela regra até encontrar a primeira data maior ou igual a [today].
/// Não gera ocorrências retroativas em lote (CA-15).
DateTime? nextOccurrenceDate({
  required DateTime fromDue,
  required DateTime anchor,
  required RecurrenceFrequency frequency,
  required DateTime today,
}) {
  final from = _dateOnly(fromDue);
  final limit = _dateOnly(today);
  var candidate = _stepAfter(from, anchor, frequency);
  var guard = 0;
  while (candidate.isBefore(limit) && guard < 10000) {
    candidate = _stepAfter(candidate, anchor, frequency);
    guard += 1;
  }
  if (guard >= 10000) return null;
  return candidate;
}

/// Calcula o novo lembrete preservando a relação temporal com o prazo
/// (spec 04, RF-13 / CA-13). Se o resultado já passou, é mantido como
/// vencido, sem notificação imediata (RF-13).
DateTime? inheritReminder({
  required DateTime? oldReminder,
  required DateTime oldDue,
  required DateTime newDue,
}) {
  if (oldReminder == null) return null;
  final oldDueInstant = _dateOnly(oldDue);
  final offset = oldReminder.difference(oldDueInstant);
  return _dateOnly(newDue).add(offset);
}
