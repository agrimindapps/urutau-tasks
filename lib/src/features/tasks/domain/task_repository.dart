import 'task.dart';

/// Porta de persistência de tarefas (spec 06, RF-21).
///
/// A camada de aplicação orquestra regras; a unidade transacional garante
/// atomicidade das escritas compostas (spec 06, RF-04).
abstract class TaskRepository {
  /// Toda tarefa com suas subtarefas, incluindo as da lixeira.
  Future<List<Task>> fetchAll();

  /// Observa a lista de tarefas reativamente.
  Stream<List<Task>> watchAll();

  Future<Task?> fetchById(String id);

  /// Upsert atômico de várias tarefas em uma única transação
  /// (spec 06, RF-04: concluir ocorrência + criar próxima).
  Future<void> saveTasks(Iterable<Task> tasks);

  /// Upsert atômico da tarefa e de seu conjunto de subtarefas.
  ///
  /// Subtarefas ausentes em [task] são removidas fisicamente;
  /// presentes são inseridas/atualizadas preservando UUIDs.
  Future<void> saveTask(Task task);

  /// Remoção física individual de subtarefa (spec 01, RF-07).
  Future<void> removeSubtask(String subtaskId);
}
