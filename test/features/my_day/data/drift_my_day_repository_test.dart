import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/my_day/data/drift_my_day_repository.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:sqlite3/sqlite3.dart';

/// Esquema v2 (spec 02) para validar a migração v2 → v3 (spec 03;
/// spec 06, CA-19).
const _v2Schema = [
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
  CREATE TABLE "groups" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL COLLATE NOCASE UNIQUE,
    "position" INTEGER NOT NULL DEFAULT 0
  );
  ''',
  '''
  CREATE TABLE "task_lists" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL COLLATE NOCASE UNIQUE,
    "position" INTEGER NOT NULL DEFAULT 0,
    "group_id" TEXT NULL REFERENCES groups (id)
  );
  ''',
  '''
  CREATE TABLE "categories" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL COLLATE NOCASE UNIQUE
  );
  ''',
  '''
  CREATE TABLE "tags" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL COLLATE NOCASE UNIQUE
  );
  ''',
  '''
  CREATE TABLE "task_tags" (
    "task_id" TEXT NOT NULL REFERENCES tasks (id),
    "tag_id" TEXT NOT NULL REFERENCES tags (id),
    PRIMARY KEY ("task_id", "tag_id")
  );
  ''',
];

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('urutau_m3_test');
    dbFile = File('${tempDir.path}/urutau_tasks.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void seedV2() {
    final raw = sqlite3.open(dbFile.path);
    for (final statement in _v2Schema) {
      raw.execute(statement);
    }
    raw.execute(
      'INSERT INTO tasks (id, title, status, created_at, position, list_id) '
      "VALUES ('task-1', 'Tarefa v2', 'active', "
      '${DateTime.utc(2026, 1, 1).millisecondsSinceEpoch}, 0, NULL)',
    );
    raw.execute(
      'INSERT INTO subtasks (id, task_id, title, is_completed, position) '
      "VALUES ('sub-1', 'task-1', 'Etapa v2', 0, 0)",
    );
    raw.userVersion = 2;
    raw.close();
  }

  test('CA-19 — migração v2→v3 preserva dados e cria My Day', () async {
    seedV2();

    final migrated = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    final tasks = await migrated.select(migrated.tasks).get();
    expect(tasks.single.id, 'task-1');
    expect(tasks.single.title, 'Tarefa v2');
    // Novas colunas com valores padrão/nulos.
    expect(tasks.single.priority, 'medium');
    expect(tasks.single.dueDate, isNull);
    expect(tasks.single.reminder, isNull);
    expect(tasks.single.listId, isNull);
    expect(await migrated.select(migrated.myDayEntries).get(), isEmpty);
    expect(await migrated.select(migrated.subtasks).get(), hasLength(1));
  });

  test('índice único impede tarefa duplicada na mesma data (spec 06, RF-19)',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final tasksRepo = DriftTaskRepository(db);
    final myDay = DriftMyDayRepository(db);

    await tasksRepo.insertTask(Task(
      id: 't1',
      title: 'Foco',
      createdAt: DateTime.utc(2026),
    ));
    await myDay.insertEntry(MyDayEntry(
      id: 'e1',
      taskId: 't1',
      date: '2026-09-24',
    ));

    await expectLater(
      myDay.insertEntry(MyDayEntry(id: 'e2', taskId: 't1', date: '2026-09-24')),
      throwsA(anything),
    );
    expect(await myDay.getEntries('2026-09-24'), hasLength(1));
  });

  test('purgeEntriesExcept remove entradas de outras datas (CA-14)',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final tasksRepo = DriftTaskRepository(db);
    final myDay = DriftMyDayRepository(db);

    await tasksRepo.insertTask(Task(
      id: 't1',
      title: 'Foco',
      createdAt: DateTime.utc(2026),
    ));
    await myDay.insertEntry(
        MyDayEntry(id: 'e1', taskId: 't1', date: '2026-09-23'));
    await myDay.insertEntry(
        MyDayEntry(id: 'e2', taskId: 't1', date: '2026-09-24'));

    await myDay.purgeEntriesExcept('2026-09-24');

    expect(
      (await myDay.getEntries('2026-09-24')).map((e) => e.id),
      ['e2'],
    );
    expect(await db.select(db.myDayEntries).get(), hasLength(1));
  });

  test('prazo persistido como data sem horário (spec 06, CA-09)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final tasksRepo = DriftTaskRepository(db);

    await tasksRepo.insertTask(Task(
      id: 't1',
      title: 'Com prazo',
      createdAt: DateTime.utc(2026),
      dueDate: DateTime(2026, 10, 1),
      reminder: DateTime.utc(2026, 10, 1, 15, 30),
    ));

    final row = (await db.select(db.tasks).get()).single;
    expect(row.dueDate, '2026-10-01');
    expect(row.reminder!.toUtc(), DateTime.utc(2026, 10, 1, 15, 30));

    final task = await tasksRepo.getTask('t1');
    expect(task!.dueDate, DateTime(2026, 10, 1));
    expect(task.reminder!.toUtc(), DateTime.utc(2026, 10, 1, 15, 30));
    expect(task.priority, Priority.medium);
  });
}
