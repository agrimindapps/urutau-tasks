import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../my_day/domain/my_day.dart';
import '../../my_day/domain/my_day_repository.dart';

/// Implementação Drift do repositório do My Day.
class DriftMyDayRepository implements MyDayRepository {
  DriftMyDayRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<MyDayEntry>> watchEntries(String date) {
    return (_db.select(_db.myDayEntries)
          ..where((e) => e.date.equals(date))
          ..orderBy([(e) => OrderingTerm.asc(e.position)]))
        .watch()
        .map((rows) => rows.map(_toEntry).toList());
  }

  @override
  Future<List<MyDayEntry>> getEntries(String date) async {
    final rows = await (_db.select(_db.myDayEntries)
          ..where((e) => e.date.equals(date))
          ..orderBy([(e) => OrderingTerm.asc(e.position)]))
        .get();
    return rows.map(_toEntry).toList();
  }

  @override
  Future<void> insertEntry(MyDayEntry entry) =>
      _db.into(_db.myDayEntries).insert(_companion(entry));

  @override
  Future<void> removeEntriesForTask(String taskId) =>
      (_db.delete(_db.myDayEntries)..where((e) => e.taskId.equals(taskId)))
          .go();

  @override
  Future<void> updatePositions(List<MyDayEntry> entries) {
    return _db.transaction(() async {
      for (final entry in entries) {
        await (_db.update(_db.myDayEntries)
              ..where((e) => e.id.equals(entry.id)))
            .write(_companion(entry));
      }
    });
  }

  @override
  Future<void> purgeEntriesExcept(String date) =>
      (_db.delete(_db.myDayEntries)..where((e) => e.date.equals(date).not()))
          .go();

  MyDayEntry _toEntry(MyDayEntryRecord row) => MyDayEntry(
        id: row.id,
        taskId: row.taskId,
        date: row.date,
        position: row.position,
      );

  MyDayEntriesCompanion _companion(MyDayEntry entry) =>
      MyDayEntriesCompanion(
        id: Value(entry.id),
        taskId: Value(entry.taskId),
        date: Value(entry.date),
        position: Value(entry.position),
      );
}
