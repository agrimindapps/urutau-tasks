import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/my_day/application/my_day_service.dart';
import '../features/my_day/data/drift_my_day_repository.dart';
import '../features/my_day/domain/my_day.dart';
import '../features/my_day/domain/my_day_repository.dart';
import '../features/recurrence/data/drift_recurrence_repository.dart';
import '../features/recurrence/domain/recurrence.dart';
import '../features/recurrence/domain/recurrence_repository.dart';
import '../features/data_transfer/application/data_transfer_service.dart';
import '../features/data_transfer/data/drift_snapshot_repository.dart';
import '../features/data_transfer/domain/snapshot_repository.dart';
import '../app/locale_preference.dart';
import '../features/notifications/application/reminder_coordinator.dart';
import '../features/notifications/domain/reminder_delivery.dart';
import '../features/notifications/platform/adapter_selector.dart';
import '../features/notifications/platform/reminder_permission_store.dart';
import '../features/organization/application/organization_service.dart';
import '../features/organization/data/drift_organization_repository.dart';
import '../features/organization/domain/organization.dart';
import '../features/organization/domain/organization_repository.dart';
import '../features/tasks/application/tasks_service.dart';
import '../features/tasks/data/drift_task_repository.dart';
import '../features/tasks/domain/task.dart';
import '../features/tasks/domain/task_repository.dart';
import 'app_database.dart' show AppDatabase;

/// Preferência de idioma da instalação (spec 09, RF-03) — fora do
/// banco e do backup (spec 09, RF-02/CA-09).
final localePreferenceStoreProvider = Provider<LocalePreferenceStore>((ref) {
  return SharedPrefsLocalePreferenceStore();
});

/// Valor persistido: `system`, `pt-BR`, `en` ou `es`.
final localePreferenceProvider = FutureProvider<String>((ref) async {
  return ref.watch(localePreferenceStoreProvider).read();
});

/// Banco local único (spec 06, RF-01).
///
/// Na Web, `web` aponta para os assets versionados em `web/` (`sqlite3.wasm`
/// e `drift_worker.js`); nas plataformas nativas os parâmetros web são
/// ignorados pelo `driftDatabase`.
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

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return DriftOrganizationRepository(ref.watch(databaseProvider));
});

final myDayRepositoryProvider = Provider<MyDayRepository>((ref) {
  return DriftMyDayRepository(ref.watch(databaseProvider));
});

final recurrenceRepositoryProvider = Provider<RecurrenceRepository>((ref) {
  return DriftRecurrenceRepository(ref.watch(databaseProvider));
});

/// Todas as séries, para o filtro de recorrência (spec 05, RF-15).
final allSeriesProvider = StreamProvider<List<RecurrenceSeries>>((ref) {
  return ref.watch(recurrenceRepositoryProvider).watchAll();
});

/// Adaptador de notificação da plataforma (spec 08, ADR-0004).
final notificationAdapterProvider = Provider<NotificationAdapter>((ref) {
  final adapter = createNotificationAdapter();
  ref.onDispose(() => adapter.setOnOpened(null));
  return adapter;
});

/// Coordena entrega de lembretes (spec 08, RF-01 a RF-05).
final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  final coordinator = ReminderCoordinator(
    adapter: ref.watch(notificationAdapterProvider),
    tasks: ref.watch(taskRepositoryProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final reminderPermissionStoreProvider =
    Provider<ReminderPermissionStore>((ref) {
  return SharedPrefsReminderPermissionStore();
});

final tasksServiceProvider = Provider<TasksService>((ref) {
  return TasksService(
    ref.watch(taskRepositoryProvider),
    organizationRepository: ref.watch(organizationRepositoryProvider),
    myDayRepository: ref.watch(myDayRepositoryProvider),
    recurrenceRepository: ref.watch(recurrenceRepositoryProvider),
    reminders: ref.watch(reminderCoordinatorProvider),
  );
});

final myDayServiceProvider = Provider<MyDayService>((ref) {
  return MyDayService(
    ref.watch(myDayRepositoryProvider),
    ref.watch(taskRepositoryProvider),
  );
});

/// Entradas do My Day do dia corrente (spec 03, RF-12).
final myDayTodayProvider = StreamProvider<List<MyDayEntry>>((ref) {
  return ref.watch(myDayRepositoryProvider).watchEntries(
        ref.watch(myDayServiceProvider).today,
      );
});

final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  return DriftSnapshotRepository(ref.watch(databaseProvider));
});

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  return DataTransferService(ref.watch(snapshotRepositoryProvider));
});

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService(ref.watch(organizationRepositoryProvider));
});

final listsProvider = StreamProvider<List<TaskList>>((ref) {
  return ref.watch(organizationRepositoryProvider).watchLists();
});

final groupsProvider = StreamProvider<List<Group>>((ref) {
  return ref.watch(organizationRepositoryProvider).watchGroups();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(organizationRepositoryProvider).watchCategories();
});

final tagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(organizationRepositoryProvider).watchTags();
});

/// Tarefas fora da lixeira, ordenadas por posição.
final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTasks();
});

/// Tarefas na lixeira (spec 01, RF-02).
final trashProvider = StreamProvider<List<Task>>((ref) {
  return ref
      .watch(taskRepositoryProvider)
      .watchTasks(includeTrashed: true)
      .map((tasks) => tasks.where((t) => t.isDeleted).toList());
});

/// Observa uma tarefa com suas subtarefas.
final taskProvider = StreamProvider.family<Task?, String>((ref, id) {
  return ref.watch(taskRepositoryProvider).watchTask(id);
});
