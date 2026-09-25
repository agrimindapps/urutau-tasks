import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/my_day/application/my_day_service.dart';
import '../features/recurrence/application/recurrence_service.dart';
import '../features/recurrence/data/drift_recurrence_repository.dart';
import '../features/recurrence/domain/recurrence.dart';
import '../features/recurrence/domain/recurrence_repository.dart';
import '../features/my_day/data/drift_my_day_repository.dart';
import '../features/my_day/domain/my_day.dart';
import '../features/my_day/domain/my_day_repository.dart';
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

final myDayRepositoryProvider = Provider<MyDayRepository>((ref) {
  return DriftMyDayRepository(ref.watch(databaseProvider));
});

final recurrenceRepositoryProvider = Provider<RecurrenceRepository>((ref) {
  return DriftRecurrenceRepository(ref.watch(databaseProvider));
});

final tasksServiceProvider = Provider<TasksService>((ref) {
  return TasksService(
    ref.watch(taskRepositoryProvider),
    ref.watch(myDayRepositoryProvider),
    ref.watch(recurrenceRepositoryProvider),
  );
});

final recurrenceServiceProvider = Provider<RecurrenceService>((ref) {
  return RecurrenceService(
    ref.watch(recurrenceRepositoryProvider),
    ref.watch(taskRepositoryProvider),
  );
});

/// Séries para contexto de busca (estado de cancelamento).
final allSeriesProvider = FutureProvider<List<RecurringSeries>>((ref) {
  return ref.watch(recurrenceRepositoryProvider).fetchAll();
});

final myDayServiceProvider = Provider<MyDayService>((ref) {
  return MyDayService(
    ref.watch(myDayRepositoryProvider),
    ref.watch(taskRepositoryProvider),
  );
});

/// Entradas do My Day observáveis.
final myDayEntriesProvider = StreamProvider<List<MyDayEntry>>((ref) {
  return ref.watch(myDayRepositoryProvider).watchAll();
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
