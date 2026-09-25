@TestOn('!browser')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/data/app_database.dart';
import 'package:urutau_tasks/src/features/data_transfer/application/data_transfer_service.dart';
import 'package:urutau_tasks/src/features/data_transfer/data/drift_snapshot_repository.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/backup_codec.dart';
import 'package:urutau_tasks/src/features/tasks/data/drift_task_repository.dart';

import '../../../support/task_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftSnapshotRepository snapshot;
  late DriftTaskRepository tasks;
  late DataTransferService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    snapshot = DriftSnapshotRepository(database);
    tasks = DriftTaskRepository(database);
    service = DataTransferService(snapshot);
  });

  tearDown(() async {
    await database.close();
  });

  test('resumo mostra tipo, data e contagens por estado (CA-07)', () async {
    await tasks.saveTask(buildTask(id: 't1', title: 'Ativa'));
    await tasks.saveTask(
      buildTask(id: 't2', title: 'Concluída').complete(at: kTestNow),
    );
    await tasks.saveTask(
      buildTask(id: 't3', title: 'Lixeira').moveToTrash(at: kTestNow),
    );

    final content = await service.createBackup(password: 'senha');
    final summary = await service.summarizeBackup(
      content: content,
      password: 'senha',
    );

    expect(summary.isEncrypted, isTrue);
    expect(summary.taskCount, 3);
    expect(summary.activeCount, 1);
    expect(summary.completedCount, 1);
    expect(summary.trashCount, 1);
  });

  test('restaurar substitui integralmente os dados (CA-09)', () async {
    await tasks.saveTask(buildTask(id: 'antiga', title: 'Antiga'));
    final content = await service.createBackup(password: 'senha');

    // Novo estado local que será substituído.
    await tasks.saveTask(buildTask(id: 'atual', title: 'Atual'));
    expect((await tasks.fetchAll()), hasLength(2));

    await service.restoreBackup(content: content, password: 'senha');

    final restored = await tasks.fetchAll();
    expect(restored.map((t) => t.id), ['antiga']);
  });

  test('senha errada preserva os dados locais (CA-11)', () async {
    await tasks.saveTask(buildTask(id: 'local', title: 'Local'));
    final content = await service.createBackup(password: 'certa');

    expect(
      () => service.restoreBackup(content: content, password: 'errada'),
      throwsA(isA<BackupException>()),
    );

    expect((await tasks.fetchAll()).map((t) => t.id), ['local']);
  });

  test('JSON legível é exportado e importado sem senha (CA-05/CA-06)', () async {
    await tasks.saveTask(buildTask(id: 't1', title: 'Legível'));
    final json = await service.createReadableExport();
    expect(json, contains('"format_version": 1'));
    expect(json, contains('Legível'));

    final summary = await service.summarizeJson(content: json);
    expect(summary.isEncrypted, isFalse);
    expect(summary.taskCount, 1);

    await tasks.saveTask(buildTask(id: 't2', title: 'Substituir'));
    await service.importJson(content: json);
    expect((await tasks.fetchAll()).map((t) => t.id), ['t1']);
  });

  test('cancelar antes da substituição não altera nada (CA-08)', () async {
    await tasks.saveTask(buildTask(id: 't1', title: 'Intacta'));
    final json = await service.createReadableExport();

    // O usuário só resume (visualização) e não confirma.
    await service.summarizeJson(content: json);

    expect((await tasks.fetchAll()).map((t) => t.id), ['t1']);
  });
}
