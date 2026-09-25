import 'package:drift/drift.dart';

import '../features/tasks/data/task_tables.dart';

part 'app_database.g.dart';

/// Banco local único do aplicativo (spec 06, RF-01).
///
/// Esquema versionado monotonicamente (spec 06, RF-22); mudanças entram
/// como migrações incrementais em [MigrationStrategy.onUpgrade], não
/// destrutivas (RF-23) e atômicas com rollback integral (RF-24).
@DriftDatabase(tables: [Tasks, Subtasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Integridade referencial habilitada (spec 06, RF-17).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
