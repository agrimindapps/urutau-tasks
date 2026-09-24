import 'package:drift/drift.dart';

import '../features/tasks/data/task_tables.dart';

part 'app_database.g.dart';

/// Banco local único do aplicativo (spec 06, RF-01).
///
/// O esquema é versionado monotonicamente (spec 06, RF-22). Mudanças de
/// estrutura entram como migração incremental em [migration.onUpgrade],
/// não destrutivas (spec 06, RF-23) e atômicas (spec 06, RF-24).
@DriftDatabase(tables: [
  Tasks,
  Subtasks,
  Groups,
  TaskLists,
  Categories,
  Tags,
  TaskTags,
  MyDayEntries,
  Series,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS my_day_task_date '
            'ON my_day_entries (task_id, date)',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 → v2: listas, grupos, categorias e tags (spec 02).
            await m.createTable(groups);
            await m.createTable(taskLists);
            await m.createTable(categories);
            await m.createTable(tags);
            await m.createTable(taskTags);
            await m.addColumn(tasks, tasks.listId);
            await m.addColumn(tasks, tasks.categoryId);
          }
          if (from < 3) {
            // v2 → v3: My Day e campos de visão (spec 03; escopo MVP 3.3).
            await m.createTable(myDayEntries);
            await m.addColumn(tasks, tasks.priority);
            await m.addColumn(tasks, tasks.dueDate);
            await m.addColumn(tasks, tasks.reminder);
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS my_day_task_date '
              'ON my_day_entries (task_id, date)',
            );
          }
          if (from < 4) {
            // v3 → v4: séries recorrentes (spec 04).
            await m.createTable(series);
            await m.addColumn(tasks, tasks.seriesId);
          }
        },
        beforeOpen: (details) async {
          // Habilita restrições de chave estrangeira (spec 06, RF-17).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
