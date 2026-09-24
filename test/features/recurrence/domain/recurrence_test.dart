import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';

void main() {
  final anchor = DateTime(2026, 1, 15);

  DateTime next({
    required DateTime fromDue,
    RecurrenceFrequency frequency = RecurrenceFrequency.daily,
    DateTime? anchorDate,
    required DateTime today,
  }) {
    final result = nextOccurrenceDate(
      fromDue: fromDue,
      anchor: anchorDate ?? anchor,
      frequency: frequency,
      today: today,
    );
    expect(result, isNotNull);
    return result!;
  }

  group('RF-08 — frequências do MVP (CA-09)', () {
    test('diária avança um dia', () {
      expect(
        next(
          fromDue: DateTime(2026, 9, 24),
          today: DateTime(2026, 9, 24),
        ),
        DateTime(2026, 9, 25),
      );
    });

    test('dias úteis pula sábado e domingo', () {
      // 2026-09-25 é sexta; a próxima é segunda 28/09.
      expect(DateTime(2026, 9, 25).weekday, DateTime.friday);
      expect(
        next(
          fromDue: DateTime(2026, 9, 25),
          frequency: RecurrenceFrequency.weekdays,
          today: DateTime(2026, 9, 25),
        ),
        DateTime(2026, 9, 28),
      );
    });

    test('semanal mantém o dia da semana da data-base', () {
      // Data-base 15/01/2026 = quinta-feira.
      expect(anchor.weekday, DateTime.thursday);
      final result = next(
        fromDue: DateTime(2026, 9, 24),
        frequency: RecurrenceFrequency.weekly,
        today: DateTime(2026, 9, 24),
      );
      expect(result.weekday, DateTime.thursday);
      expect(result.isAfter(DateTime(2026, 9, 24)), isTrue);
    });

    test('mensal mantém o dia do mês da data-base', () {
      expect(
        next(
          fromDue: DateTime(2026, 9, 15),
          frequency: RecurrenceFrequency.monthly,
          today: DateTime(2026, 9, 15),
        ),
        DateTime(2026, 10, 15),
      );
    });

    test('anual mantém mês e dia da data-base', () {
      expect(
        next(
          fromDue: DateTime(2026, 9, 15),
          frequency: RecurrenceFrequency.yearly,
          anchorDate: DateTime(2026, 9, 15),
          today: DateTime(2026, 9, 15),
        ),
        DateTime(2027, 9, 15),
      );
    });
  });

  group('RF-09 / CA-10 — datas de calendário', () {
    test('CA-10 mensal 31 usa o último dia de fevereiro', () {
      final result = next(
        fromDue: DateTime(2026, 1, 31),
        frequency: RecurrenceFrequency.monthly,
        anchorDate: DateTime(2026, 1, 31),
        today: DateTime(2026, 1, 31),
      );
      expect(result, DateTime(2026, 2, 28));
    });

    test('CA-10 mensal volta ao dia 31 em meses com 31 dias', () {
      final result = next(
        fromDue: DateTime(2026, 3, 31),
        frequency: RecurrenceFrequency.monthly,
        anchorDate: DateTime(2026, 1, 31),
        today: DateTime(2026, 3, 31),
      );
      expect(result, DateTime(2026, 4, 30));
      final backTo31 = next(
        fromDue: result,
        frequency: RecurrenceFrequency.monthly,
        anchorDate: DateTime(2026, 1, 31),
        today: DateTime(2026, 4, 30),
      );
      expect(backTo31, DateTime(2026, 5, 31));
    });

    test('CA-10 anual 29/02 usa 28/02 em ano não bissexto', () {
      final result = next(
        fromDue: DateTime(2024, 2, 29),
        frequency: RecurrenceFrequency.yearly,
        anchorDate: DateTime(2024, 2, 29),
        today: DateTime(2024, 2, 29),
      );
      expect(result, DateTime(2025, 2, 28));
    });

    test('CA-10 anual 29/02 usa 29/02 em ano bissexto', () {
      final result = next(
        fromDue: DateTime(2024, 2, 29),
        frequency: RecurrenceFrequency.yearly,
        anchorDate: DateTime(2024, 2, 29),
        today: DateTime(2027, 6, 1),
      );
      expect(result, DateTime(2028, 2, 29));
    });
  });

  group('RF-11 / CA-15 — próxima ocorrência futura', () {
    test('CA-15 avança até hoje sem gerar retroativas em lote', () {
      final result = next(
        fromDue: DateTime(2026, 9, 20),
        today: DateTime(2026, 9, 24),
      );
      expect(result, DateTime(2026, 9, 24));
    });

    test('datas passadas não criam ocorrências anteriores a hoje', () {
      final result = next(
        fromDue: DateTime(2026, 1, 1),
        frequency: RecurrenceFrequency.monthly,
        anchorDate: DateTime(2026, 1, 1),
        today: DateTime(2026, 9, 24),
      );
      expect(result, DateTime(2026, 10, 1));
      expect(result.isBefore(DateTime(2026, 9, 24)), isFalse);
    });
  });

  group('RF-13 / CA-13 — herança de lembrete', () {
    test('CA-13 preserva a relação com o novo prazo', () {
      final oldDue = DateTime(2026, 9, 20);
      final newDue = DateTime(2026, 9, 27);
      final oldReminder = DateTime(2026, 9, 20, 9, 30); // 09:30 local

      final inherited = inheritReminder(
        oldReminder: oldReminder,
        oldDue: oldDue,
        newDue: newDue,
      );

      expect(inherited, DateTime(2026, 9, 27, 9, 30));
    });

    test('sem lembrete não herda nada', () {
      expect(
        inheritReminder(
          oldReminder: null,
          oldDue: DateTime(2026, 9, 20),
          newDue: DateTime(2026, 9, 27),
        ),
        isNull,
      );
    });

    test('resultado vencido é mantido como expirado (RF-13)', () {
      final inherited = inheritReminder(
        oldReminder: DateTime(2026, 9, 20, 8),
        oldDue: DateTime(2026, 9, 20),
        newDue: DateTime(2026, 9, 22),
      );
      expect(inherited, DateTime(2026, 9, 22, 8));
      expect(inherited!.isBefore(DateTime(2026, 9, 24)), isTrue);
    });
  });
}
