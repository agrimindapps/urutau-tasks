import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/data_transfer/application/data_transfer_service.dart';
import 'package:urutau_tasks/src/features/data_transfer/data/drift_snapshot_repository.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/data_snapshot.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/snapshot_codec.dart';
import 'package:urutau_tasks/src/features/my_day/application/my_day_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:urutau_tasks/src/features/my_day/data/drift_my_day_repository.dart';
import 'package:urutau_tasks/src/features/organization/application/organization_service.dart';
import 'package:urutau_tasks/src/features/organization/data/drift_organization_repository.dart';
import 'package:urutau_tasks/src/features/recurrence/data/drift_recurrence_repository.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase source;
  late DataTransferService sourceService;
  var idCounter = 0;

  String newId() => 'id-${idCounter++}';

  Future<void> populateSource() async {
    final tasksRepo = DriftTaskRepository(source);
    final orgRepo = DriftOrganizationRepository(source);
    final myDayRepo = DriftMyDayRepository(source);
    final recurrenceRepo = DriftRecurrenceRepository(source);
    final org = OrganizationService(orgRepo, generateId: newId);
    final myDay = MyDayService(myDayRepo, tasksRepo,
        now: () => DateTime(2026, 9, 24, 12), generateId: newId);
    final tasks = TasksService(
      tasksRepo,
      organizationRepository: orgRepo,
      myDayRepository: myDayRepo,
      recurrenceRepository: recurrenceRepo,
      now: () => DateTime(2026, 9, 24, 12),
      generateId: newId,
    );

    // Organização completa (spec 02).
    final groupId = await org.createGroup('Projetos');
    final listId = await org.createList('Trabalho', groupId: groupId);
    await org.createList('Casa');
    final categoryId = await org.createCategory('Financeiro');
    final urgentTag = await org.ensureTag('urgente');

    // Tarefa ativa com todos os atributos (CA-01/CA-03).
    final activeId = await tasks.createTask(
      title: 'Reunião do time',
      notes: 'discutar orçamento',
      listId: listId,
      categoryId: categoryId,
      priority: Priority.urgent,
      dueDate: DateTime(2026, 10, 1),
      reminder: DateTime.utc(2026, 9, 30, 12),
    );
    await tasks.setTaskTags(activeId, [urgentTag]);
    await tasks.addSubtask(activeId, title: 'Preparar pauta');
    final subtasks = await tasksRepo.getTask(activeId);
    await tasks.toggleSubtaskCompletion(
        activeId, subtasks!.subtasks.first.id);
    await myDay.addToMyDay(activeId);

    // Tarefa concluída com notas.
    final completedId = await tasks.createTask(
      title: 'Enviar relatório',
      notes: 'anexo no drive',
    );
    await tasks.toggleCompletion(completedId);

    // Tarefa na lixeira (CA-01: estados completos).
    final trashedId = await tasks.createTask(title: 'Descartável');
    await tasks.moveToTrash(trashedId);

    // Recorrência com histórico (spec 04).
    final recurringId = await tasks.createTask(
      title: 'Pagar conta',
      dueDate: DateTime(2026, 10, 5),
    );
    await tasks.setRecurrence(recurringId, RecurrenceFrequency.monthly);
    await tasks.toggleCompletion(recurringId); // gera próxima ocorrência
  }

  setUp(() async {
    idCounter = 0;
    source = createMemoryDatabase();
    sourceService = DataTransferService(DriftSnapshotRepository(source));
    await populateSource();
  });

  tearDown(() => source.close());

  Future<DataSnapshot> snapshotOf(AppDatabase db) =>
      DriftSnapshotRepository(db).loadSnapshot();

  /// Conteúdo lógico sem o instante de exportação (que muda a cada carga).
  String contentOf(DataSnapshot snapshot) =>
      encodeSnapshot(snapshot).replaceFirst(snapshot.exportedAt, 'AT');

  Future<void> expectSameContent(AppDatabase a, AppDatabase b) async {
    expect(contentOf(await snapshotOf(b)), contentOf(await snapshotOf(a)));
  }

  group('exportação e importação JSON (CA-01 a CA-03, CA-09, CA-13)', () {
    test('CA-01/CA-02/CA-03/CA-06 — roundtrip completo preserva o conjunto',
        () async {
      final json = await sourceService.exportJson();

      final target = createMemoryDatabase();
      addTearDown(target.close);
      final targetService = DataTransferService(DriftSnapshotRepository(target));

      final validated = targetService.validateJson(json);
      // CA-07: resumo antes de substituir.
      expect(validated.summary.activeTasks, greaterThan(0));
      expect(validated.summary.completedTasks, 2); // relatório + ocorrência concluída
      expect(validated.summary.trashedTasks, 1);
      expect(validated.summary.subtasks, 1);
      expect(validated.summary.lists, 2);
      expect(validated.summary.groups, 1);

      await targetService.apply(validated);
      await expectSameContent(source, target);

      // CA-03: instante UTC do lembrete idêntico.
      final sourceReminder = (await DriftTaskRepository(source)
              .getTask('id-5')) // primeira createTask do populate
          ?.reminder;
      final targetTasks = await DriftSnapshotRepository(target).loadSnapshot();
      expect(targetTasks.tasks.map((t) => t.reminder),
          (await snapshotOf(source)).tasks.map((t) => t.reminder));
      expect(sourceReminder, isNotNull);
    });

    test('CA-13 — versão futura rejeitada sem tocar nos dados', () async {
      final json = await sourceService.exportJson();
      final futureJson =
          json.replaceFirst('"format_version": 1', '"format_version": 2');

      final target = createMemoryDatabase();
      addTearDown(target.close);
      final targetService = DataTransferService(DriftSnapshotRepository(target));
      await targetService.importJson('{"format_version":1,"exported_at":'
          '"2026-01-01T00:00:00.000Z","data":{"tasks":[],"subtasks":[],'
          '"lists":[],"groups":[],"categories":[],"tags":[],"task_tags":[],'
          '"recurring_series":[],"my_day_entries":[]}}');
      final before = contentOf(await snapshotOf(target));

      expect(
        () => targetService.validateJson(futureJson),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.unsupportedVersion)),
      );
      expect(contentOf(await snapshotOf(target)), before);
    });

    test('CA-12 — JSON inválido não altera os dados locais', () async {
      final target = createMemoryDatabase();
      addTearDown(target.close);
      final targetService = DataTransferService(DriftSnapshotRepository(target));
      await targetService.importJson(encodeSnapshot(DataSnapshot(
        formatVersion: 1,
        exportedAt: '2026-01-01T00:00:00.000Z',
        tasks: const [],
        subtasks: const [],
        lists: const [],
        groups: const [],
        categories: const [],
        tags: const [],
        taskTags: const [],
        series: const [],
        myDayEntries: const [],
      )));
      final before = contentOf(await snapshotOf(target));

      expect(
        () => targetService.validateJson('{"format_version": 1, broken'),
        throwsA(isA<SnapshotException>()),
      );
      expect(contentOf(await snapshotOf(target)), before);
    });
  });

  group('backup criptografado (CA-04, CA-11)', () {
    test('CA-04/CA-01 — backup restaura o conjunto completo com senha',
        () async {
      final bytes = await sourceService.createBackup('senha-forte');

      final target = createMemoryDatabase();
      addTearDown(target.close);
      final targetService = DataTransferService(DriftSnapshotRepository(target));
      await targetService.restoreBackup(bytes, 'senha-forte');

      await expectSameContent(source, target);
    });

    test('CA-11 — senha incorreta rejeita sem alterar dados locais',
        () async {
      final bytes = await sourceService.createBackup('correta');

      final target = createMemoryDatabase();
      addTearDown(target.close);
      final targetService = DataTransferService(DriftSnapshotRepository(target));
      await targetService.importJson(encodeSnapshot(DataSnapshot(
        formatVersion: 1,
        exportedAt: '2026-01-01T00:00:00.000Z',
        tasks: const [],
        subtasks: const [],
        lists: const [],
        groups: const [],
        categories: const [],
        tags: const [],
        taskTags: const [],
        series: const [],
        myDayEntries: const [],
      )));
      final before = contentOf(await snapshotOf(target));

      await expectLater(
        targetService.restoreBackup(bytes, 'errada'),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.invalidPassword)),
      );
      expect(contentOf(await snapshotOf(target)), before);
    });
  });

  group('RF-16 — troca atômica (CA-10)', () {
    test('CA-10 — falha na gravação reverte e preserva dados anteriores',
        () async {
      final target = createMemoryDatabase();
      addTearDown(target.close);
      final repo = DriftSnapshotRepository(target);

      DataSnapshot snapshotWith({String? seriesId}) => DataSnapshot(
            formatVersion: 1,
            exportedAt: '2026-02-01T00:00:00.000Z',
            tasks: [
              TaskData(
                id: 'keep-me',
                title: 'Sobrevive',
                notes: null,
                status: 'active',
                priority: 'medium',
                dueDate: null,
                reminder: null,
                listId: null,
                categoryId: null,
                seriesId: seriesId,
                position: 0,
                createdAt: '2026-02-01T00:00:00.000Z',
                updatedAt: null,
                completedAt: null,
                deletedAt: null,
              ),
            ],
            subtasks: const [],
            lists: const [],
            groups: const [],
            categories: const [],
            tags: const [],
            taskTags: const [],
            series: const [],
            myDayEntries: const [],
          );

      // Estado local válido anterior.
      await repo.replaceAll(snapshotWith());
      final before = contentOf(await snapshotOf(target));

      // Gravação com referência inexistente falha no meio da transação.
      await expectLater(
        repo.replaceAll(snapshotWith(seriesId: 'ghost-series')),
        throwsA(anything),
      );

      // Nada parcial permanece (CA-10).
      expect(contentOf(await snapshotOf(target)), before);
      expect((await snapshotOf(target)).tasks.single.id, 'keep-me');
    });
  });
}
