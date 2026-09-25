import 'organization.dart';

/// Porta de persistência da organização (spec 02; spec 06, RF-07/RF-21).
abstract class OrganizationRepository {
  /// Listas, grupos, categorias e tags com a contagem de tarefas por lista.
  Future<OrganizationSnapshot> fetchSnapshot();

  /// Observa a organização reativamente.
  Stream<OrganizationSnapshot> watchSnapshot();

  Future<void> saveList(TaskList list);
  Future<void> saveGroup(TaskGroup group);
  Future<void> saveCategory(TaskCategory category);
  Future<void> saveTag(TaskTag tag);

  /// Exclui categoria desvinculando das tarefas (spec 02, RF-08).
  Future<void> removeCategory(String categoryId);

  /// Exclui tag removendo as associações (spec 02, RF-09).
  Future<void> removeTag(String tagId);

  /// Exclui o grupo mantendo as listas intactas e sem grupo (spec 02, RF-05).
  Future<void> removeGroup(String groupId);

  /// Exclui lista vazia em transação (spec 02, RF-06).
  Future<void> removeEmptyList(String listId);

  /// Move a hierarquia de tarefas para [toListId] sem cópia e exclui a lista
  /// de origem em uma única transação (spec 02, RF-06/RF-07; spec 06, RF-04).
  Future<void> removeListMigratingTasks({
    required String listId,
    required String toListId,
  });
}

/// Retrato imutável da organização atual.
class OrganizationSnapshot {
  const OrganizationSnapshot({
    required this.lists,
    required this.groups,
    required this.categories,
    required this.tags,
    required this.taskCountByList,
  });

  final List<TaskList> lists;
  final List<TaskGroup> groups;
  final List<TaskCategory> categories;
  final List<TaskTag> tags;

  /// Tarefas (principal + subtarefas migram junto) por lista.
  final Map<String, int> taskCountByList;

  int taskCount(String listId) => taskCountByList[listId] ?? 0;
}
