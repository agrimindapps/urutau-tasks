import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class NewerDatabaseSchemaException implements Exception {
  const NewerDatabaseSchemaException({
    required this.databaseVersion,
    required this.appVersion,
  });

  final int databaseVersion;
  final int appVersion;
}

class DatabaseMigrationFailedException implements Exception {
  const DatabaseMigrationFailedException({
    required this.fromVersion,
    required this.toVersion,
  });

  final int fromVersion;
  final int toVersion;
}

@DataClassName('TaskGroupRecord')
@TableIndex(name: 'groups_by_name', columns: {#name}, unique: true)
class TaskGroups extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1)();

  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskListRecord')
@TableIndex(name: 'lists_by_name', columns: {#name}, unique: true)
class TaskLists extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1)();

  IntColumn get position => integer()();

  TextColumn get groupId => text().nullable().references(TaskGroups, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryRecord')
@TableIndex(name: 'categories_by_name', columns: {#name}, unique: true)
class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TagRecord')
@TableIndex(
  name: 'tags_by_normalized_name',
  columns: {#normalizedName},
  unique: true,
)
class Tags extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1)();

  TextColumn get normalizedName => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecurrenceSeriesRecord')
class RecurrenceSeries extends Table {
  TextColumn get id => text()();

  IntColumn get frequency => integer()();

  TextColumn get anchorDueDateIso => text()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  IntColumn get createdAtUtc => integer()();

  IntColumn get updatedAtUtc => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskRecord')
class Tasks extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withLength(min: 1)();

  TextColumn get notes => text().nullable()();

  IntColumn get status => integer().withDefault(const Constant(0))();

  IntColumn get priority => integer().withDefault(const Constant(0))();

  TextColumn get listId => text().nullable().references(TaskLists, #id)();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  TextColumn get dueDateIso => text().nullable()();

  IntColumn get reminderAtUtc => integer().nullable()();

  TextColumn get recurringSeriesId =>
      text().nullable().references(RecurrenceSeries, #id)();

  IntColumn get createdAtUtc => integer()();

  IntColumn get updatedAtUtc => integer()();

  IntColumn get completedAtUtc => integer().nullable()();

  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get statusBeforeTrash => integer().nullable()();

  IntColumn get deletedAtUtc => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SubtaskRecord')
@TableIndex(
  name: 'subtasks_by_task_and_position',
  columns: {#taskId, #position},
  unique: true,
)
class Subtasks extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(Tasks, #id)();

  TextColumn get title => text().withLength(min: 1)();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskTagRecord')
@TableIndex(
  name: 'task_tags_by_task_and_tag',
  columns: {#taskId, #tagId},
  unique: true,
)
class TaskTags extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();

  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column<Object>> get primaryKey => {taskId, tagId};
}

@DataClassName('MyDayEntryRecord')
@TableIndex(
  name: 'my_day_by_task_and_date',
  columns: {#taskId, #localDateIso},
  unique: true,
)
@TableIndex(
  name: 'my_day_by_date_and_position',
  columns: {#localDateIso, #position},
  unique: true,
)
class MyDayEntries extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(Tasks, #id)();

  TextColumn get localDateIso => text()();

  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AppSettingRecord')
class AppSettings extends Table {
  TextColumn get settingKey => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}

@DataClassName('NotificationMappingRecord')
@TableIndex(
  name: 'notification_mappings_by_id',
  columns: {#notificationId},
  unique: true,
)
class NotificationMappings extends Table {
  TextColumn get taskId => text()();

  IntColumn get notificationId => integer()();

  @override
  Set<Column<Object>> get primaryKey => {taskId};
}

@DriftDatabase(
  tables: [
    TaskGroups,
    TaskLists,
    Categories,
    Tags,
    RecurrenceSeries,
    Tasks,
    Subtasks,
    TaskTags,
    MyDayEntries,
    AppSettings,
    NotificationMappings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from > to) {
        throw NewerDatabaseSchemaException(
          databaseVersion: from,
          appVersion: to,
        );
      }
      try {
        await transaction(() async {
          if (from < 2) await migrator.createTable(notificationMappings);
        });
      } catch (_, stackTrace) {
        Error.throwWithStackTrace(
          DatabaseMigrationFailedException(fromVersion: from, toVersion: to),
          stackTrace,
        );
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(
    name: 'urutau_tasks',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
