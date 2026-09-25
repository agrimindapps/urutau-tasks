import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';

import '../app/app.dart';
import '../app/locale_preference.dart';
import '../features/data_transfer/application/data_transfer_service.dart';
import '../features/data_transfer/data/drift_snapshot_repository.dart';
import '../features/my_day/application/my_day_service.dart';
import '../features/notifications/application/reminder_coordinator.dart';
import '../features/notifications/domain/reminder_delivery.dart';
import '../features/notifications/platform/adapter_selector.dart';
import '../features/tasks/presentation/task_detail_page.dart';
import '../features/notifications/platform/reminder_permission_store.dart';
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

/// Adaptador de notificação da plataforma (spec 08, §5).
final reminderAdapterProvider = Provider<ReminderAdapter>((ref) {
  return createReminderAdapter();
});

/// Roteamento ao tocar no aviso: navega para o detalhe da tarefa
/// (spec 08, CA-06). Registrado na inicialização do shell.
final reminderOpenRoutingProvider = Provider<void>((ref) {
  ref.watch(reminderAdapterProvider).setOnOpenTask((taskId) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(taskId: taskId),
      ),
    );
  });
});

final reminderPermissionStoreProvider =
    Provider<ReminderPermissionStore>((ref) {
  return SharedPrefsReminderPermissionStore();
});

/// Agendador de avisos de primeiro plano (spec 08, §8).
final foregroundSchedulerProvider = Provider<ForegroundScheduler>((ref) {
  return TimerForegroundScheduler();
});

/// Coordenador de lembretes: reconcilia com as tarefas em cada mudança.
final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  final coordinator = ReminderCoordinator(
    ref.watch(reminderAdapterProvider),
    ref.watch(reminderPermissionStoreProvider),
    foreground: ref.watch(foregroundSchedulerProvider),
  );
  coordinator.bindTo(ref.watch(taskRepositoryProvider).watchAll());
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// Avisos de primeiro plano (spec 08, §8).
final reminderNoticesProvider = StreamProvider<Task>((ref) {
  return ref.watch(reminderCoordinatorProvider).foregroundNotices;
});

final snapshotRepositoryProvider = Provider<DriftSnapshotRepository>((ref) {
  return DriftSnapshotRepository(ref.watch(databaseProvider));
});

/// Persistência local da preferência de idioma (spec 09, RF-03).
final localePreferenceStoreProvider = Provider<LocalePreferenceStore>((ref) {
  return SharedPrefsLocalePreferenceStore();
});

/// Preferência efetiva: `system` ou `pt-BR`/`en`/`es`.
final localePreferenceProvider =
    NotifierProvider<LocalePreferenceNotifier, String>(
  LocalePreferenceNotifier.new,
);

class LocalePreferenceNotifier extends Notifier<String> {
  @override
  String build() {
    Future.microtask(() async {
      final value = await ref.read(localePreferenceStoreProvider).read();
      state = value;
    });
    return kLocaleSystem;
  }

  /// Aplica imediatamente, sem reinício (spec 09, RF-03).
  Future<void> set(String value) async {
    state = value;
    await ref.read(localePreferenceStoreProvider).write(value);
  }
}

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  return DataTransferService(ref.watch(snapshotRepositoryProvider));
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
