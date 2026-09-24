import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

/// Porta de persistência de tarefas (spec 06, RF-20/RF-21).
///
/// As regras de negócio ficam na camada de aplicação; este contrato apenas
/// lê, grava e observa registros já convertidos para o domínio.
abstract interface class TaskRepository {
  /// Observa tarefas ordenadas por posição; quando [includeTrashed] é
  /// `false`, a lixeira fica oculta (spec 06, RF-14).
  Stream<List<Task>> watchTasks({bool includeTrashed = false});

  /// Observa uma tarefa com suas subtarefas; emite `null` se não existir.
  Stream<Task?> watchTask(String id);

  Future<Task?> getTask(String id);

  /// Insere a tarefa completa (tarefa + subtarefas) em uma transação.
  Future<void> insertTask(Task task);

  /// Atualiza tarefa e substitui o conjunto de subtarefas em uma transação.
  Future<void> saveTask(Task task);

  Future<void> deleteSubtask(String subtaskId);

  /// Próxima posição global para uma nova tarefa.
  Future<int> nextTaskPosition();

  /// Próxima posição dentro da tarefa informada.
  Future<int> nextSubtaskPosition(String taskId);
}
