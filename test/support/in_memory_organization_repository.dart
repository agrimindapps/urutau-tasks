import 'dart:async';

import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization_repository.dart';

import 'in_memory_task_repository.dart';

/// Repositório de organização em memória para testes (spec 06, RF-26).
///
/// Compartilha o armazenamento de tarefas com [InMemoryTaskRepository],
/// como os repositórios Drift compartilham o banco.
class InMemoryOrganizationRepository implements OrganizationRepository {
  InMemoryOrganizationRepository(this._taskStore);

  final InMemoryTaskRepository _taskStore;
  final _lists = <String, TaskList>{};
  final _groups = <String, TaskGroup>{};
  final _categories = <String, TaskCategory>{};
  final _tags = <String, TaskTag>{};
  final _controller = StreamController<OrganizationSnapshot>.broadcast();

  OrganizationSnapshot _snapshot() {
    final counts = <String, int>{};
    for (final task in _taskStore.allTasks) {
      final listId = task.listId;
      if (listId != null) {
        counts[listId] = (counts[listId] ?? 0) + 1;
      }
    }
    return OrganizationSnapshot(
      lists: _lists.values.toList()
        ..sort((a, b) => a.position.compareTo(b.position)),
      groups: _groups.values.toList()
        ..sort((a, b) => a.position.compareTo(b.position)),
      categories: _categories.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
      tags: _tags.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
      taskCountByList: counts,
    );
  }

  void _notify() => _controller.add(_snapshot());

  @override
  Future<OrganizationSnapshot> fetchSnapshot() async => _snapshot();

  @override
  Stream<OrganizationSnapshot> watchSnapshot() async* {
    yield _snapshot();
    yield* _controller.stream;
  }

  @override
  Future<void> saveList(TaskList list) async {
    _lists[list.id] = list;
    _notify();
  }

  @override
  Future<void> saveGroup(TaskGroup group) async {
    _groups[group.id] = group;
    _notify();
  }

  @override
  Future<void> saveCategory(TaskCategory category) async {
    _categories[category.id] = category;
    _notify();
  }

  @override
  Future<void> saveTag(TaskTag tag) async {
    _tags[tag.id] = tag;
    _notify();
  }

  @override
  Future<void> removeCategory(String categoryId) async {
    _categories.remove(categoryId);
    for (final task in _taskStore.allTasks.toList()) {
      if (task.categoryId == categoryId) {
        await _taskStore.saveTask(task.assignCategory(null));
      }
    }
    _notify();
  }

  @override
  Future<void> removeTag(String tagId) async {
    _tags.remove(tagId);
    for (final task in _taskStore.allTasks.toList()) {
      if (task.tagIds.contains(tagId)) {
        await _taskStore.saveTask(task.removeTagId(tagId));
      }
    }
    _notify();
  }

  @override
  Future<void> removeGroup(String groupId) async {
    _groups.remove(groupId);
    for (final list in _lists.values.toList()) {
      if (list.groupId == groupId) {
        _lists[list.id] = list.moveToGroup(null);
      }
    }
    _notify();
  }

  @override
  Future<void> removeEmptyList(String listId) async {
    _lists.remove(listId);
    _notify();
  }

  @override
  Future<void> removeListMigratingTasks({
    required String listId,
    required String toListId,
  }) async {
    for (final task in _taskStore.allTasks.toList()) {
      if (task.listId == listId) {
        await _taskStore.saveTask(task.assignList(toListId));
      }
    }
    _lists.remove(listId);
    _notify();
  }

  Iterable<TaskList> get allLists => _lists.values;
  Iterable<TaskGroup> get allGroups => _groups.values;
  Iterable<TaskCategory> get allCategories => _categories.values;
  Iterable<TaskTag> get allTags => _tags.values;
}
