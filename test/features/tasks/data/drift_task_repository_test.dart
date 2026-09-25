@TestOn('!browser')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/task_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('persiste e recupera tarefa com subtarefas (CA-01, CA-03)', () async {
    final task = buildTask(id: 't1', title: 'Persistida', notes: 'N')
        .addSubtask(id: 's1', description: 'Uma')
        .addSubtask(id: 's2', description: 'Duas');

    await repository.saveTask(task);
    final loaded = await repository.fetchById('t1');

    expect(loaded, isNotNull);
    expect(loaded!.title, 'Persistida');
    expect(loaded.notes, 'N');
    expect(loaded.subtasks.map((s) => s.description), ['Uma', 'Duas']);
    expect(loaded.subtasks.map((s) => s.taskId), ['t1', 't1']);
  });

  test('tarefa sem lista (sem campos extras) mantém UUID estável '
      '(CA-02, CA-18)', () async {
    final task = buildTask(id: 'uuid-x', title: 'Com UUID');
    await repository.saveTask(task);
    final loaded = await repository.fetchById('uuid-x');
    expect(loaded!.id, 'uuid-x');
  });

  test('saveTask substitui o conjunto de subtarefas preservando ids '
      '(CA-05)', () async {
    var task = buildTask(id: 't1', title: 'T')
        .addSubtask(id: 's1', description: 'Fica')
        .addSubtask(id: 's2', description: 'Sai');
    await repository.saveTask(task);

    task = task.removeSubtask('s2');
    await repository.saveTask(task);

    final loaded = await repository.fetchById('t1');
    expect(loaded!.subtasks.map((s) => s.id), ['s1']);
  });

  test('removeSubtask faz exclusão física (RF-07)', () async {
    final task = buildTask(id: 't1', title: 'T')
        .addSubtask(id: 's1', description: 'Uma')
        .addSubtask(id: 's2', description: 'Duas');
    await repository.saveTask(task);

    await repository.removeSubtask('s1');
    final loaded = await repository.fetchById('t1');
    expect(loaded!.subtasks.map((s) => s.id), ['s2']);
  });

  test('lixeira e restauração preservam estados e posições '
      '(CA-13, CA-14)', () async {
    var task = buildTask(id: 't1', title: 'T')
        .addSubtask(id: 's1', description: 'Uma')
        .addSubtask(id: 's2', description: 'Duas');
    task = task.updateSubtask(task.subtasks.last.complete());
    await repository.saveTask(task);

    final trashed = task.moveToTrash(at: kTestNow);
    await repository.saveTask(trashed);

    final loadedTrashed = await repository.fetchById('t1');
    expect(loadedTrashed!.status, TaskStatus.trash);
    expect(loadedTrashed.statusBeforeTrash, TaskStatus.active);
    expect(loadedTrashed.subtasks.map((s) => s.isCompleted), [false, true]);
    expect(loadedTrashed.subtasks.map((s) => s.position), [0, 1]);

    final restored = loadedTrashed.restore(at: kTestNow);
    await repository.saveTask(restored);

    final loadedRestored = await repository.fetchById('t1');
    expect(loadedRestored!.status, TaskStatus.active);
    expect(loadedRestored.statusBeforeTrash, isNull);
    expect(loadedRestored.subtasks.map((s) => s.isCompleted), [false, true]);
  });

  test('restaura concluída para concluída (CA-14)', () async {
    final completed = buildTask(id: 't1', title: 'T').complete(at: kTestNow);
    final trashed = completed.moveToTrash(at: kTestNow);
    await repository.saveTask(trashed);
    final restored = (await repository.fetchById('t1'))!.restore(at: kTestNow);
    await repository.saveTask(restored);

    final loaded = await repository.fetchById('t1');
    expect(loaded!.status, TaskStatus.completed);
    expect(loaded.completedAt, isNotNull);
  });

  test('fetchAll devolve tarefas na posição (CA-23)', () async {
    await repository.saveTask(buildTask(id: 't2', title: 'Segunda', position: 1));
    await repository.saveTask(buildTask(id: 't1', title: 'Primeira', position: 0));

    final all = await repository.fetchAll();
    expect(all.map((t) => t.id), ['t1', 't2']);
  });

  test('watchAll emite lista atualizada após escrita', () async {
    await repository.saveTask(buildTask(id: 't1', title: 'T'));
    final events = <List<Task>>[];
    final subscription = repository.watchAll().listen(events.add);

    await Future<void>.delayed(Duration.zero);
    await repository.saveTask(buildTask(id: 't2', title: 'Nova', position: 1));
    await Future<void>.delayed(Duration.zero);

    expect(events.length, greaterThanOrEqualTo(2));
    expect(events.last.map((t) => t.id), ['t1', 't2']);
    await subscription.cancel();
  });

  test('FK impede subtarefa órfã (CA-22)', () async {
    expect(
      () => database.into(database.subtasks).insert(
            SubtasksCompanion.insert(
              id: 's9',
              taskId: 'ghost',
              description: 'Órfã',
            ),
          ),
      throwsA(anything),
    );
  });
}
