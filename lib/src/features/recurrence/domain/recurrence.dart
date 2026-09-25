/// Domínio de recorrência — séries e ocorrências (spec 04, RF-07 a RF-13).
///
/// Datas de calendário local (`YYYY-MM-DD`), calculadas sempre no
/// calendário original da série (RF-09).
library;

import '../../tasks/domain/task.dart';

/// Frequências essenciais do MVP (spec 04, RF-08).
enum RecurrenceFrequency {
  /// Diária.
  daily,

  /// Dias úteis (seg–sex).
  weekdays,

  /// Semanal, mesmo dia da semana.
  weekly,

  /// Mensal, mesmo dia do mês com ajuste para o último dia válido.
  monthly,

  /// Anual, mesmo mês/dia com ajuste para anos não bissextos.
  annual,
}

/// Falhas de recorrência e lembrete.
enum RecurrenceFailure {
  /// Recorrência exige prazo como data-base da série (spec 04, RF-07).
  dueDateRequired,

  /// Série inexistente.
  unknownSeries,

  /// Série já cancelada.
  seriesCancelled,

  /// Lembrete no passado é rejeitado (spec 04, RF-04).
  reminderInPast,
}

class RecurrenceException implements Exception {
  const RecurrenceException(this.failure);

  final RecurrenceFailure failure;

  @override
  String toString() => 'RecurrenceException(${failure.name})';
}

/// Série recorrente ancorada no calendário original (spec 04, RF-09/RF-10).
class RecurringSeries {
  const RecurringSeries({
    required this.id,
    required this.frequency,
    required this.baseDate,
    required this.cancelled,
  });

  factory RecurringSeries.create({
    required String id,
    required RecurrenceFrequency frequency,
    required String baseDate,
  }) {
    return RecurringSeries(
      id: id,
      frequency: frequency,
      baseDate: baseDate,
      cancelled: false,
    );
  }

  final String id;
  final RecurrenceFrequency frequency;

  /// Data-base da série em `YYYY-MM-DD` (o prazo da ocorrência original).
  final String baseDate;

  /// Cancelamento manual impede novas ocorrências (spec 04, RF-10).
  final bool cancelled;

  RecurringSeries copyWith({
    RecurrenceFrequency? frequency,
    String? baseDate,
    bool? cancelled,
  }) {
    return RecurringSeries(
      id: id,
      frequency: frequency ?? this.frequency,
      baseDate: baseDate ?? this.baseDate,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  RecurringSeries cancel() => copyWith(cancelled: true);

  /// Próxima data da série estritamente após [after], sem retroativas
  /// (spec 04, RF-11/RF-12).
  String nextDateAfter(String after) {
    return nextOccurrenceDate(
      base: baseDate,
      frequency: frequency,
      after: after,
    );
  }
}

/// Data da ocorrência de índice [n] (0 = data-base), no calendário original.
String occurrenceDateAt({
  required String base,
  required RecurrenceFrequency frequency,
  required int n,
}) {
  final start = _parseDate(base);
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return _formatDate(start.add(Duration(days: n)));

    case RecurrenceFrequency.weekdays:
      var date = start;
      for (var i = 0; i < n; i++) {
        date = _nextWeekday(date);
      }
      return _formatDate(date);

    case RecurrenceFrequency.weekly:
      return _formatDate(start.add(Duration(days: 7 * n)));

    case RecurrenceFrequency.monthly:
      final monthIndex = start.year * 12 + (start.month - 1) + n;
      final year = monthIndex ~/ 12;
      final month = monthIndex % 12 + 1;
      return _formatDate(
        DateTime.utc(year, month, _min(start.day, _daysInMonth(year, month))),
      );

    case RecurrenceFrequency.annual:
      final year = start.year + n;
      return _formatDate(
        DateTime.utc(
          year,
          start.month,
          _min(start.day, _daysInMonth(year, start.month)),
        ),
      );
  }
}

/// Menor data da série estritamente após [after] (spec 04, RF-11/RF-12).
///
/// A série é calculada do calendário original; datas do passado são
/// puladas em bloco, gerando apenas a próxima ocorrência futura.
String nextOccurrenceDate({
  required String base,
  required RecurrenceFrequency frequency,
  required String after,
}) {
  var n = 0;
  // Limite generoso: mais de 200 anos de ocorrências diárias.
  while (n < 100000) {
    final date = occurrenceDateAt(base: base, frequency: frequency, n: n);
    if (date.compareTo(after) > 0) {
      return date;
    }
    n++;
  }
  throw StateError('Série sem próxima data após $after');
}

DateTime _parseDate(String iso) => DateTime.parse(iso);

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int _daysInMonth(int year, int month) {
  final firstOfNext = month == 12
      ? DateTime.utc(year + 1, 1, 1)
      : DateTime.utc(year, month + 1, 1);
  return firstOfNext.subtract(const Duration(days: 1)).day;
}

int _min(int a, int b) => a < b ? a : b;

DateTime _nextWeekday(DateTime date) {
  var next = date.add(const Duration(days: 1));
  // 6 = sábado, 7 = domingo em DateTime.weekday (seg=1 ... dom=7).
  while (next.weekday > 5) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}

/// Constrói a próxima ocorrência da série a partir da concluída
/// (spec 04, RF-11).
///
/// A ocorrência nasce ativa, **sem subtarefas** (CA-12), com prazo
/// calculado no calendário original e lembrete herdado recalculado pela
/// relação temporal com o prazo (RF-13); se o lembrete herdado cair no
/// passado, fica registrado como vencido, sem alerta imediato.
///
/// Retorna `null` quando a série está cancelada ou a concluída não tem
/// prazo. [today] é a data local de hoje (`YYYY-MM-DD`): a próxima
/// ocorrência é sempre futura, sem retroativas em lote.
Task? buildNextOccurrence({
  required Task completed,
  required RecurringSeries series,
  required String today,
  required DateTime now,
  required String id,
  int position = 0,
}) {
  if (series.cancelled) return null;
  final dueDate = completed.dueDate;
  if (dueDate == null) return null;

  final anchor = dueDate.compareTo(today) >= 0 ? dueDate : today;
  final nextDate = series.nextDateAfter(anchor);

  DateTime? nextReminder;
  final reminder = completed.reminder;
  if (reminder != null) {
    final dueInstant = DateTime.parse(dueDate);
    final offset = reminder.difference(dueInstant);
    nextReminder = DateTime.parse(nextDate).add(offset).toUtc();
  }

  return Task.create(
    id: id,
    title: completed.title,
    notes: completed.notes,
    createdAt: now,
    position: position,
    listId: completed.listId,
    categoryId: completed.categoryId,
    tagIds: completed.tagIds,
    priority: completed.priority,
    dueDate: nextDate,
    reminder: nextReminder,
    seriesId: series.id,
  );
}
