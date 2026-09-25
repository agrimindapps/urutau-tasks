@TestOn('!browser')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/organization/data/drift_organization_repository.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';

import '../../../support/task_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftOrganizationRepository repository;
  late DriftTaskRepository taskRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftOrganizationRepository(database);
    taskRepository = DriftTaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('persiste e recupera listas, grupos, categorias e tags', () async {
    await repository.saveGroup(
      TaskGroup.create(id: 'g1', name: 'Projeto', position: 0),
    );
    await repository.saveList(
      TaskList.create(id: 'l1', name: 'Casa', position: 0, groupId: 'g1'),
    );
    await repository.saveCategory(
      TaskCategory.create(id: 'c1', name: 'Trabalho'),
    );
    await repository.saveTag(TaskTag.create(id: 't1', name: 'Trabalho'));

    final snapshot = await repository.fetchSnapshot();
    expect(snapshot.lists.single.name, 'Casa');
    expect(snapshot.lists.single.groupId, 'g1');
    expect(snapshot.groups.single.name, 'Projeto');
    expect(snapshot.categories.single.name, 'Trabalho');
    expect(snapshot.tags.single.normalizedName, 'trabalho');
  });

  test('índice único impede nomes duplicados por tipo (RF-01)', () async {
    await repository.saveList(TaskList.create(id: 'l1', name: 'Casa'));
    expect(
      () => repository.saveList(TaskList.create(id: 'l2', name: 'Casa')),
      throwsA(anything),
    );
  });

  test('removeCategory desvincula sem apagar tarefas (RF-08)', () async {
    await repository.saveCategory(TaskCategory.create(id: 'c1', name: 'Temp'));
    await taskRepository.saveTask(
      buildTask(id: 'task1', title: 'T').assignCategory('c1'),
    );

    await repository.removeCategory('c1');

    final task = await taskRepository.fetchById('task1');
    expect(task!.categoryId, isNull);
    expect(task.title, 'T');
    expect((await repository.fetchSnapshot()).categories, isEmpty);
  });

  test('removeTag remove só as associações (RF-09)', () async {
    await repository.saveTag(TaskTag.create(id: 'tag1', name: 'casa'));
    await taskRepository.saveTask(
      buildTask(id: 'task1', title: 'T').addTagId('tag1'),
    );

    await repository.removeTag('tag1');

    final task = await taskRepository.fetchById('task1');
    expect(task!.tagIds, isEmpty);
    expect((await repository.fetchSnapshot()).tags, isEmpty);
  });

  test('removeGroup deixa as listas intactas e sem grupo (RF-05)', () async {
    await repository.saveGroup(TaskGroup.create(id: 'g1', name: 'Projeto'));
    await repository.saveList(
      TaskList.create(id: 'l1', name: 'Casa', groupId: 'g1'),
    );

    await repository.removeGroup('g1');

    final snapshot = await repository.fetchSnapshot();
    expect(snapshot.groups, isEmpty);
    expect(snapshot.lists.single.groupId, isNull);
  });

  test('removeListMigratingTasks move a hierarquia em transação (RF-06)',
      () async {
    await repository.saveList(TaskList.create(id: 'l1', name: 'Origem'));
    await repository.saveList(TaskList.create(id: 'l2', name: 'Destino'));
    var task = buildTask(id: 'task1', title: 'T')
        .addSubtask(id: 'sub1', description: 'Etapa');
    task = task.assignList('l1');
    await taskRepository.saveTask(task);

    await repository.removeListMigratingTasks(listId: 'l1', toListId: 'l2');

    final migrated = await taskRepository.fetchById('task1');
    expect(migrated!.listId, 'l2');
    expect(migrated.subtasks.single.description, 'Etapa');
    final snapshot = await repository.fetchSnapshot();
    expect(snapshot.lists.map((l) => l.id), ['l2']);
    expect(snapshot.taskCount('l2'), 1);
  });

  test('FK impede tarefa órfã de lista inexistente (RF-17)', () async {
    expect(
      () => taskRepository.saveTask(
        buildTask(id: 'task1', title: 'T').assignList('ghost'),
      ),
      throwsA(anything),
    );
  });

  group('migração v1 → v2 (spec 06, RF-22/RF-23)', () {
    test('preserva tarefas e subtarefas e adiciona colunas nulas', () async {
      final dir = await Directory.systemTemp.createTemp('urutau_migration');
      final dbFile = File('${dir.path}/v1.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      // Esquema v1 gravado com SQL direto (como o app antigo faria).
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
        'INSERT INTO tasks VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ['task1', 'Antiga', 'Notas', 'completed', null, created, created,
          created, 5],
      );
      raw.execute(
        'INSERT INTO subtasks VALUES (?, ?, ?, ?, ?)',
        ['sub1', 'task1', 'Etapa', 1, 0],
      );
      raw.execute('PRAGMA user_version = 1');
      raw.close();

      // Abertura pelo app atual dispara a migração para a v2.
      final migrated = AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(migrated.close);

      final tasks = await migrated.select(migrated.tasks).get();
      expect(tasks.single.title, 'Antiga');
      expect(tasks.single.status, 'completed');
      expect(tasks.single.position, 5);
      expect(tasks.single.listId, isNull);
      expect(tasks.single.categoryId, isNull);

      final subtasks = await migrated.select(migrated.subtasks).get();
      expect(subtasks.single.description, 'Etapa');
      expect(subtasks.single.isCompleted, isTrue);

      // Tabelas novas operantes após a migração.
      await migrated.into(migrated.taskLists).insert(
            TaskListsCompanion.insert(id: 'l1', name: 'Nova'),
          );
      final lists = await migrated.select(migrated.taskLists).get();
      expect(lists.single.name, 'Nova');
    });
  });
}
