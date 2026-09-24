import 'package:urutau_tasks/src/core/ids.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization_repository.dart';

/// Casos de uso de listas, grupos, categorias e tags (spec 02).
class OrganizationService {
  OrganizationService(
    this._repository, {
    String Function()? generateId,
  }) : _generateId = generateId ?? newId;

  final OrganizationRepository _repository;
  final String Function() _generateId;

  // ---------------------------------------------------------------- listas

  Future<int> countTasksInList(String listId) =>
      _repository.countTasksInList(listId);

  Future<String> createList(String rawName, {String? groupId}) async {
    final name = normalizeName(rawName);
    final lists = await _repository.getLists();
    _ensureFree(name, lists.map((l) => l.name));
    final position = lists.isEmpty
        ? 0
        : lists.map((l) => l.position).reduce((a, b) => a > b ? a : b) + 1;
    final list = TaskList(
      id: _generateId(),
      name: name,
      position: position,
      groupId: groupId,
    );
    await _repository.insertList(list);
    return list.id;
  }

  Future<void> renameList(String id, String rawName) async {
    final name = normalizeName(rawName);
    final lists = await _repository.getLists();
    final current = _requireList(lists, id);
    _ensureFree(name, lists.where((l) => l.id != id).map((l) => l.name));
    await _repository.saveList(current.copyWith(name: name));
  }

  Future<void> moveListToGroup(String listId, String? groupId) async {
    final lists = await _repository.getLists();
    final list = _requireList(lists, listId);
    await _repository.saveList(list.copyWithGroup(groupId));
  }

  /// RF-10/CA-14: ordem manual persistida em transação.
  Future<void> reorderLists(int oldIndex, int newIndex) async {
    final lists = await _repository.getLists();
    final reordered = reorderItems<TaskList>(
      lists,
      oldIndex,
      newIndex,
      (l) => l.position,
      (l, position) => l.copyWith(position: position),
    );
    await _repository.updateListPositions(reordered);
  }

  /// RF-06/CA-06 a CA-08.
  Future<void> deleteList(String id, {String? destinationId}) async {
    final lists = await _repository.getLists();
    _requireList(lists, id);
    final others = lists.where((l) => l.id != id).toList();
    final taskCount = await _repository.countTasksInList(id);

    if (taskCount == 0) {
      await _repository.deleteList(id);
      return;
    }
    if (destinationId == null) {
      if (others.isEmpty) throw const NoDestinationAvailableException();
      throw const ListNotEmptyException();
    }
    if (destinationId == id) {
      throw ArgumentError('The deleted list cannot be the destination.');
    }
    if (!others.any((l) => l.id == destinationId)) {
      throw const NoDestinationAvailableException();
    }
    await _repository.deleteListMovingTasks(id, destinationId);
  }

  // ---------------------------------------------------------------- grupos

  Future<String> createGroup(String rawName) async {
    final name = normalizeName(rawName);
    final groups = await _repository.watchGroups().first;
    _ensureFree(name, groups.map((g) => g.name));
    final position = groups.isEmpty
        ? 0
        : groups.map((g) => g.position).reduce((a, b) => a > b ? a : b) + 1;
    final group = Group(id: _generateId(), name: name, position: position);
    await _repository.insertGroup(group);
    return group.id;
  }

  Future<void> renameGroup(String id, String rawName) async {
    final name = normalizeName(rawName);
    final groups = await _repository.watchGroups().first;
    final current = groups.firstWhere(
      (g) => g.id == id,
      orElse: () => throw StateError('Group not found: $id'),
    );
    _ensureFree(name, groups.where((g) => g.id != id).map((g) => g.name));
    await _repository.saveGroup(current.copyWith(name: name));
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    final groups = await _repository.watchGroups().first;
    final reordered = reorderItems<Group>(
      groups,
      oldIndex,
      newIndex,
      (g) => g.position,
      (g, position) => g.copyWith(position: position),
    );
    await _repository.updateGroupPositions(reordered);
  }

  /// RF-05/CA-09: excluir o grupo preserva as listas.
  Future<void> deleteGroup(String id) => _repository.deleteGroup(id);

  // ----------------------------------------------------------- categorias

  Future<String> createCategory(String rawName) async {
    final name = normalizeName(rawName);
    final categories = await _repository.watchCategories().first;
    _ensureFree(name, categories.map((c) => c.name));
    final category = Category(id: _generateId(), name: name);
    await _repository.insertCategory(category);
    return category.id;
  }

  Future<void> renameCategory(String id, String rawName) async {
    final name = normalizeName(rawName);
    final categories = await _repository.watchCategories().first;
    final current = categories.firstWhere(
      (c) => c.id == id,
      orElse: () => throw StateError('Category not found: $id'),
    );
    _ensureFree(
      name,
      categories.where((c) => c.id != id).map((c) => c.name),
    );
    await _repository.saveCategory(current.copyWith(name: name));
  }

  /// RF-08/CA-11: apenas desvincula das tarefas.
  Future<void> deleteCategory(String id) => _repository.deleteCategory(id);

  // ------------------------------------------------------------------ tags

  Future<String> createTag(String rawName) async {
    final name = normalizeName(rawName);
    final tags = await _repository.watchTags().first;
    _ensureEquivalentFree(name, tags.map((t) => t.name));
    final tag = Tag(id: _generateId(), name: name);
    await _repository.insertTag(tag);
    return tag.id;
  }

  /// Devolve a tag equivalente ou cria uma (RF-09, criação durante a
  /// edição de tarefa; CA-12 não duplica equivalentes).
  Future<Tag> ensureTag(String rawName) async {
    final name = normalizeName(rawName);
    final canonical = canonicalName(name);
    final tags = await _repository.watchTags().first;
    for (final tag in tags) {
      if (canonicalName(tag.name) == canonical) return tag;
    }
    final tag = Tag(id: _generateId(), name: name);
    await _repository.insertTag(tag);
    return tag;
  }

  Future<void> renameTag(String id, String rawName) async {
    final name = normalizeName(rawName);
    final tags = await _repository.watchTags().first;
    final current = tags.firstWhere(
      (t) => t.id == id,
      orElse: () => throw StateError('Tag not found: $id'),
    );
    _ensureEquivalentFree(
      name,
      tags.where((t) => t.id != id).map((t) => t.name),
    );
    await _repository.saveTag(current.copyWith(name: name));
  }

  /// RF-09/CA-13: remove a tag e suas associações.
  Future<void> deleteTag(String id) => _repository.deleteTag(id);

  // -------------------------------------------------------------- internos

  TaskList _requireList(List<TaskList> lists, String id) {
    for (final list in lists) {
      if (list.id == id) return list;
    }
    throw StateError('List not found: $id');
  }

  void _ensureFree(String name, Iterable<String> existing) {
    final canonical = canonicalName(name);
    for (final other in existing) {
      if (canonicalName(other) == canonical) {
        throw DuplicateNameException(name);
      }
    }
  }

  void _ensureEquivalentFree(String name, Iterable<String> existing) =>
      _ensureFree(name, existing);
}
