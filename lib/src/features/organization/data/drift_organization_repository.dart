import 'dart:async';

import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../domain/organization.dart';
import '../domain/organization_repository.dart';

/// Persistência Drift da organização (spec 02; spec 06, RF-07/RF-21).
class DriftOrganizationRepository implements OrganizationRepository {
  DriftOrganizationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<OrganizationSnapshot> fetchSnapshot() async {
    final listRows = await _db.select(_db.taskLists).get();
    final groupRows = await _db.select(_db.groups).get();
    final categoryRows = await _db.select(_db.categories).get();
    final tagRows = await _db.select(_db.tags).get();
    final countRows = await _db.customSelect(
      'SELECT list_id, COUNT(*) AS cnt FROM tasks '
      'WHERE list_id IS NOT NULL GROUP BY list_id',
      readsFrom: {_db.tasks},
    ).get();

    return OrganizationSnapshot(
      lists: [
        for (final row in listRows) _toList(row),
      ]..sort((a, b) => a.position.compareTo(b.position)),
      groups: [
        for (final row in groupRows) _toGroup(row),
      ]..sort((a, b) => a.position.compareTo(b.position)),
      categories: [
        for (final row in categoryRows) _toCategory(row),
      ]..sort((a, b) => a.name.compareTo(b.name)),
      tags: [
        for (final row in tagRows) _toTag(row),
      ]..sort((a, b) => a.name.compareTo(b.name)),
      taskCountByList: {
        for (final row in countRows)
          row.read<String>('list_id'): row.read<int>('cnt'),
      },
    );
  }

  @override
  Stream<OrganizationSnapshot> watchSnapshot() {
    final controller = StreamController<OrganizationSnapshot>();
    final subscriptions = <StreamSubscription<void>>[];

    Future<void> emit() async {
      if (controller.isClosed) return;
      controller.add(await fetchSnapshot());
    }

    for (final stream in [
      _db.select(_db.taskLists).watch(),
      _db.select(_db.groups).watch(),
      _db.select(_db.categories).watch(),
      _db.select(_db.tags).watch(),
      _db.select(_db.tasks).watch(),
      _db.select(_db.taskTags).watch(),
    ]) {
      subscriptions.add(stream.listen((_) => emit()));
    }
    emit();

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    return controller.stream;
  }

  @override
  Future<void> saveList(TaskList list) async {
    await _db.into(_db.taskLists).insertOnConflictUpdate(
          TaskListsCompanion.insert(
            id: list.id,
            name: list.name,
            position: Value(list.position),
            groupId: Value(list.groupId),
          ),
        );
  }

  @override
  Future<void> saveGroup(TaskGroup group) async {
    await _db.into(_db.groups).insertOnConflictUpdate(
          GroupsCompanion.insert(
            id: group.id,
            name: group.name,
            position: Value(group.position),
          ),
        );
  }

  @override
  Future<void> saveCategory(TaskCategory category) async {
    await _db.into(_db.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(id: category.id, name: category.name),
        );
  }

  @override
  Future<void> saveTag(TaskTag tag) async {
    await _db.into(_db.tags).insertOnConflictUpdate(
          TagsCompanion.insert(
            id: tag.id,
            name: tag.name,
            normalizedName: tag.normalizedName,
          ),
        );
  }

  @override
  Future<void> removeCategory(String categoryId) async {
    // Exclusão só desvincula (spec 02, RF-08).
    await _db.transaction(() async {
      await (_db.update(_db.tasks)
            ..where((t) => t.categoryId.equals(categoryId)))
          .write(const TasksCompanion(categoryId: Value(null)));
      await (_db.delete(_db.categories)..where((c) => c.id.equals(categoryId)))
          .go();
    });
  }

  @override
  Future<void> removeTag(String tagId) async {
    // Exclusão remove apenas as associações (spec 02, RF-09).
    await _db.transaction(() async {
      await (_db.delete(_db.taskTags)..where((t) => t.tagId.equals(tagId)))
          .go();
      await (_db.delete(_db.tags)..where((t) => t.id.equals(tagId))).go();
    });
  }

  @override
  Future<void> removeGroup(String groupId) async {
    // As listas permanecem intactas e sem grupo (spec 02, RF-05).
    await _db.transaction(() async {
      await (_db.update(_db.taskLists)..where((l) => l.groupId.equals(groupId)))
          .write(const TaskListsCompanion(groupId: Value(null)));
      await (_db.delete(_db.groups)..where((g) => g.id.equals(groupId))).go();
    });
  }

  @override
  Future<void> removeEmptyList(String listId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.taskLists)..where((l) => l.id.equals(listId)))
          .go();
    });
  }

  @override
  Future<void> removeListMigratingTasks({
    required String listId,
    required String toListId,
  }) async {
    // Hierarquia inteira migra sem cópia (spec 02, RF-06/RF-07): as
    // subtarefas seguem a tarefa principal pela referência.
    await _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.listId.equals(listId)))
          .write(TasksCompanion(listId: Value(toListId)));
      await (_db.delete(_db.taskLists)..where((l) => l.id.equals(listId)))
          .go();
    });
  }

  TaskList _toList(TaskListRow row) {
    return TaskList(
      id: row.id,
      name: row.name,
      position: row.position,
      groupId: row.groupId,
    );
  }

  TaskGroup _toGroup(GroupRow row) {
    return TaskGroup(id: row.id, name: row.name, position: row.position);
  }

  TaskCategory _toCategory(CategoryRow row) {
    return TaskCategory(id: row.id, name: row.name);
  }

  TaskTag _toTag(TagRow row) {
    return TaskTag(
      id: row.id,
      name: row.name,
      normalizedName: row.normalizedName,
    );
  }
}
