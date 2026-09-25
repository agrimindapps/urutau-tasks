import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/organization/application/organization_service.dart';
import '../features/organization/data/drift_organization_repository.dart';
import '../features/organization/domain/organization_repository.dart';
import '../features/tasks/application/tasks_service.dart';
import '../features/tasks/data/drift_task_repository.dart';
import '../features/tasks/domain/task.dart';
import '../features/tasks/domain/task_repository.dart';
import 'app_database.dart';

/// Banco local único (spec 06, RF-01).
///
/// Na Web, `web` aponta para os assets versionados em `web/`
/// (`sqlite3.wasm`, `drift_worker.js`); em plataformas nativas os
/// parâmetros web são ignorados pelo `driftDatabase`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(
    driftDatabase(
      name: 'urutau_tasks',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );
  ref.onDispose(database.close);
  return database;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DriftTaskRepository(ref.watch(databaseProvider));
});

final tasksServiceProvider = Provider<TasksService>((ref) {
  return TasksService(ref.watch(taskRepositoryProvider));
});

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return DriftOrganizationRepository(ref.watch(databaseProvider));
});

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService(
    ref.watch(organizationRepositoryProvider),
    ref.watch(taskRepositoryProvider),
  );
});

/// Organização observável: listas, grupos, categorias e tags.
final organizationProvider = StreamProvider<OrganizationSnapshot>((ref) {
  return ref.watch(organizationRepositoryProvider).watchSnapshot();
});

/// Lista observável de tarefas (inclusive lixeira).
final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});
