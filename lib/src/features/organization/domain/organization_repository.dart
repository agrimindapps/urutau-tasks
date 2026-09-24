import 'package:urutau_tasks/src/features/organization/domain/organization.dart';

/// Porta de persistência da organização (spec 02; spec 06, RF-20/RF-21).
///
/// Operações compostas (exclusão de grupo/lista, reordenação) são atômicas
/// no lado Drift (spec 06, RF-04).
abstract interface class OrganizationRepository {
  Stream<List<TaskList>> watchLists();
  Stream<List<Group>> watchGroups();
  Stream<List<Category>> watchCategories();
  Stream<List<Tag>> watchTags();

  Future<List<TaskList>> getLists();
  Future<int> countTasksInList(String listId);

  Future<void> insertList(TaskList list);
  Future<void> saveList(TaskList list);
  Future<void> deleteList(String id);

  /// RF-06/CA-08: move as tarefas da lista de origem para o destino e
  /// remove a origem em uma única transação.
  Future<void> deleteListMovingTasks(String sourceId, String destinationId);

  Future<void> insertGroup(Group group);
  Future<void> saveGroup(Group group);

  /// RF-05/CA-09: remove o grupo e apenas desvincula suas listas.
  Future<void> deleteGroup(String id);

  Future<void> insertCategory(Category category);
  Future<void> saveCategory(Category category);

  /// RF-08/CA-11: remove a categoria e desvincula das tarefas.
  Future<void> deleteCategory(String id);

  Future<void> insertTag(Tag tag);
  Future<void> saveTag(Tag tag);

  /// RF-09/CA-13: remove a tag e suas associações sem tocar nas tarefas.
  Future<void> deleteTag(String id);

  Future<void> updateListPositions(List<TaskList> lists);
  Future<void> updateGroupPositions(List<Group> groups);

  Future<void> setTaskList(String taskId, String? listId);
  Future<void> setTaskCategory(String taskId, String? categoryId);
  Future<void> setTaskTags(String taskId, List<Tag> tags);
}
