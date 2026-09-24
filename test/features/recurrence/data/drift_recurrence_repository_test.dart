import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/recurrence/data/drift_recurrence_repository.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// Esquema v3 (spec 03) para validar a migração v3 → v4 (spec 04;
/// spec 06, CA-19).
const _v3Schema = [
  '''
  CREATE TABLE "tasks" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL CHECK(length(trim(title)) > 0),
    "notes" TEXT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "created_at" INTEGER NOT NULL,
    "updated_at" INTEGER NULL,
    "completed_at" INTEGER NULL,
    "deleted_at" INTEGER NULL,
    "position" INTEGER NOT NULL DEFAULT 0,
    "priority" TEXT NOT NULL DEFAULT 'medium',
    "due_date" TEXT NULL,
    "reminder" INTEGER NULL,
    "list_id" TEXT NULL,
    "category_id" TEXT NULL
  );
  ''',
  '''
  CREATE TABLE "subtasks" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "task_id" TEXT NOT NULL REFERENCES tasks (id),
    "title" TEXT NOT NULL CHECK(length(trim(title)) > 0),
    "is_completed" INTEGER NOT NULL DEFAULT 0,
    "position" INTEGER NOT NULL DEFAULT 0
  );
  ''',
  '''
  CREATE TABLE "my_day_entries" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "task_id" TEXT NOT NULL REFERENCES tasks (id),
    "date" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0
  );
  ''',
  "CREATE UNIQUE INDEX my_day_task_date ON my_day_entries (task_id, date);",
];

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('urutau_m4_test');
    dbFile = File('${tempDir.path}/urutau_tasks.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void seedV3() {
    final raw = sqlite3.open(dbFile.path);
    for (final statement in _v3Schema) {
      raw.execute(statement);
    }
    raw.execute(
      'INSERT INTO tasks (id, title, status, created_at, position, priority, due_date) '
      "VALUES ('task-1', 'Tarefa v3', 'active', "
      '${DateTime.utc(2026, 1, 1).millisecondsSinceEpoch}, 0, '
      "'high', '2026-10-01')",
    );
    raw.userVersion = 3;
    raw.close();
  }

  test('CA-19 — migração v3→v4 preserva dados e cria séries', () async {
    seedV3();

    final migrated = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    final tasks = await migrated.select(migrated.tasks).get();
    expect(tasks.single.id, 'task-1');
    expect(tasks.single.priority, 'high');
    expect(tasks.single.dueDate, '2026-10-01');
    expect(tasks.single.seriesId, isNull); // nova coluna nula
    expect(await migrated.select(migrated.series).get(), isEmpty);
    expect(await migrated.select(migrated.myDayEntries).get(), isEmpty);
  });

  test('série persiste e vincula a ocorrência (CA-09)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final recurrence = DriftRecurrenceRepository(db);
    final tasksRepo = DriftTaskRepository(db);

    await recurrence.insertSeries(RecurrenceSeries(
      id: 's1',
      frequency: RecurrenceFrequency.weekly,
      anchorDate: '2026-10-01',
    ));
    await tasksRepo.insertTask(Task(
      id: 't1',
      title: 'Semanal',
      createdAt: DateTime.utc(2026),
      dueDate: DateTime(2026, 10, 1),
      seriesId: 's1',
    ));

    final loaded = await recurrence.getSeries('s1');
    expect(loaded!.frequency, RecurrenceFrequency.weekly);
    expect(loaded.active, isTrue);

    final task = await tasksRepo.getTask('t1');
    expect(task!.seriesId, 's1');

    // RF-10/CA-17: cancelamento persiste.
    await recurrence.saveSeries(loaded.copyWith(active: false));
    expect((await recurrence.getSeries('s1'))!.active, isFalse);
  });
}
