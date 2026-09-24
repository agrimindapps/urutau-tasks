import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences_repository.dart';
import '../../../core/database/app_database.dart';
import '../../organization/data/organization_repository.dart';
import '../../organization/domain/organization.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => DriftTaskRepository(ref.watch(appDatabaseProvider)),
);

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => DriftOrganizationRepository(ref.watch(appDatabaseProvider)),
);

final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>(
  (ref) => AppPreferencesRepository(ref.watch(appDatabaseProvider)),
);

final languagePreferenceProvider = StreamProvider<AppLanguagePreference>(
  (ref) =>
      ref.watch(appPreferencesRepositoryProvider).watchLanguagePreference(),
);

final taskGroupsProvider = StreamProvider<List<TaskGroup>>(
  (ref) => ref.watch(organizationRepositoryProvider).watchGroups(),
);

final taskListsProvider = StreamProvider<List<TaskList>>(
  (ref) => ref.watch(organizationRepositoryProvider).watchLists(),
);

final taskCategoriesProvider = StreamProvider<List<TaskCategory>>(
  (ref) => ref.watch(organizationRepositoryProvider).watchCategories(),
);

final taskTagsProvider = StreamProvider<List<TaskTag>>(
  (ref) => ref.watch(organizationRepositoryProvider).watchTags(),
);

final taskTagAssignmentsProvider = StreamProvider.family<List<TaskTag>, String>(
  (ref, taskId) =>
      ref.watch(organizationRepositoryProvider).watchTaskTags(taskId),
);

final tasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchTasks(),
);

final myDayTasksProvider = StreamProvider.family<List<Task>, String>(
  (ref, localDateIso) =>
      ref.watch(taskRepositoryProvider).watchMyDay(localDateIso),
);

final taskProvider = StreamProvider.family<Task?, String>(
  (ref, taskId) => ref.watch(taskRepositoryProvider).watchTask(taskId),
);

final taskSubtasksProvider = StreamProvider.family<List<Subtask>, String>(
  (ref, taskId) => ref.watch(taskRepositoryProvider).watchSubtasks(taskId),
);

final allSubtasksProvider = StreamProvider<List<Subtask>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAllSubtasks(),
);

final allTaskTagAssignmentsProvider = StreamProvider<List<TaskTagAssignment>>(
  (ref) =>
      ref.watch(organizationRepositoryProvider).watchAllTaskTagAssignments(),
);
