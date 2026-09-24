import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/organization/data/drift_organization_repository.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// DDL equivalente ao esquema v1 (spec 06, RF-22) para validar a
/// migração v1 → v2 (CA-19).
const _v1Schema = [
  '''
  CREATE TABLE "tasks" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL CHECK(length(trim(title)) > 0),
    "notes" TEXT NULL,
    "status" TEXT NOT NULL DEFAULT 'active'
      CHECK(status IN ('active', 'completed')),
    "created_at" INTEGER NOT NULL,
    "updated_at" INTEGER NULL,
    "completed_at" INTEGER NULL,
    "deleted_at" INTEGER NULL,
    "position" INTEGER NOT NULL DEFAULT 0
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
];

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('urutau_migration_test');
    dbFile = File('${tempDir.path}/urutau_tasks.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void seedV1() {
    // Escreve o esquema v1 diretamente, sem passar pelo Drift, para que a
    // abertura posterior dispare a migração v1 → v2.
    final raw = sqlite3.open(dbFile.path);
    for (final statement in _v1Schema) {
      raw.execute(statement);
    }
    raw.execute(
      'INSERT INTO tasks (id, title, notes, status, created_at, position) '
      "VALUES ('task-1', 'Tarefa v1', 'nota v1', 'completed', "
      '${DateTime.utc(2026, 1, 1).millisecondsSinceEpoch}, 0)',
    );
    raw.execute(
      'INSERT INTO subtasks (id, task_id, title, is_completed, position) '
      "VALUES ('sub-1', 'task-1', 'Etapa v1', 1, 0)",
    );
    // Marca a base como esquema v1 para que o Drift execute onUpgrade.
    raw.userVersion = 1;
    raw.close();
  }

  test('CA-19 — migração v1→v2 preserva dados e adiciona organização',
      () async {
    seedV1();

    final migrated = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    // Tarefa e subtarefa preservadas com UUIDs estáveis (CA-18).
    final tasks = await migrated.select(migrated.tasks).get();
    expect(tasks, hasLength(1));
    expect(tasks.single.id, 'task-1');
    expect(tasks.single.title, 'Tarefa v1');
    expect(tasks.single.status, 'completed');
    expect(tasks.single.notes, 'nota v1');
    // Novas colunas chegam nulas (inbox implícita, sem categoria).
    expect(tasks.single.listId, isNull);
    expect(tasks.single.categoryId, isNull);

    final subtasks = await migrated.select(migrated.subtasks).get();
    expect(subtasks.single.id, 'sub-1');
    expect(subtasks.single.isCompleted, isTrue);

    // Novas tabelas disponíveis.
    expect(await migrated.select(migrated.taskLists).get(), isEmpty);
    expect(await migrated.select(migrated.groups).get(), isEmpty);
    expect(await migrated.select(migrated.categories).get(), isEmpty);
    expect(await migrated.select(migrated.tags).get(), isEmpty);
    expect(await migrated.select(migrated.taskTags).get(), isEmpty);

    // Camada de organização funcional pós-migração.
    final org = DriftOrganizationRepository(migrated);
    final listId = await org.insertListReturnId();
    await org.setTaskList('task-1', listId);
    final tasksRepo = DriftTaskRepository(migrated);
    final task = await tasksRepo.getTask('task-1');
    expect(task!.listId, listId);
    expect(task.subtasks.single.title, 'Etapa v1');
  });

  test('esquema v2 protege unicidade sem diferenciação de maiúsculas', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final org = DriftOrganizationRepository(db);

    await org.insertList(TaskList(id: 'l1', name: 'Trabalho'));
    await expectLater(
      org.insertList(TaskList(id: 'l2', name: 'TRABALHO')),
      throwsA(anything),
    );

    await org.insertTag(Tag(id: 't1', name: 'urgente'));
    await expectLater(
      org.insertTag(Tag(id: 't2', name: ' Urgente ')),
      throwsA(anything),
    );
  });

  test('RF-06 — exclusão de lista move tarefas em uma transação', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final org = DriftOrganizationRepository(db);
    final tasksRepo = DriftTaskRepository(db);

    final sourceId = await org.insertListReturnId();
    final destId = await org.insertListReturnId();
    await tasksRepo.insertTask(Task(
      id: 't1',
      title: 'Mover',
      createdAt: DateTime.utc(2026),
      listId: sourceId,
      subtasks: [
        Subtask(id: 's1', taskId: 't1', title: 'Etapa'),
      ],
    ));

    await org.deleteListMovingTasks(sourceId, destId);

    expect(await org.getLists(), hasLength(1));
    final task = await tasksRepo.getTask('t1');
    expect(task!.listId, destId);
    expect(task.subtasks.single.title, 'Etapa');
  });

  test('RF-05 — excluir grupo desvincula listas sem excluí-las', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final org = DriftOrganizationRepository(db);

    await org.insertGroup(Group(id: 'g1', name: 'Projetos'));
    await org.insertList(TaskList(id: 'l1', name: 'Site', groupId: 'g1'));

    await org.deleteGroup('g1');

    expect(await org.watchGroups().first, isEmpty);
    final lists = await org.getLists();
    expect(lists.single.id, 'l1');
    expect(lists.single.groupId, isNull);
  });

  test('RF-08/RF-09 — excluir categoria e tag desvincula sem tocar tarefas',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final org = DriftOrganizationRepository(db);
    final tasksRepo = DriftTaskRepository(db);

    await org.insertCategory(Category(id: 'c1', name: 'Casa'));
    await org.insertTag(Tag(id: 't1', name: 'rápido'));
    await tasksRepo.insertTask(Task(
      id: 'task-1',
      title: 'Comprar',
      createdAt: DateTime.utc(2026),
      categoryId: 'c1',
      tags: [Tag(id: 't1', name: 'rápido')],
    ));

    await org.deleteCategory('c1');
    await org.deleteTag('t1');

    final task = await tasksRepo.getTask('task-1');
    expect(task!.title, 'Comprar');
    expect(task.categoryId, isNull);
    expect(task.tags, isEmpty);
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.tags).get(), isEmpty);
    expect(await db.select(db.taskTags).get(), isEmpty);
  });
}

extension on DriftOrganizationRepository {
  Future<String> insertListReturnId() async {
    final id = 'list-${DateTime.now().microsecondsSinceEpoch}';
    await insertList(TaskList(id: id, name: 'Lista $id'));
    return id;
  }
}
