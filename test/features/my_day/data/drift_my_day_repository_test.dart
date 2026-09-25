@TestOn('!browser')
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/my_day/data/drift_my_day_repository.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';

import '../../../support/task_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftMyDayRepository repository;
  late DriftTaskRepository taskRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftMyDayRepository(database);
    taskRepository = DriftTaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('persiste e recupera entradas por data e posição (CA-11)', () async {
    await taskRepository.saveTask(buildTask(id: 't1', title: 'T'));
    await repository.saveEntry(
      MyDayEntry.create(id: 'e1', taskId: 't1', date: '2026-09-25', position: 1),
    );
    await repository.saveEntry(
      MyDayEntry.create(id: 'e0', taskId: 't1', date: '2026-09-24', position: 0),
    );

    final entries = await repository.fetchAll();
    expect(entries.map((e) => e.date), ['2026-09-24', '2026-09-25']);
    expect(entries.map((e) => e.position), [0, 1]);
  });

  test('índice único impede duplicar tarefa/data (RF-19)', () async {
    await taskRepository.saveTask(buildTask(id: 't1', title: 'T'));
    await repository.saveEntry(
      MyDayEntry.create(id: 'e1', taskId: 't1', date: '2026-09-25'),
    );
    expect(
      () => repository.saveEntry(
        MyDayEntry.create(id: 'e2', taskId: 't1', date: '2026-09-25'),
      ),
      throwsA(anything),
    );
  });

  test('removeForTask limpa todas as datas (CA-12/CA-13)', () async {
    await taskRepository.saveTask(buildTask(id: 't1', title: 'T'));
    await repository.saveEntry(
      MyDayEntry.create(id: 'e1', taskId: 't1', date: '2026-09-25'),
    );
    await repository.saveEntry(
      MyDayEntry.create(id: 'e2', taskId: 't1', date: '2026-09-26'),
    );

    await repository.removeForTask('t1');

    expect(await repository.fetchAll(), isEmpty);
  });

  test('removeBefore é o rollover transacional e idempotente (CA-14)', () async {
    await taskRepository.saveTask(buildTask(id: 't1', title: 'T'));
    await repository.saveEntry(
      MyDayEntry.create(id: 'e1', taskId: 't1', date: '2026-09-24'),
    );
    await repository.saveEntry(
      MyDayEntry.create(id: 'e2', taskId: 't1', date: '2026-09-25'),
    );

    await repository.removeBefore('2026-09-25');
    await repository.removeBefore('2026-09-25');

    final remaining = await repository.fetchAll();
    expect(remaining.map((e) => e.id), ['e2']);
  });

  test('migração v2 → v3 preserva dados e adiciona colunas nulas', () async {
    final dir = await Directory.systemTemp.createTemp('urutau_v2_v3');
    final dbFile = File('${dir.path}/v2.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // Esquema v2 gravado com SQL direto (como o app antigo faria).
    final raw = sqlite3.open(dbFile.path);
    raw.execute('''
      CREATE TABLE tasks (
        id TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL,
        status_before_trash TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER NULL,
        position INTEGER NOT NULL DEFAULT 0,
        list_id TEXT NULL,
        category_id TEXT NULL,
        PRIMARY KEY (id)
      );
    ''');
    raw.execute('''
      CREATE TABLE subtasks (
        id TEXT NOT NULL,
        task_id TEXT NOT NULL REFERENCES tasks (id),
        description TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
    ''');
    final created = DateTime.utc(2026, 9, 1).millisecondsSinceEpoch ~/ 1000;
    raw.execute(
      'INSERT INTO tasks VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['t1', 'Antiga', 'Notas', 'active', null, created, created, null, 2,
        null, null],
    );
    raw.execute('PRAGMA user_version = 2');
    raw.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    final rows = await migrated.select(migrated.tasks).get();
    expect(rows.single.title, 'Antiga');
    expect(rows.single.status, 'active');
    expect(rows.single.priority, isNull);
    expect(rows.single.dueDate, isNull);
    expect(rows.single.reminder, isNull);

    await migrated.into(migrated.myDayEntries).insert(
          MyDayEntriesCompanion.insert(
            id: 'e1',
            taskId: 't1',
            date: '2026-09-25',
            position: Value(0),
          ),
        );
    final entries = await migrated.select(migrated.myDayEntries).get();
    expect(entries.length, 1);
  });
}
