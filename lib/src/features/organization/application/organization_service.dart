import '../../../core/ids.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/organization.dart';
import '../domain/organization_repository.dart';

/// Casos de uso de listas, grupos, categorias e tags (spec 02).
class OrganizationService {
  OrganizationService(
    this._repository,
    this._taskRepository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final OrganizationRepository _repository;
  final TaskRepository _taskRepository;
  final DateTime Function() _clock;

  Future<OrganizationSnapshot> fetchSnapshot() => _repository.fetchSnapshot();

  Stream<OrganizationSnapshot> watchSnapshot() =>
      _repository.watchSnapshot();

  // ---------------------------------------------------------------- listas

  Future<TaskList> createList({required String name, String? groupId}) async {
    final snapshot = await _repository.fetchSnapshot();
    final trimmed = validateName(name);
    _ensureUnique(snapshot.lists.map((l) => l.name), trimmed);
    if (groupId != null) {
      _requireGroup(snapshot, groupId);
    }
    final list = TaskList.create(
      id: newId(),
      name: trimmed,
      position: _nextListPosition(snapshot),
      groupId: groupId,
    );
    await _repository.saveList(list);
    return list;
  }

  Future<TaskList> renameList(String listId, {required String name}) async {
    final snapshot = await _repository.fetchSnapshot();
    final current = _requireList(snapshot, listId);
    final trimmed = validateName(name);
    _ensureUnique(
      snapshot.lists.where((l) => l.id != listId).map((l) => l.name),
      trimmed,
    );
    final renamed = current.rename(trimmed);
    await _repository.saveList(renamed);
    return renamed;
  }

  Future<TaskList> moveListToGroup(String listId, String? groupId) async {
    final snapshot = await _repository.fetchSnapshot();
    final current = _requireList(snapshot, listId);
    if (groupId != null) {
      _requireGroup(snapshot, groupId);
    }
    final moved = current.moveToGroup(groupId);
    await _repository.saveList(moved);
    return moved;
  }

  Future<void> reorderLists(List<String> orderedIds) async {
    final snapshot = await _repository.fetchSnapshot();
    final byId = {for (final l in snapshot.lists) l.id: l};
    if (orderedIds.length != byId.length ||
        !orderedIds.toSet().containsAll(byId.keys)) {
      throw const OrganizationException(OrganizationFailure.unknownList);
    }
    for (var i = 0; i < orderedIds.length; i++) {
      await _repository.saveList(byId[orderedIds[i]]!.copyWith(position: i));
    }
  }

  /// Exclui lista: vazia é direta; com tarefas exige lista destino
  /// (spec 02, RF-06).
  Future<void> deleteList(
    String listId, {
    String? destinationListId,
  }) async {
    final snapshot = await _repository.fetchSnapshot();
    final current = _requireList(snapshot, listId);
    final taskCount = snapshot.taskCount(current.id);

    if (taskCount == 0) {
      await _repository.removeEmptyList(current.id);
      return;
    }

    if (destinationListId == null) {
      // Sem destino disponível a exclusão fica bloqueada (spec 02, RF-06).
      throw const OrganizationException(OrganizationFailure.listNotEmpty);
    }
    if (destinationListId == current.id) {
      throw const OrganizationException(OrganizationFailure.sameDestination);
    }
    final destination = _requireList(snapshot, destinationListId);
    await _repository.removeListMigratingTasks(
      listId: current.id,
      toListId: destination.id,
    );
  }

  // ---------------------------------------------------------------- grupos

  Future<TaskGroup> createGroup({required String name}) async {
    final snapshot = await _repository.fetchSnapshot();
    final trimmed = validateName(name);
    _ensureUnique(snapshot.groups.map((g) => g.name), trimmed);
    final group = TaskGroup.create(
      id: newId(),
      name: trimmed,
      position: snapshot.groups.isEmpty
          ? 0
          : snapshot.groups
                  .map((g) => g.position)
                  .reduce((a, b) => a > b ? a : b) +
              1,
    );
    await _repository.saveGroup(group);
    return group;
  }

  Future<TaskGroup> renameGroup(String groupId, {required String name}) async {
    final snapshot = await _repository.fetchSnapshot();
    final current = _requireGroup(snapshot, groupId);
    final trimmed = validateName(name);
    _ensureUnique(
      snapshot.groups.where((g) => g.id != groupId).map((g) => g.name),
      trimmed,
    );
    final renamed = current.rename(trimmed);
    await _repository.saveGroup(renamed);
    return renamed;
  }

  Future<void> reorderGroups(List<String> orderedIds) async {
    final snapshot = await _repository.fetchSnapshot();
    final byId = {for (final g in snapshot.groups) g.id: g};
    if (orderedIds.length != byId.length ||
        !orderedIds.toSet().containsAll(byId.keys)) {
      throw const OrganizationException(OrganizationFailure.unknownGroup);
    }
    for (var i = 0; i < orderedIds.length; i++) {
      await _repository.saveGroup(byId[orderedIds[i]]!.copyWith(position: i));
    }
  }

  /// Exclui grupo mantendo as listas intactas (spec 02, RF-05).
  Future<void> deleteGroup(String groupId) async {
    final snapshot = await _repository.fetchSnapshot();
    _requireGroup(snapshot, groupId);
    await _repository.removeGroup(groupId);
  }

  // ------------------------------------------------------------ categorias

  Future<TaskCategory> createCategory({required String name}) async {
    final snapshot = await _repository.fetchSnapshot();
    final trimmed = validateName(name);
    _ensureUnique(snapshot.categories.map((c) => c.name), trimmed);
    final category = TaskCategory.create(id: newId(), name: trimmed);
    await _repository.saveCategory(category);
    return category;
  }

  Future<TaskCategory> renameCategory(
    String categoryId, {
    required String name,
  }) async {
    final snapshot = await _repository.fetchSnapshot();
    final current = _requireCategory(snapshot, categoryId);
    final trimmed = validateName(name);
    _ensureUnique(
      snapshot.categories.where((c) => c.id != categoryId).map((c) => c.name),
      trimmed,
    );
    final renamed = current.rename(trimmed);
    await _repository.saveCategory(renamed);
    return renamed;
  }

  /// Exclui categoria desvinculando das tarefas (spec 02, RF-08).
  Future<void> deleteCategory(String categoryId) async {
    final snapshot = await _repository.fetchSnapshot();
    _requireCategory(snapshot, categoryId);
    await _repository.removeCategory(categoryId);
  }

  // ------------------------------------------------------------------ tags

  /// Cria tag; nomes equivalentes após normalização são rejeitados
  /// (spec 02, RF-01/RF-09, CA-12).
  Future<TaskTag> createTag({required String name}) async {
    final snapshot = await _repository.fetchSnapshot();
    final tag = TaskTag.create(id: newId(), name: name);
    final equivalent = snapshot.tags
        .where((t) => t.normalizedName == tag.normalizedName)
        .toList();
    if (equivalent.isNotEmpty) {
      throw const OrganizationException(OrganizationFailure.duplicateName);
    }
    await _repository.saveTag(tag);
    return tag;
  }

  /// Devolve a tag equivalente existente ou cria uma nova.
  Future<TaskTag> ensureTag({required String name}) async {
    final snapshot = await _repository.fetchSnapshot();
    final normalized = normalizeTagName(name);
    final existing = snapshot.tags
        .where((t) => t.normalizedName == normalized)
        .toList();
    if (existing.isNotEmpty) return existing.first;
    final tag = TaskTag.create(id: newId(), name: name);
    await _repository.saveTag(tag);
    return tag;
  }

  Future<TaskTag> renameTag(String tagId, {required String name}) async {
    final snapshot = await _repository.fetchSnapshot();
    final current = _requireTag(snapshot, tagId);
    final renamed = current.rename(name);
    final equivalent = snapshot.tags
        .where((t) => t.id != tagId && t.normalizedName == renamed.normalizedName)
        .toList();
    if (equivalent.isNotEmpty) {
      throw const OrganizationException(OrganizationFailure.duplicateName);
    }
    await _repository.saveTag(renamed);
    return renamed;
  }

  /// Exclui tag removendo as associações (spec 02, RF-09).
  Future<void> deleteTag(String tagId) async {
    final snapshot = await _repository.fetchSnapshot();
    _requireTag(snapshot, tagId);
    await _repository.removeTag(tagId);
  }

  // ------------------------------------------------------- atribuições

  /// Move a tarefa para uma lista (ou inbox com nulo), preservando a
  /// hierarquia (spec 02, RF-03/RF-07).
  Future<Task> assignListToTask(String taskId, String? listId) async {
    final task = await _requireTask(taskId);
    if (listId != null) {
      final snapshot = await _repository.fetchSnapshot();
      _requireList(snapshot, listId);
    }
    final updated = task.assignList(listId, at: _clock());
    await _taskRepository.saveTask(updated);
    return updated;
  }

  /// Define a categoria única da tarefa (spec 02, RF-08).
  Future<Task> assignCategoryToTask(String taskId, String? categoryId) async {
    final task = await _requireTask(taskId);
    if (categoryId != null) {
      final snapshot = await _repository.fetchSnapshot();
      _requireCategory(snapshot, categoryId);
    }
    final updated = task.assignCategory(categoryId, at: _clock());
    await _taskRepository.saveTask(updated);
    return updated;
  }

  /// Associa uma tag existente à tarefa (spec 02, RF-09).
  Future<Task> addTagToTask(String taskId, String tagId) async {
    final task = await _requireTask(taskId);
    final snapshot = await _repository.fetchSnapshot();
    _requireTag(snapshot, tagId);
    final updated = task.addTagId(tagId, at: _clock());
    await _taskRepository.saveTask(updated);
    return updated;
  }

  /// Cria (ou reutiliza) tag pelo nome e associa à tarefa.
  Future<Task> addTagToTaskByName(String taskId, String name) async {
    final tag = await ensureTag(name: name);
    return addTagToTask(taskId, tag.id);
  }

  /// Remove a associação da tag na tarefa (spec 02, RF-09).
  Future<Task> removeTagFromTask(String taskId, String tagId) async {
    final task = await _requireTask(taskId);
    final updated = task.removeTagId(tagId, at: _clock());
    await _taskRepository.saveTask(updated);
    return updated;
  }

  // ------------------------------------------------------------- apoio

  void _ensureUnique(Iterable<String> names, String candidate) {
    if (names.any((n) => n == candidate)) {
      throw const OrganizationException(OrganizationFailure.duplicateName);
    }
  }

  TaskList _requireList(OrganizationSnapshot snapshot, String id) {
    return snapshot.lists.firstWhere(
      (l) => l.id == id,
      orElse: () =>
          throw const OrganizationException(OrganizationFailure.unknownList),
    );
  }

  TaskGroup _requireGroup(OrganizationSnapshot snapshot, String id) {
    return snapshot.groups.firstWhere(
      (g) => g.id == id,
      orElse: () =>
          throw const OrganizationException(OrganizationFailure.unknownGroup),
    );
  }

  TaskCategory _requireCategory(OrganizationSnapshot snapshot, String id) {
    return snapshot.categories.firstWhere(
      (c) => c.id == id,
      orElse: () =>
          throw const OrganizationException(OrganizationFailure.unknownCategory),
    );
  }

  TaskTag _requireTag(OrganizationSnapshot snapshot, String id) {
    return snapshot.tags.firstWhere(
      (t) => t.id == id,
      orElse: () =>
          throw const OrganizationException(OrganizationFailure.unknownTag),
    );
  }

  Future<Task> _requireTask(String id) async {
    final task = await _taskRepository.fetchById(id);
    if (task == null) {
      throw const TaskException(TaskFailure.unknownTask);
    }
    return task;
  }

  int _nextListPosition(OrganizationSnapshot snapshot) {
    if (snapshot.lists.isEmpty) return 0;
    return snapshot.lists
            .map((l) => l.position)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }
}
