import 'dart:async';

import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../domain/my_day.dart';
import '../domain/my_day_repository.dart';

/// Persistência Drift do My Day (spec 06, RF-10/RF-21).
class DriftMyDayRepository implements MyDayRepository {
  DriftMyDayRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<MyDayEntry>> fetchAll() async {
    final rows = await _db.select(_db.myDayEntries).get();
    return _assemble(rows);
  }

  @override
  Stream<List<MyDayEntry>> watchAll() {
    return _db.select(_db.myDayEntries).watch().map(_assemble);
  }

  List<MyDayEntry> _assemble(List<MyDayEntryRow> rows) {
    final entries = [for (final row in rows) _toEntry(row)];
    entries.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.position.compareTo(b.position);
    });
    return entries;
  }

  @override
  Future<void> saveEntry(MyDayEntry entry) async {
    await _db.into(_db.myDayEntries).insertOnConflictUpdate(
          MyDayEntriesCompanion.insert(
            id: entry.id,
            taskId: entry.taskId,
            date: entry.date,
            position: Value(entry.position),
          ),
        );
  }

  @override
  Future<void> removeEntry(String entryId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.myDayEntries)..where((e) => e.id.equals(entryId)))
          .go();
    });
  }

  @override
  Future<void> removeForTask(String taskId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.myDayEntries)
            ..where((e) => e.taskId.equals(taskId)))
          .go();
    });
  }

  @override
  Future<void> removeBefore(String today) async {
    // Idempotente: remover o que já não existe é no-op (spec 03, RF-10).
    await _db.transaction(() async {
      await (_db.delete(_db.myDayEntries)..where((e) => e.date.isSmallerThanValue(today)))
          .go();
    });
  }

  MyDayEntry _toEntry(MyDayEntryRow row) {
    return MyDayEntry(
      id: row.id,
      taskId: row.taskId,
      date: row.date,
      position: row.position,
    );
  }
}
