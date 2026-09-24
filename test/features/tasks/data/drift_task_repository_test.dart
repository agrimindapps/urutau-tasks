import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/data/app_database.dart';

import '../../../support/test_database.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository repository;
  late TasksService service;

  setUp(() {
    db = createMemoryDatabase();
    repository = DriftTaskRepository(db);
    service = TasksService(
      repository,
      now: () => DateTime.utc(2026, 9, 24, 12),
      generateId: () => 'generated',
    );
  });

  tearDown(() => db.close());

  Future<String> createTaskWithSubtasks() async {
    var counter = 0;
    final svc = TasksService(
      repository,
      now: () => DateTime.utc(2026, 9, 24, 12),
      generateId: () => 'id-${counter++}',
    );
    final id = await svc.createTask(title: 'Principal', notes: 'nota');
    await svc.addSubtask(id, title: 'A');
    await svc.addSubtask(id, title: 'B');
    await svc.toggleSubtaskCompletion(id, (await repository.getTask(id))!
        .subtasks
        .first
        .id);
    return id;
  }

  group('spec 06 — persistência básica (CA-01 a CA-04)', () {
    test('CA-01 persiste e recupera tarefa', () async {
      var counter = 0;
      final svc = TasksService(
        repository,
        now: () => DateTime.utc(2026, 9, 24, 12),
        generateId: () => 'id-${counter++}',
      );
      final id =
          await svc.createTask(title: 'Comprar pão', notes: 'integral');

      final reopened = await DriftTaskRepository(db).getTask(id);
      expect(reopened!.title, 'Comprar pão');
      expect(reopened.notes, 'integral');
      expect(reopened.status, TaskStatus.active);
      expect(reopened.createdAt.toUtc(), DateTime.utc(2026, 9, 24, 12));
    });

    test('CA-02 preserva tarefa sem lista (inbox implícita)', () async {
      final id = await service.createTask(title: 'Sem lista');
      final task = await repository.getTask(id);
      expect(task, isNotNull);
    });

    test('CA-03 preserva hierarquia de subtarefas', () async {
      final id = await createTaskWithSubtasks();

      final task = await DriftTaskRepository(db).getTask(id);
      expect(task!.subtasks.map((s) => s.taskId), [id, id]);
      expect(task.subtasks.map((s) => s.title), ['A', 'B']);
    });

    test('CA-04 preserva estados e posições', () async {
      final id = await createTaskWithSubtasks();
      final task = await repository.getTask(id);

      expect(task!.subtasks.map((s) => s.isCompleted), [true, false]);
      expect(task.subtasks.map((s) => s.position), [0, 1]);
    });
  });

  group('spec 06 — subtarefas e lixeira (CA-05, CA-13, CA-14)', () {
    test('CA-05 remover subtarefa exclui fisicamente', () async {
      final id = await createTaskWithSubtasks();
      final victim = (await repository.getTask(id))!.subtasks.first;

      await service.removeSubtask(id, victim.id);

      final rows = await db.select(db.subtasks).get();
      expect(rows.map((r) => r.id), isNot(contains(victim.id)));
      final task = await repository.getTask(id);
      expect(task!.subtasks.single.title, 'B');
      expect(task.status, TaskStatus.active);
      expect(task.isDeleted, isFalse);
    });

    test('CA-13 hierarquia permanece na lixeira com metadados', () async {
      final id = await createTaskWithSubtasks();
      await service.moveToTrash(id);

      final trashed = await repository.getTask(id);
      expect(trashed!.isDeleted, isTrue);
      expect(trashed.deletedAt!.toUtc(), DateTime.utc(2026, 9, 24, 12));
      expect(trashed.subtasks, hasLength(2));

      final visible = await repository.watchTasks().first;
      expect(visible, isEmpty);

      final withTrash = await repository.watchTasks(includeTrashed: true).first;
      expect(withTrash.single.id, id);
    });

    test('CA-14 restaurar não cria cópias nem altera UUIDs', () async {
      final id = await createTaskWithSubtasks();
      final before = await repository.getTask(id);
      await service.moveToTrash(id);
      await service.restoreFromTrash(id);
      final after = await repository.getTask(id);

      expect(after!.id, before!.id);
      expect(after.isDeleted, isFalse);
      expect(
        after.subtasks.map((s) => s.id),
        before.subtasks.map((s) => s.id),
      );
      expect(await db.select(db.tasks).get(), hasLength(1));
    });
  });

  group('spec 06 — integridade e ordenação (CA-18, CA-23, CA-24)', () {
    test('CA-18 UUIDs estáveis após edições', () async {
      var counter = 0;
      final svc = TasksService(
        repository,
        generateId: () => 'id-${counter++}',
      );
      final id = await svc.createTask(title: 'Original');
      await svc.addSubtask(id, title: 'Etapa');
      final before = await repository.getTask(id);

      await svc.editTask(id, title: 'Editada');
      await svc.toggleCompletion(id);
      await svc.moveToTrash(id);
      await svc.restoreFromTrash(id);

      final after = await repository.getTask(id);
      expect(after!.id, before!.id);
      expect(after.subtasks.single.id, before.subtasks.single.id);
    });

    test('CA-23 reordenação persiste sem posições duplicadas', () async {
      final id = await createTaskWithSubtasks();
      final task = await repository.getTask(id);
      await service.moveSubtask(id, 1, 0);

      final rows = await (db.select(db.subtasks)
            ..where((s) => s.taskId.equals(id))
            ..orderBy([(s) => OrderingTerm.asc(s.position)]))
          .get();
      expect(rows.map((r) => r.position), [0, 1]);
      expect(rows.map((r) => r.title), ['B', 'A']);
      expect(task!.subtasks, hasLength(2));
    });

    test('CA-24 banco isolado por teste', () async {
      final other = createMemoryDatabase();
      addTearDown(other.close);
      await DriftTaskRepository(other)
          .insertTask(Task(id: 'other-1', title: 'Outra', createdAt: DateTime.utc(2026)));

      expect(await db.select(db.tasks).get(), isEmpty);
      expect(await other.select(other.tasks).get(), hasLength(1));
    });

    test('RF-17 FK impede subtarefa órfã', () async {
      await expectLater(
        db.into(db.subtasks).insert(
              SubtasksCompanion.insert(
                id: 'orphan',
                taskId: 'inexistent',
                title: 'Órfã',
              ),
            ),
        throwsA(anything),
      );
    });

    test('RF-04 escrita multi-registro é atômica', () async {
      final id = await createTaskWithSubtasks();
      final before = await repository.getTask(id);

      await expectLater(
        db.transaction(() async {
          await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
            const TasksCompanion(title: Value('Alterada')),
          );
          // Viola a checagem de título e força rollback da transação.
          await db.into(db.subtasks).insert(
                SubtasksCompanion.insert(
                  id: 'bad',
                  taskId: id,
                  title: '   ',
                ),
              );
        }),
        throwsA(anything),
      );

      final after = await repository.getTask(id);
      expect(after!.title, before!.title);
      expect(after.subtasks, hasLength(before.subtasks.length));
    });
  });
}
