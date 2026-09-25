import '../../../core/ids.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Casos de uso do ciclo de tarefas e subtarefas (spec 01).
///
/// Regras de transição no domínio; orquestração e persistência aqui.
class TasksService {
  TasksService(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final TaskRepository _repository;
  final DateTime Function() _clock;

  Future<List<Task>> fetchTasks() => _repository.fetchAll();

  Future<Task?> fetchTask(String id) => _repository.fetchById(id);

  /// Cria tarefa ativa com título validado (spec 01, RF-01/RF-02/RF-03).
  Future<Task> createTask({required String title, String notes = ''}) async {
    final existing = await _repository.fetchAll();
    final task = Task.create(
      id: newId(),
      title: title,
      notes: notes,
      createdAt: _clock(),
      position: _nextPosition(existing),
    );
    await _repository.saveTask(task);
    return task;
  }

  /// Edita título/notas preservando identidade e subtarefas (spec 01, RF-03).
  Future<Task> renameTask(
    String id, {
    required String title,
    String? notes,
  }) async {
    final task = await _require(id);
    final updated = task.rename(title: title, notes: notes, at: _clock());
    await _repository.saveTask(updated);
    return updated;
  }

  /// Conclui sem alterar subtarefas (spec 01, RF-04). Pendências não bloqueiam.
  Future<Task> completeTask(String id) async {
    final task = await _require(id);
    final updated = task.complete(at: _clock());
    await _repository.saveTask(updated);
    return updated;
  }

  /// Reabre preservando estados das subtarefas (spec 01, RF-04/CA-08).
  Future<Task> reopenTask(String id) async {
    final task = await _require(id);
    final updated = task.reopen(at: _clock());
    await _repository.saveTask(updated);
    return updated;
  }

  /// Exclusão lógica da hierarquia preservando dados (spec 01, RF-09).
  Future<Task> moveToTrash(String id) async {
    final task = await _require(id);
    final updated = task.moveToTrash(at: _clock());
    await _repository.saveTask(updated);
    return updated;
  }

  /// Restaura a hierarquia ao estado anterior (spec 01, RF-10).
  Future<Task> restore(String id) async {
    final task = await _require(id);
    final updated = task.restore(at: _clock());
    await _repository.saveTask(updated);
    return updated;
  }

  /// Adiciona etapa validada ao final da ordem (spec 01, RF-05/RF-06).
  Future<Task> addSubtask(String taskId, {required String description}) async {
    final task = await _require(taskId);
    final updated = task.addSubtask(id: newId(), description: description);
    await _repository.saveTask(updated);
    return updated;
  }

  /// Renomeia etapa preservando estado e posição (spec 01, RF-05).
  Future<Task> renameSubtask(
    String taskId,
    String subtaskId, {
    required String description,
  }) async {
    final task = await _require(taskId);
    final current = _requireSubtask(task, subtaskId);
    final updated = task.updateSubtask(current.rename(description));
    await _repository.saveTask(updated);
    return updated;
  }

  /// Conclui/reabre a etapa sem tocar na tarefa principal (spec 01, RF-05).
  Future<Task> setSubtaskCompleted(
    String taskId,
    String subtaskId, {
    required bool completed,
  }) async {
    final task = await _require(taskId);
    final current = _requireSubtask(task, subtaskId);
    final updated = task.updateSubtask(
      completed ? current.complete() : current.reopen(),
    );
    await _repository.saveTask(updated);
    return updated;
  }

  /// Remoção individual definitiva; sai do progresso (spec 01, RF-07).
  Future<Task> removeSubtask(String taskId, String subtaskId) async {
    final task = await _require(taskId);
    final updated = task.removeSubtask(subtaskId);
    await _repository.saveTask(updated);
    return updated;
  }

  /// Reordena etapas preservando estados e títulos (spec 01, RF-06).
  Future<Task> reorderSubtasks(
    String taskId,
    List<String> orderedIds,
  ) async {
    final task = await _require(taskId);
    final updated = task.reorderSubtasks(orderedIds);
    await _repository.saveTask(updated);
    return updated;
  }

  Future<Task> _require(String id) async {
    final task = await _repository.fetchById(id);
    if (task == null) {
      throw const TaskException(TaskFailure.unknownTask);
    }
    return task;
  }

  Subtask _requireSubtask(Task task, String subtaskId) {
    return task.subtasks.firstWhere(
      (s) => s.id == subtaskId,
      orElse: () => throw const TaskException(TaskFailure.unknownSubtask),
    );
  }

  int _nextPosition(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    return tasks.map((t) => t.position).reduce((a, b) => a > b ? a : b) + 1;
  }
}
