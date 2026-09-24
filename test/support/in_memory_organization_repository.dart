import 'dart:async';

import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization_repository.dart';

import 'in_memory_task_repository.dart';

/// Repositório de organização em memória para testes (spec 06, RF-26),
/// com as operações compostas espelhando as regras de domínio.
class InMemoryOrganizationRepository implements OrganizationRepository {
  InMemoryOrganizationRepository(this._tasks);

  final InMemoryTaskRepository _tasks;

  final _lists = <String, TaskList>{};
  final _groups = <String, Group>{};
  final _categories = <String, Category>{};
  final _tags = <String, Tag>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  void _notify() => _changes.add(null);

  List<TaskList> _sortedLists() => _lists.values.toList()
    ..sort((a, b) {
      final byPosition = a.position.compareTo(b.position);
      if (byPosition != 0) return byPosition;
      return a.name.compareTo(b.name);
    });

  List<Group> _sortedGroups() => _groups.values.toList()
    ..sort((a, b) => a.position.compareTo(b.position));

  Stream<List<T>> _watch<T>(List<T> Function() load) async* {
    yield load();
    yield* _changes.stream.map((_) => load());
  }

  @override
  Stream<List<TaskList>> watchLists() => _watch(_sortedLists);

  @override
  Stream<List<Group>> watchGroups() => _watch(_sortedGroups);

  @override
  Stream<List<Category>> watchCategories() =>
      _watch(() => _categories.values.toList()..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Stream<List<Tag>> watchTags() =>
      _watch(() => _tags.values.toList()..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<List<TaskList>> getLists() async => _sortedLists();

  @override
  Future<int> countTasksInList(String listId) async =>
      _tasks.countInList(listId);

  @override
  Future<void> insertList(TaskList list) async {
    _lists[list.id] = list;
    _notify();
  }

  @override
  Future<void> saveList(TaskList list) async {
    _lists[list.id] = list;
    _notify();
  }

  @override
  Future<void> deleteList(String id) async {
    _lists.remove(id);
    _notify();
  }

  @override
  Future<void> deleteListMovingTasks(String sourceId, String destId) async {
    _tasks.moveTasksToList(sourceId, destId);
    _lists.remove(sourceId);
    _notify();
  }

  @override
  Future<void> insertGroup(Group group) async {
    _groups[group.id] = group;
    _notify();
  }

  @override
  Future<void> saveGroup(Group group) async {
    _groups[group.id] = group;
    _notify();
  }

  @override
  Future<void> deleteGroup(String id) async {
    for (final entry in _lists.entries.toList()) {
      if (entry.value.groupId == id) {
        _lists[entry.key] = entry.value.copyWithGroup(null);
      }
    }
    _groups.remove(id);
    _notify();
  }

  @override
  Future<void> insertCategory(Category category) async {
    _categories[category.id] = category;
    _notify();
  }

  @override
  Future<void> saveCategory(Category category) async {
    _categories[category.id] = category;
    _notify();
  }

  @override
  Future<void> deleteCategory(String id) async {
    _tasks.unbindCategory(id);
    _categories.remove(id);
    _notify();
  }

  @override
  Future<void> insertTag(Tag tag) async {
    _tags[tag.id] = tag;
    _notify();
  }

  @override
  Future<void> saveTag(Tag tag) async {
    _tags[tag.id] = tag;
    _notify();
  }

  @override
  Future<void> deleteTag(String id) async {
    _tasks.removeTagEverywhere(id);
    _tags.remove(id);
    _notify();
  }

  @override
  Future<void> updateListPositions(List<TaskList> lists) async {
    for (final list in lists) {
      _lists[list.id] = list;
    }
    _notify();
  }

  @override
  Future<void> updateGroupPositions(List<Group> groups) async {
    for (final group in groups) {
      _groups[group.id] = group;
    }
    _notify();
  }

  @override
  Future<void> setTaskList(String taskId, String? listId) async {
    final task = _tasks.taskById(taskId);
    if (task == null) return;
    _tasks.updateTask(
      listId == null
          ? task.copyWith(clearListId: true)
          : task.copyWith(listId: listId),
    );
    _notify();
  }

  @override
  Future<void> setTaskCategory(String taskId, String? categoryId) async {
    final task = _tasks.taskById(taskId);
    if (task == null) return;
    _tasks.updateTask(
      categoryId == null
          ? task.copyWith(clearCategoryId: true)
          : task.copyWith(categoryId: categoryId),
    );
    _notify();
  }

  @override
  Future<void> setTaskTags(String taskId, List<Tag> tags) async {
    final task = _tasks.taskById(taskId);
    if (task == null) return;
    _tasks.updateTask(task.copyWith(tags: tags));
    _notify();
  }
}
