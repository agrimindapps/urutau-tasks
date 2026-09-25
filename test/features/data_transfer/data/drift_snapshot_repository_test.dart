@TestOn('!browser')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/data_transfer/data/drift_snapshot_repository.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/data_snapshot.dart';
import 'package:urutau_tasks/src/features/my_day/data/drift_my_day_repository.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/organization/data/drift_organization_repository.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/recurrence/data/drift_recurrence_repository.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/task_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftSnapshotRepository snapshot;
  late DriftTaskRepository tasks;
  late DriftOrganizationRepository organization;
  late DriftRecurrenceRepository recurrence;
  late DriftMyDayRepository myDay;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    snapshot = DriftSnapshotRepository(database);
    tasks = DriftTaskRepository(database);
    organization = DriftOrganizationRepository(database);
    recurrence = DriftRecurrenceRepository(database);
    myDay = DriftMyDayRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedFullState() async {
    await organization.saveGroup(TaskGroup.create(id: 'g1', name: 'Projeto'));
    await organization.saveList(
      TaskList.create(id: 'l1', name: 'Casa', groupId: 'g1'),
    );
    await organization.saveCategory(TaskCategory.create(id: 'c1', name: 'Trabalho'));
    await organization.saveTag(TaskTag.create(id: 'tag1', name: 'Foco'));
    await recurrence.saveSeries(
      RecurringSeries.create(
        id: 's1',
        frequency: RecurrenceFrequency.weekly,
        baseDate: '2026-09-25',
      ),
    );

    // Tarefa ativa com subtarefas, tags e lembrete.
    var active = buildTask(
      id: 't1',
      title: 'Ativa',
      notes: 'Notas',
      priority: TaskPriority.high,
      dueDate: '2026-09-30',
      reminder: DateTime.utc(2026, 10, 1, 9),
    )
        .assignList('l1')
        .assignCategory('c1')
        .addTagId('tag1')
        .addSubtask(id: 'sub1', description: 'Etapa');
    active = active.setSeries('s1');
    await tasks.saveTask(active);

    // Tarefa concluída e tarefa na lixeira (RF-01: todos os estados).
    await tasks.saveTask(
      buildTask(id: 't2', title: 'Concluída').complete(at: kTestNow),
    );
    await tasks.saveTask(
      buildTask(id: 't3', title: 'Lixeira').moveToTrash(at: kTestNow),
    );

    await myDay.saveEntry(
      MyDayEntry.create(id: 'e1', taskId: 't1', date: '2026-09-25', position: 0),
    );
  }

  test('exporta o conjunto completo incluindo lixeira e histórico (CA-01/CA-02)',
      () async {
    await seedFullState();
    final exported = await snapshot.exportSnapshot(
      exportedAt: DateTime.utc(2026, 9, 25, 12),
    );

    expect(exported.tasks, hasLength(3));
    expect(exported.tasks.map((t) => t['status']).toSet(),
        {'active', 'completed', 'trash'});
    expect(exported.subtasks, hasLength(1));
    expect(exported.lists, hasLength(1));
    expect(exported.groups, hasLength(1));
    expect(exported.categories, hasLength(1));
    expect(exported.tags, hasLength(1));
    expect(exported.taskTags, hasLength(1));
    expect(exported.recurringSeries, hasLength(1));
    expect(exported.myDayEntries, hasLength(1));
  });

  test('restauração preserva UUIDs e relações (CA-02/CA-18)', () async {
    await seedFullState();
    final exported = await snapshot.exportSnapshot();

    // Banco novo: substituição integral deve reproduzir o estado.
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    snapshot = DriftSnapshotRepository(database);
    tasks = DriftTaskRepository(database);
    await snapshot.replaceAll(exported);

    final restored = await tasks.fetchById('t1');
    expect(restored!.id, 't1');
    expect(restored.listId, 'l1');
    expect(restored.categoryId, 'c1');
    expect(restored.tagIds, ['tag1']);
    expect(restored.seriesId, 's1');
    expect(restored.dueDate, '2026-09-30');
    expect(restored.reminder, DateTime.utc(2026, 10, 1, 9));
    expect(restored.priority, TaskPriority.high);
    expect(restored.subtasks.single.id, 'sub1');

    final trashed = await tasks.fetchById('t3');
    expect(trashed!.status, TaskStatus.trash);

    final myDayRows = await database.select(database.myDayEntries).get();
    expect(myDayRows.single.taskId, 't1');
    expect(myDayRows.single.date, '2026-09-25');
  });

  test('falha no meio da substituição faz rollback integral (CA-10)', () async {
    await seedFullState();
    final before = await tasks.fetchAll();

    // Retrato com referência quebrada: passaria na ordem de inserção até a
    // FK de tasks.list_id falhar no meio da transação.
    final broken = DataSnapshot(
      exportedAt: DateTime.utc(2026, 9, 25),
      tasks: [
        {
          'id': 'x1',
          'title': 'Nova',
          'notes': '',
          'status': 'active',
          'status_before_trash': null,
          'created_at': '2026-09-25T12:00:00.000Z',
          'updated_at': '2026-09-25T12:00:00.000Z',
          'completed_at': null,
          'position': 0,
          'list_id': 'inexistente',
          'category_id': null,
          'priority': null,
          'due_date': null,
          'reminder': null,
          'series_id': null,
        }
      ],
      subtasks: const [],
      lists: const [],
      groups: const [],
      categories: const [],
      tags: const [],
      taskTags: const [],
      recurringSeries: const [],
      myDayEntries: const [],
    );

    expect(() => snapshot.replaceAll(broken), throwsA(anything));

    final after = await tasks.fetchAll();
    expect(after.map((t) => t.id), before.map((t) => t.id));
    expect(after.length, 3);
  });
}
