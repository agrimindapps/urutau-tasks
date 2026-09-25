import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';

void main() {
  group('Frequências (RF-08, CA-09)', () {
    test('diária avança um dia', () {
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.daily, n: 0), '2026-09-25');
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.daily, n: 1), '2026-09-26');
      expect(occurrenceDateAt(base: '2026-09-30', frequency: RecurrenceFrequency.daily, n: 1), '2026-10-01');
    });

    test('semanal mantém o dia da semana', () {
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.weekly, n: 1), '2026-10-02');
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.weekly, n: 2), '2026-10-09');
    });

    test('dias úteis pula fins de semana', () {
      // 2026-09-25 é sexta-feira.
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.weekdays, n: 1), '2026-09-28');
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.weekdays, n: 2), '2026-09-29');
    });

    test('mensal mantém o dia do mês no calendário original', () {
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.monthly, n: 1), '2026-10-25');
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.monthly, n: 4), '2027-01-25');
    });

    test('anual mantém mês/dia', () {
      expect(occurrenceDateAt(base: '2026-09-25', frequency: RecurrenceFrequency.annual, n: 1), '2027-09-25');
    });
  });

  group('Dias inexistentes (RF-09, CA-10)', () {
    test('31 do mês cai no último dia válido de meses curtos', () {
      final jan31 = occurrenceDateAt(
          base: '2026-01-31', frequency: RecurrenceFrequency.monthly, n: 1);
      expect(jan31, '2026-02-28');

      // O calendário original volta ao dia 31 (não desloca por fevereiro).
      final mar31 = occurrenceDateAt(
          base: '2026-01-31', frequency: RecurrenceFrequency.monthly, n: 2);
      expect(mar31, '2026-03-31');

      final apr30 = occurrenceDateAt(
          base: '2026-01-31', frequency: RecurrenceFrequency.monthly, n: 3);
      expect(apr30, '2026-04-30');
    });

    test('29 de fevereiro em ano bissexto e não bissexto', () {
      // 2024 é bissexto: a série ancora em 29/02.
      expect(
        occurrenceDateAt(
            base: '2024-02-29', frequency: RecurrenceFrequency.annual, n: 1),
        '2025-02-28',
      );
      expect(
        occurrenceDateAt(
            base: '2024-02-29', frequency: RecurrenceFrequency.annual, n: 2),
        '2026-02-28',
      );
      expect(
        occurrenceDateAt(
            base: '2024-02-29', frequency: RecurrenceFrequency.annual, n: 4),
        '2028-02-29',
      );
    });
  });

  group('Próxima data (RF-11/RF-12)', () {
    test('retorna a primeira data estritamente após a âncora', () {
      expect(
        nextOccurrenceDate(
          base: '2026-09-25',
          frequency: RecurrenceFrequency.daily,
          after: '2026-09-25',
        ),
        '2026-09-26',
      );
    });

    test('pula datas passadas em bloco, sem retroativas (CA-15)', () {
      // Série diária com base antiga: a próxima é sempre futura.
      expect(
        nextOccurrenceDate(
          base: '2026-09-01',
          frequency: RecurrenceFrequency.daily,
          after: '2026-09-25',
        ),
        '2026-09-26',
      );
    });

    test('mensal calculado do calendário original ao saltar meses', () {
      expect(
        nextOccurrenceDate(
          base: '2026-01-31',
          frequency: RecurrenceFrequency.monthly,
          after: '2026-02-28',
        ),
        '2026-03-31',
      );
    });
  });

  group('Série (RF-10)', () {
    test('cancelamento marca a série preservando os dados', () {
      final series = RecurringSeries.create(
        id: 's1',
        frequency: RecurrenceFrequency.daily,
        baseDate: '2026-09-25',
      );
      final cancelled = series.cancel();
      expect(cancelled.cancelled, isTrue);
      expect(cancelled.id, 's1');
      expect(cancelled.baseDate, '2026-09-25');
    });
  });
}
