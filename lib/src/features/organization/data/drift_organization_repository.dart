import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../organization/domain/organization.dart';
import '../../organization/domain/organization_repository.dart';

/// Implementação Drift do repositório de organização.
class DriftOrganizationRepository implements OrganizationRepository {
  DriftOrganizationRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<TaskList>> watchLists() {
    return (_db.select(_db.taskLists)
          ..orderBy([
            (l) => OrderingTerm.asc(l.position),
            (l) => OrderingTerm.asc(l.name),
          ]))
        .watch()
        .map((rows) => rows.map(_toList).toList());
  }

  @override
  Stream<List<Group>> watchGroups() {
    return (_db.select(_db.groups)
          ..orderBy([
            (g) => OrderingTerm.asc(g.position),
            (g) => OrderingTerm.asc(g.name),
          ]))
        .watch()
        .map((rows) => rows.map(_toGroup).toList());
  }

  @override
  Stream<List<Category>> watchCategories() {
    return (_db.select(_db.categories)..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch()
        .map((rows) => rows.map(_toCategory).toList());
  }

  @override
  Stream<List<Tag>> watchTags() {
    return (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(_toTag).toList());
  }

  @override
  Future<List<TaskList>> getLists() async {
    final rows = await (_db.select(_db.taskLists)
          ..orderBy([
            (l) => OrderingTerm.asc(l.position),
            (l) => OrderingTerm.asc(l.name),
          ]))
        .get();
    return rows.map(_toList).toList();
  }

  @override
  Future<int> countTasksInList(String listId) async {
    final count = _db.tasks.id.count();
    final query = _db.selectOnly(_db.tasks)
      ..addColumns([count])
      ..where(_db.tasks.listId.equals(listId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<void> insertList(TaskList list) =>
      _db.into(_db.taskLists).insert(_listCompanion(list));

  @override
  Future<void> saveList(TaskList list) => _db
      .update(_db.taskLists)
      .replace(_listCompanion(list));

  @override
  Future<void> deleteList(String id) =>
      (_db.delete(_db.taskLists)..where((l) => l.id.equals(id))).go();

  @override
  Future<void> deleteListMovingTasks(String sourceId, String destinationId) {
    return _db.transaction(() async {
      await (_db.update(_db.tasks)
            ..where((t) => t.listId.equals(sourceId)))
          .write(TasksCompanion(listId: Value(destinationId)));
      await (_db.delete(_db.taskLists)
            ..where((l) => l.id.equals(sourceId)))
          .go();
    });
  }

  @override
  Future<void> insertGroup(Group group) =>
      _db.into(_db.groups).insert(_groupCompanion(group));

  @override
  Future<void> saveGroup(Group group) =>
      _db.update(_db.groups).replace(_groupCompanion(group));

  @override
  Future<void> deleteGroup(String id) {
    return _db.transaction(() async {
      await (_db.update(_db.taskLists)
            ..where((l) => l.groupId.equals(id)))
          .write(const TaskListsCompanion(groupId: Value(null)));
      await (_db.delete(_db.groups)..where((g) => g.id.equals(id))).go();
    });
  }

  @override
  Future<void> insertCategory(Category category) =>
      _db.into(_db.categories).insert(_categoryCompanion(category));

  @override
  Future<void> saveCategory(Category category) =>
      _db.update(_db.categories).replace(_categoryCompanion(category));

  @override
  Future<void> deleteCategory(String id) {
    return _db.transaction(() async {
      await (_db.update(_db.tasks)
            ..where((t) => t.categoryId.equals(id)))
          .write(const TasksCompanion(categoryId: Value(null)));
      await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    });
  }

  @override
  Future<void> insertTag(Tag tag) =>
      _db.into(_db.tags).insert(_tagCompanion(tag));

  @override
  Future<void> saveTag(Tag tag) => _db.update(_db.tags).replace(_tagCompanion(tag));

  @override
  Future<void> deleteTag(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.taskTags)..where((tt) => tt.tagId.equals(id)))
          .go();
      await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> updateListPositions(List<TaskList> lists) {
    return _db.transaction(() async {
      for (final list in lists) {
        await (_db.update(_db.taskLists)..where((l) => l.id.equals(list.id)))
            .write(_listCompanion(list));
      }
    });
  }

  @override
  Future<void> updateGroupPositions(List<Group> groups) {
    return _db.transaction(() async {
      for (final group in groups) {
        await (_db.update(_db.groups)..where((g) => g.id.equals(group.id)))
            .write(_groupCompanion(group));
      }
    });
  }

  @override
  Future<void> setTaskList(String taskId, String? listId) =>
      (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
          .write(TasksCompanion(listId: Value(listId)));

  @override
  Future<void> setTaskCategory(String taskId, String? categoryId) =>
      (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
          .write(TasksCompanion(categoryId: Value(categoryId)));

  @override
  Future<void> setTaskTags(String taskId, List<Tag> tags) {
    return _db.transaction(() async {
      await (_db.delete(_db.taskTags)..where((tt) => tt.taskId.equals(taskId)))
          .go();
      if (tags.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.taskTags, [
            for (final tag in tags)
              TaskTagsCompanion.insert(taskId: taskId, tagId: tag.id),
          ]);
        });
      }
    });
  }

  TaskList _toList(TaskListRecord row) => TaskList(
        id: row.id,
        name: row.name,
        position: row.position,
        groupId: row.groupId,
      );

  Group _toGroup(GroupRecord row) => Group(
        id: row.id,
        name: row.name,
        position: row.position,
      );

  Category _toCategory(CategoryRecord row) =>
      Category(id: row.id, name: row.name);

  Tag _toTag(TagRecord row) => Tag(id: row.id, name: row.name);

  TaskListsCompanion _listCompanion(TaskList list) => TaskListsCompanion(
        id: Value(list.id),
        name: Value(list.name),
        position: Value(list.position),
        groupId: Value(list.groupId),
      );

  GroupsCompanion _groupCompanion(Group group) => GroupsCompanion(
        id: Value(group.id),
        name: Value(group.name),
        position: Value(group.position),
      );

  CategoriesCompanion _categoryCompanion(Category category) =>
      CategoriesCompanion(id: Value(category.id), name: Value(category.name));

  TagsCompanion _tagCompanion(Tag tag) =>
      TagsCompanion(id: Value(tag.id), name: Value(tag.name));
}
