import 'recurrence.dart';

/// Porta de persistência das séries recorrentes (spec 04; spec 06, RF-09).
abstract class RecurrenceRepository {
  Future<RecurringSeries?> fetchSeries(String id);

  Future<List<RecurringSeries>> fetchAll();

  Future<void> saveSeries(RecurringSeries series);
}
