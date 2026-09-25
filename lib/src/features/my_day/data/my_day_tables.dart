import 'package:drift/drift.dart';

import '../../tasks/data/task_tables.dart';

/// Entradas do My Day (esquema v3; spec 06, RF-10).
@DataClassName('MyDayEntryRow')
class MyDayEntries extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(Tasks, #id)();

  /// Data local do foco `YYYY-MM-DD` (spec 06, RF-13).
  TextColumn get date => text()();

  /// Ordem manual do dia (spec 03, RF-12).
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
