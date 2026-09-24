import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../tasks/domain/task.dart';
import '../domain/organization.dart';

abstract interface class OrganizationRepository {
  Stream<List<TaskGroup>> watchGroups();

  Stream<List<TaskList>> watchLists();

  Stream<List<TaskCategory>> watchCategories();

  Stream<List<TaskTag>> watchTags();

  Stream<List<TaskTag>> watchTaskTags(String taskId);

  Stream<List<TaskTagAssignment>> watchAllTaskTagAssignments();

  Future<TaskGroup> createGroup(String name);

  Future<void> renameGroup(String groupId, String name);

  Future<void> reorderGroups(List<String> orderedGroupIds);

  Future<void> deleteGroup(String groupId);

  Future<TaskList> createList(String name, {String? groupId});

  Future<void> renameList(String listId, String name);

  Future<void> setListGroup(String listId, String? groupId);

  Future<void> reorderLists(List<String> orderedListIds);

  Future<void> deleteList(String listId, {String? destinationListId});

  Future<void> moveTaskToList(String taskId, String? listId);

  Future<TaskCategory> createCategory(String name);

  Future<TaskCategory> createCategoryAndAssignTask(String taskId, String name);

  Future<void> renameCategory(String categoryId, String name);

  Future<void> deleteCategory(String categoryId);

  Future<TaskTag> createOrGetTag(String name);

  Future<TaskTag> createOrGetTagAndAssignTask(String taskId, String name);

  Future<void> renameTag(String tagId, String name);

  Future<void> deleteTag(String tagId);

  Future<void> setTaskCategory(String taskId, String? categoryId);

  Future<void> setTaskTags(String taskId, List<String> tagIds);

  Future<void> setTaskTag(String taskId, String tagId, bool isAssigned);
}

class DriftOrganizationRepository implements OrganizationRepository {
  DriftOrganizationRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<TaskGroup>> watchGroups() =>
      (_database.select(_database.taskGroups)..orderBy([
            (group) => OrderingTerm.asc(group.position),
            (group) => OrderingTerm.asc(group.id),
          ]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (row) => TaskGroup(
                    id: row.id,
                    name: row.name,
                    position: row.position,
                  ),
                )
                .toList(growable: false),
          );

  @override
  Stream<List<TaskList>> watchLists() =>
      (_database.select(_database.taskLists)..orderBy([
            (list) => OrderingTerm.asc(list.position),
            (list) => OrderingTerm.asc(list.name),
          ]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (row) => TaskList(
                    id: row.id,
                    name: row.name,
                    position: row.position,
                    groupId: row.groupId,
                  ),
                )
                .toList(growable: false),
          );

  @override
  Stream<List<TaskCategory>> watchCategories() =>
      (_database.select(
        _database.categories,
      )..orderBy([(category) => OrderingTerm.asc(category.name)])).watch().map(
        (rows) => rows
            .map((row) => TaskCategory(id: row.id, name: row.name))
            .toList(growable: false),
      );

  @override
  Stream<List<TaskTag>> watchTags() =>
      (_database.select(
        _database.tags,
      )..orderBy([(tag) => OrderingTerm.asc(tag.name)])).watch().map(
        (rows) => rows
            .map((row) => TaskTag(id: row.id, name: row.name))
            .toList(growable: false),
      );

  @override
  Stream<List<TaskTag>> watchTaskTags(String taskId) {
    final query =
        _database.select(_database.tags).join([
            innerJoin(
              _database.taskTags,
              _database.taskTags.tagId.equalsExp(_database.tags.id),
            ),
          ])
          ..where(_database.taskTags.taskId.equals(taskId))
          ..orderBy([OrderingTerm.asc(_database.tags.name)]);
    return query.watch().map(
      (rows) => rows
          .map((row) {
            final tag = row.readTable(_database.tags);
            return TaskTag(id: tag.id, name: tag.name);
          })
          .toList(growable: false),
    );
  }

  @override
  Stream<List<TaskTagAssignment>> watchAllTaskTagAssignments() => _database
      .select(_database.taskTags)
      .watch()
      .map(
        (rows) => rows
            .map(
              (row) => TaskTagAssignment(taskId: row.taskId, tagId: row.tagId),
            )
            .toList(growable: false),
      );

  @override
  Future<TaskGroup> createGroup(String name) async {
    final normalizedName = normalizeOrganizationName(name);
    return _database.transaction(() async {
      await _ensureUniqueGroupName(normalizedName);
      final current = await _database.select(_database.taskGroups).get();
      final position = _maxPosition(current.map((row) => row.position));
      final group = TaskGroup(
        id: _uuid.v4(),
        name: normalizedName,
        position: position,
      );
      await _database
          .into(_database.taskGroups)
          .insert(
            TaskGroupsCompanion.insert(
              id: group.id,
              name: group.name,
              position: group.position,
            ),
          );
      return group;
    });
  }

  @override
  Future<void> renameGroup(String groupId, String name) async {
    final normalizedName = normalizeOrganizationName(name);
    await _database.transaction(() async {
      await _groupRecord(groupId);
      await _ensureUniqueGroupName(normalizedName, excludingId: groupId);
      await (_database.update(_database.taskGroups)
            ..where((group) => group.id.equals(groupId)))
          .write(TaskGroupsCompanion(name: Value(normalizedName)));
    });
  }

  @override
  Future<void> reorderGroups(List<String> orderedGroupIds) async {
    await _database.transaction(() async {
      final current = await _database.select(_database.taskGroups).get();
      _validateOrder(orderedGroupIds, current.map((group) => group.id).toSet());
      for (var index = 0; index < orderedGroupIds.length; index++) {
        await (_database.update(_database.taskGroups)
              ..where((group) => group.id.equals(orderedGroupIds[index])))
            .write(TaskGroupsCompanion(position: Value(index)));
      }
    });
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _database.transaction(() async {
      await _groupRecord(groupId);
      await (_database.update(_database.taskLists)
            ..where((list) => list.groupId.equals(groupId)))
          .write(const TaskListsCompanion(groupId: Value(null)));
      await (_database.delete(
        _database.taskGroups,
      )..where((group) => group.id.equals(groupId))).go();
    });
  }

  @override
  Future<TaskList> createList(String name, {String? groupId}) async {
    final normalizedName = normalizeOrganizationName(name);
    return _database.transaction(() async {
      await _ensureUniqueListName(normalizedName);
      if (groupId != null) await _groupRecord(groupId);
      final current = await _database.select(_database.taskLists).get();
      final position = _maxPosition(current.map((row) => row.position));
      final list = TaskList(
        id: _uuid.v4(),
        name: normalizedName,
        position: position,
        groupId: groupId,
      );
      await _database
          .into(_database.taskLists)
          .insert(
            TaskListsCompanion.insert(
              id: list.id,
              name: list.name,
              position: list.position,
              groupId: Value(groupId),
            ),
          );
      return list;
    });
  }

  @override
  Future<void> renameList(String listId, String name) async {
    final normalizedName = normalizeOrganizationName(name);
    await _database.transaction(() async {
      await _listRecord(listId);
      await _ensureUniqueListName(normalizedName, excludingId: listId);
      await (_database.update(_database.taskLists)
            ..where((list) => list.id.equals(listId)))
          .write(TaskListsCompanion(name: Value(normalizedName)));
    });
  }

  @override
  Future<void> setListGroup(String listId, String? groupId) async {
    await _database.transaction(() async {
      await _listRecord(listId);
      if (groupId != null) await _groupRecord(groupId);
      await (_database.update(_database.taskLists)
            ..where((list) => list.id.equals(listId)))
          .write(TaskListsCompanion(groupId: Value(groupId)));
    });
  }

  @override
  Future<void> reorderLists(List<String> orderedListIds) async {
    await _database.transaction(() async {
      final current = await _database.select(_database.taskLists).get();
      _validateOrder(orderedListIds, current.map((list) => list.id).toSet());
      for (var index = 0; index < orderedListIds.length; index++) {
        await (_database.update(_database.taskLists)
              ..where((list) => list.id.equals(orderedListIds[index])))
            .write(TaskListsCompanion(position: Value(index)));
      }
    });
  }

  @override
  Future<void> deleteList(String listId, {String? destinationListId}) async {
    await _database.transaction(() async {
      final source = await _listRecord(listId);
      final tasks =
          await (_database.select(_database.tasks)
                ..where((task) => task.listId.equals(listId))
                ..orderBy([
                  (task) => OrderingTerm.asc(task.position),
                  (task) => OrderingTerm.asc(task.createdAtUtc),
                  (task) => OrderingTerm.asc(task.id),
                ]))
              .get();
      if (tasks.isNotEmpty) {
        if (destinationListId == null || destinationListId == listId) {
          throw const ListHasTasksException();
        }
        await _listRecord(destinationListId);
      }
      if (tasks.isNotEmpty) {
        final destinationTasks = await (_database.select(
          _database.tasks,
        )..where((task) => task.listId.equals(destinationListId!))).get();
        var nextPosition = _maxPosition(
          destinationTasks.map((task) => task.position),
        );
        for (final task in tasks) {
          await (_database.update(
            _database.tasks,
          )..where((row) => row.id.equals(task.id))).write(
            TasksCompanion(
              listId: Value(destinationListId),
              position: Value(nextPosition),
              updatedAtUtc: Value(
                DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            ),
          );
          nextPosition++;
        }
        await _renumberTasksForList(destinationListId);
      }
      await (_database.delete(
        _database.taskLists,
      )..where((list) => list.id.equals(source.id))).go();
    });
  }

  @override
  Future<void> moveTaskToList(String taskId, String? listId) async {
    await _database.transaction(() async {
      final task = await (_database.select(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).getSingleOrNull();
      if (task == null) throw const OrganizationItemNotFoundException();
      _ensureTaskEditable(task.status);
      if (listId != null) await _listRecord(listId);
      if (task.listId == listId) return;

      final destinationQuery = _database.select(_database.tasks);
      if (listId == null) {
        destinationQuery.where((row) => row.listId.isNull());
      } else {
        destinationQuery.where((row) => row.listId.equals(listId));
      }
      final destinationTasks = await destinationQuery.get();
      final position = _maxPosition(
        destinationTasks.map((row) => row.position),
      );
      await (_database.update(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).write(
        TasksCompanion(
          listId: Value(listId),
          position: Value(position),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
      if (task.listId != null) await _renumberTasksForList(task.listId);
      await _renumberTasksForList(listId);
    });
  }

  @override
  Future<TaskCategory> createCategory(String name) async {
    final normalizedName = normalizeOrganizationName(name);
    return _database.transaction(() async {
      await _ensureUniqueCategoryName(normalizedName);
      final category = TaskCategory(id: _uuid.v4(), name: normalizedName);
      await _database
          .into(_database.categories)
          .insert(
            CategoriesCompanion.insert(id: category.id, name: category.name),
          );
      return category;
    });
  }

  @override
  Future<TaskCategory> createCategoryAndAssignTask(
    String taskId,
    String name,
  ) async {
    final normalizedName = normalizeOrganizationName(name);
    return _database.transaction(() async {
      final task = await (_database.select(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).getSingleOrNull();
      if (task == null) throw const OrganizationItemNotFoundException();
      _ensureTaskEditable(task.status);
      await _ensureUniqueCategoryName(normalizedName);

      final category = TaskCategory(id: _uuid.v4(), name: normalizedName);
      await _database
          .into(_database.categories)
          .insert(
            CategoriesCompanion.insert(id: category.id, name: category.name),
          );
      await (_database.update(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).write(
        TasksCompanion(
          categoryId: Value(category.id),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
      return category;
    });
  }

  @override
  Future<void> renameCategory(String categoryId, String name) async {
    final normalizedName = normalizeOrganizationName(name);
    await _database.transaction(() async {
      await _categoryRecord(categoryId);
      await _ensureUniqueCategoryName(normalizedName, excludingId: categoryId);
      await (_database.update(_database.categories)
            ..where((category) => category.id.equals(categoryId)))
          .write(CategoriesCompanion(name: Value(normalizedName)));
    });
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _database.transaction(() async {
      await _categoryRecord(categoryId);
      await (_database.update(
        _database.tasks,
      )..where((task) => task.categoryId.equals(categoryId))).write(
        TasksCompanion(
          categoryId: const Value(null),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
      await (_database.delete(
        _database.categories,
      )..where((category) => category.id.equals(categoryId))).go();
    });
  }

  @override
  Future<TaskTag> createOrGetTag(String name) async {
    final normalizedName = normalizeTagName(name);
    final canonicalName = canonicalTagName(normalizedName);
    return _database.transaction(() async {
      final existing =
          await (_database.select(_database.tags)
                ..where((tag) => tag.normalizedName.equals(canonicalName)))
              .getSingleOrNull();
      if (existing != null) {
        return TaskTag(id: existing.id, name: existing.name);
      }

      final tag = TaskTag(id: _uuid.v4(), name: normalizedName);
      await _database
          .into(_database.tags)
          .insert(
            TagsCompanion.insert(
              id: tag.id,
              name: tag.name,
              normalizedName: canonicalName,
            ),
          );
      return tag;
    });
  }

  @override
  Future<TaskTag> createOrGetTagAndAssignTask(
    String taskId,
    String name,
  ) async {
    final normalizedName = normalizeTagName(name);
    final canonicalName = canonicalTagName(normalizedName);
    return _database.transaction(() async {
      final task = await (_database.select(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).getSingleOrNull();
      if (task == null) throw const OrganizationItemNotFoundException();
      _ensureTaskEditable(task.status);

      final existing =
          await (_database.select(_database.tags)
                ..where((tag) => tag.normalizedName.equals(canonicalName)))
              .getSingleOrNull();
      final tag = existing == null
          ? TaskTag(id: _uuid.v4(), name: normalizedName)
          : TaskTag(id: existing.id, name: existing.name);
      if (existing == null) {
        await _database
            .into(_database.tags)
            .insert(
              TagsCompanion.insert(
                id: tag.id,
                name: tag.name,
                normalizedName: canonicalName,
              ),
            );
      }

      final assignment =
          await (_database.select(_database.taskTags)..where(
                (row) => row.taskId.equals(taskId) & row.tagId.equals(tag.id),
              ))
              .getSingleOrNull();
      if (assignment == null) {
        await _database
            .into(_database.taskTags)
            .insert(TaskTagsCompanion.insert(taskId: taskId, tagId: tag.id));
      }
      await (_database.update(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).write(
        TasksCompanion(
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
      return tag;
    });
  }

  @override
  Future<void> renameTag(String tagId, String name) async {
    final normalizedName = normalizeTagName(name);
    final canonicalName = canonicalTagName(normalizedName);
    await _database.transaction(() async {
      await _tagRecord(tagId);
      final duplicate =
          await (_database.select(_database.tags)..where(
                (tag) =>
                    tag.normalizedName.equals(canonicalName) &
                    tag.id.isNotValue(tagId),
              ))
              .getSingleOrNull();
      if (duplicate != null) {
        throw const DuplicateOrganizationNameException();
      }
      await (_database.update(
        _database.tags,
      )..where((tag) => tag.id.equals(tagId))).write(
        TagsCompanion(
          name: Value(normalizedName),
          normalizedName: Value(canonicalName),
        ),
      );
    });
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await _database.transaction(() async {
      await _tagRecord(tagId);
      final assignments = await (_database.select(
        _database.taskTags,
      )..where((relation) => relation.tagId.equals(tagId))).get();
      await (_database.delete(
        _database.taskTags,
      )..where((relation) => relation.tagId.equals(tagId))).go();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      for (final taskId
          in assignments.map((relation) => relation.taskId).toSet()) {
        await (_database.update(_database.tasks)
              ..where((task) => task.id.equals(taskId)))
            .write(TasksCompanion(updatedAtUtc: Value(now)));
      }
      await (_database.delete(
        _database.tags,
      )..where((tag) => tag.id.equals(tagId))).go();
    });
  }

  @override
  Future<void> setTaskCategory(String taskId, String? categoryId) async {
    await _database.transaction(() async {
      final task = await (_database.select(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).getSingleOrNull();
      if (task == null) throw const OrganizationItemNotFoundException();
      _ensureTaskEditable(task.status);
      if (categoryId != null) await _categoryRecord(categoryId);
      await (_database.update(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).write(
        TasksCompanion(
          categoryId: Value(categoryId),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> setTaskTags(String taskId, List<String> tagIds) async {
    final uniqueTagIds = tagIds.toSet();
    await _database.transaction(() async {
      final task = await (_database.select(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).getSingleOrNull();
      if (task == null) throw const OrganizationItemNotFoundException();
      _ensureTaskEditable(task.status);
      final knownTags = await (_database.select(
        _database.tags,
      )..where((tag) => tag.id.isIn(uniqueTagIds))).get();
      if (knownTags.length != uniqueTagIds.length) {
        throw const OrganizationItemNotFoundException();
      }
      await (_database.delete(
        _database.taskTags,
      )..where((relation) => relation.taskId.equals(taskId))).go();
      for (final tagId in uniqueTagIds) {
        await _database
            .into(_database.taskTags)
            .insert(TaskTagsCompanion.insert(taskId: taskId, tagId: tagId));
      }
      await (_database.update(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).write(
        TasksCompanion(
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> setTaskTag(String taskId, String tagId, bool isAssigned) async {
    await _database.transaction(() async {
      final task = await (_database.select(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).getSingleOrNull();
      if (task == null) throw const OrganizationItemNotFoundException();
      _ensureTaskEditable(task.status);
      await _tagRecord(tagId);
      final relation = _database.taskTags;
      if (isAssigned) {
        final existing =
            await (_database.select(relation)..where(
                  (row) => row.taskId.equals(taskId) & row.tagId.equals(tagId),
                ))
                .getSingleOrNull();
        if (existing == null) {
          await _database
              .into(relation)
              .insert(TaskTagsCompanion.insert(taskId: taskId, tagId: tagId));
        }
      } else {
        await (_database.delete(relation)..where(
              (row) => row.taskId.equals(taskId) & row.tagId.equals(tagId),
            ))
            .go();
      }
      await (_database.update(
        _database.tasks,
      )..where((row) => row.id.equals(taskId))).write(
        TasksCompanion(
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    });
  }

  Future<TaskGroupRecord> _groupRecord(String groupId) async {
    final row = await (_database.select(
      _database.taskGroups,
    )..where((group) => group.id.equals(groupId))).getSingleOrNull();
    if (row == null) throw const OrganizationItemNotFoundException();
    return row;
  }

  Future<TaskListRecord> _listRecord(String listId) async {
    final row = await (_database.select(
      _database.taskLists,
    )..where((list) => list.id.equals(listId))).getSingleOrNull();
    if (row == null) throw const OrganizationItemNotFoundException();
    return row;
  }

  Future<CategoryRecord> _categoryRecord(String categoryId) async {
    final row = await (_database.select(
      _database.categories,
    )..where((category) => category.id.equals(categoryId))).getSingleOrNull();
    if (row == null) throw const OrganizationItemNotFoundException();
    return row;
  }

  Future<TagRecord> _tagRecord(String tagId) async {
    final row = await (_database.select(
      _database.tags,
    )..where((tag) => tag.id.equals(tagId))).getSingleOrNull();
    if (row == null) throw const OrganizationItemNotFoundException();
    return row;
  }

  Future<void> _renumberTasksForList(String? listId) async {
    final query = _database.select(_database.tasks)
      ..orderBy([
        (task) => OrderingTerm.asc(task.position),
        (task) => OrderingTerm.asc(task.createdAtUtc),
        (task) => OrderingTerm.asc(task.id),
      ]);
    if (listId == null) {
      query.where((task) => task.listId.isNull());
    } else {
      query.where((task) => task.listId.equals(listId));
    }
    final rows = await query.get();
    for (var index = 0; index < rows.length; index++) {
      await (_database.update(_database.tasks)
            ..where((task) => task.id.equals(rows[index].id)))
          .write(TasksCompanion(position: Value(index)));
    }
  }

  Future<void> _ensureUniqueGroupName(
    String name, {
    String? excludingId,
  }) async {
    final rows = await _database.select(_database.taskGroups).get();
    if (rows.any((row) => row.id != excludingId && row.name == name)) {
      throw const DuplicateOrganizationNameException();
    }
  }

  Future<void> _ensureUniqueListName(String name, {String? excludingId}) async {
    final rows = await _database.select(_database.taskLists).get();
    if (rows.any((row) => row.id != excludingId && row.name == name)) {
      throw const DuplicateOrganizationNameException();
    }
  }

  Future<void> _ensureUniqueCategoryName(
    String name, {
    String? excludingId,
  }) async {
    final rows = await _database.select(_database.categories).get();
    if (rows.any((row) => row.id != excludingId && row.name == name)) {
      throw const DuplicateOrganizationNameException();
    }
  }

  void _ensureTaskEditable(int status) {
    if (status == TaskStatus.trashed.databaseValue) {
      throw const TaskUnavailableException();
    }
  }

  void _validateOrder(List<String> requested, Set<String> existing) {
    if (requested.toSet().length != requested.length ||
        requested.length != existing.length ||
        !requested.toSet().containsAll(existing)) {
      throw const OrganizationItemNotFoundException();
    }
  }

  int _maxPosition(Iterable<int> positions) =>
      positions.fold<int>(-1, (max, current) => current > max ? current : max) +
      1;
}
