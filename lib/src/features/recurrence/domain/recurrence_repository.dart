import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';

/// Porta de persistência das séries recorrentes (spec 04; spec 06, RF-21).
abstract interface class RecurrenceRepository {
  Future<RecurrenceSeries?> getSeries(String id);
  Future<void> insertSeries(RecurrenceSeries series);
  Future<void> saveSeries(RecurrenceSeries series);

  /// Todas as séries, para o filtro de recorrência (spec 05, RF-15).
  Stream<List<RecurrenceSeries>> watchAll();
}
