import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../domain/recurrence.dart';
import '../domain/recurrence_repository.dart';

/// Persistência Drift das séries recorrentes (spec 06, RF-09).
class DriftRecurrenceRepository implements RecurrenceRepository {
  DriftRecurrenceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<RecurringSeries?> fetchSeries(String id) async {
    final row = await (_db.select(_db.series)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toSeries(row);
  }

  @override
  Future<List<RecurringSeries>> fetchAll() async {
    final rows = await _db.select(_db.series).get();
    return [for (final row in rows) _toSeries(row)];
  }

  @override
  Future<void> saveSeries(RecurringSeries series) async {
    await _db.into(_db.series).insertOnConflictUpdate(
          SeriesCompanion.insert(
            id: series.id,
            frequency: series.frequency.name,
            baseDate: series.baseDate,
            cancelled: Value(series.cancelled),
          ),
        );
  }

  RecurringSeries _toSeries(SeriesRow row) {
    return RecurringSeries(
      id: row.id,
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.name == row.frequency,
        orElse: () => throw StateError('Frequência desconhecida: ${row.frequency}'),
      ),
      baseDate: row.baseDate,
      cancelled: row.cancelled,
    );
  }
}
