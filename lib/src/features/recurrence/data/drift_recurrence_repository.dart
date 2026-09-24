import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../recurrence/domain/recurrence.dart';
import '../../recurrence/domain/recurrence_repository.dart';

/// Implementação Drift do repositório de séries recorrentes.
class DriftRecurrenceRepository implements RecurrenceRepository {
  DriftRecurrenceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<RecurrenceSeries?> getSeries(String id) async {
    final row = await (_db.select(_db.series)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toSeries(row);
  }

  @override
  Future<void> insertSeries(RecurrenceSeries series) =>
      _db.into(_db.series).insert(_companion(series));

  @override
  Future<void> saveSeries(RecurrenceSeries series) =>
      _db.update(_db.series).replace(_companion(series));

  @override
  Stream<List<RecurrenceSeries>> watchAll() {
    return (_db.select(_db.series)..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .watch()
        .map((rows) => rows.map(_toSeries).toList());
  }

  RecurrenceSeries _toSeries(SeriesRecord row) => RecurrenceSeries(
        id: row.id,
        frequency: RecurrenceFrequency.parse(row.frequency),
        anchorDate: row.anchorDate,
        active: row.active,
      );

  SeriesCompanion _companion(RecurrenceSeries series) => SeriesCompanion(
        id: Value(series.id),
        frequency: Value(series.frequency.storedName),
        anchorDate: Value(series.anchorDate),
        active: Value(series.active),
      );
}
