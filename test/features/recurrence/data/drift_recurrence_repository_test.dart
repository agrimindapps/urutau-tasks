@TestOn('!browser')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/recurrence/data/drift_recurrence_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';

import '../../../support/task_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftRecurrenceRepository repository;
  late DriftTaskRepository taskRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftRecurrenceRepository(database);
    taskRepository = DriftTaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('persiste e recupera séries com cancelamento (CA-17)', () async {
    final series = RecurringSeries.create(
      id: 's1',
      frequency: RecurrenceFrequency.monthly,
      baseDate: '2026-01-31',
    );
    await repository.saveSeries(series);
    await repository.saveSeries(series.cancel());

    final loaded = await repository.fetchSeries('s1');
    expect(loaded!.frequency, RecurrenceFrequency.monthly);
    expect(loaded.baseDate, '2026-01-31');
    expect(loaded.cancelled, isTrue);
  });

  test('tarefa persiste prazo, lembrete, prioridade e série', () async {
    await repository.saveSeries(
      RecurringSeries.create(
        id: 's1',
        frequency: RecurrenceFrequency.weekly,
        baseDate: '2026-09-25',
      ),
    );
    final task = buildTask(
      id: 't1',
      title: 'Recorrente',
      priority: TaskPriority.high,
      dueDate: '2026-09-25',
      reminder: DateTime.utc(2026, 9, 26, 9),
    ).setSeries('s1');

    await taskRepository.saveTask(task);

    final loaded = await taskRepository.fetchById('t1');
    expect(loaded!.dueDate, '2026-09-25');
    expect(loaded.reminder, DateTime.utc(2026, 9, 26, 9));
    expect(loaded.priority, TaskPriority.high);
    expect(loaded.seriesId, 's1');
  });

  test('migração v3 → v4 preserva dados e adiciona series_id nulo', () async {
    final dir = await Directory.systemTemp.createTemp('urutau_v3_v4');
    final dbFile = File('${dir.path}/v3.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // Esquema v3: tudo da v2 + my_day/prioridade/prazo/lembrete, sem séries.
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
        priority TEXT NULL,
        due_date TEXT NULL,
        reminder INTEGER NULL,
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
    raw.execute('''
      CREATE TABLE my_day_entries (
        id TEXT NOT NULL,
        task_id TEXT NOT NULL REFERENCES tasks (id),
        date TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
    ''');
    final created = DateTime.utc(2026, 9, 1).millisecondsSinceEpoch ~/ 1000;
    final reminder = DateTime.utc(2026, 9, 26, 9).millisecondsSinceEpoch ~/ 1000;
    raw.execute(
      'INSERT INTO tasks VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['t1', 'Antiga', 'Notas', 'active', null, created, created, null, 0,
        null, null, 'high', '2026-09-30', reminder],
    );
    raw.execute('PRAGMA user_version = 3');
    raw.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    final rows = await migrated.select(migrated.tasks).get();
    expect(rows.single.title, 'Antiga');
    expect(rows.single.priority, 'high');
    expect(rows.single.dueDate, '2026-09-30');
    expect(rows.single.seriesId, isNull);

    await migrated.into(migrated.series).insert(
          SeriesCompanion.insert(
            id: 's1',
            frequency: 'weekly',
            baseDate: '2026-09-30',
          ),
        );
    final seriesRows = await migrated.select(migrated.series).get();
    expect(seriesRows.length, 1);
  });
}
