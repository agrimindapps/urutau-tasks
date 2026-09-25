import 'package:drift/drift.dart';

import '../features/my_day/data/my_day_tables.dart';
import '../features/organization/data/organization_tables.dart';
import '../features/tasks/data/task_tables.dart';

part 'app_database.g.dart';

/// Banco local único do aplicativo (spec 06, RF-01).
///
/// Esquema versionado monotonicamente (spec 06, RF-22); mudanças entram
/// como migrações incrementais em [MigrationStrategy.onUpgrade], não
/// destrutivas (RF-23) e atômicas com rollback integral (RF-24).
@DriftDatabase(tables: [
  Tasks,
  Subtasks,
  Groups,
  TaskLists,
  Categories,
  Tags,
  TaskTags,
  MyDayEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createUniqueIndexes();
          await _createMyDayIndex();
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
            await _createUniqueIndexes();
          }
          if (from < 3) {
            // v2 → v3: My Day, prioridade, prazo e lembrete (spec 03/04).
            await m.createTable(myDayEntries);
            await m.addColumn(tasks, tasks.priority);
            await m.addColumn(tasks, tasks.dueDate);
            await m.addColumn(tasks, tasks.reminder);
            await _createMyDayIndex();
          }
        },
        beforeOpen: (details) async {
          // Integridade referencial habilitada (spec 06, RF-17).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Unicidade de nomes por tipo (spec 02, RF-01) e de identidade de tag.
  Future<void> _createUniqueIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_groups_name ON groups (name)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_lists_name ON task_lists (name)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_categories_name '
      'ON categories (name)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_tags_normalized_name '
      'ON tags (normalized_name)',
    );
  }

  /// Máx. 1 entrada por tarefa/data (spec 06, RF-19); tabela da v3.
  Future<void> _createMyDayIndex() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_my_day_task_date '
      'ON my_day_entries (task_id, date)',
    );
  }
}
