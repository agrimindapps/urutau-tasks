import '../../../core/ids.dart';
import '../../my_day/domain/my_day.dart';
import '../../my_day/domain/my_day_repository.dart';
import '../../recurrence/domain/recurrence.dart';
import '../../recurrence/domain/recurrence_repository.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Casos de uso do ciclo de tarefas e subtarefas (spec 01).
///
/// Regras de transição no domínio; orquestração e persistência aqui.
/// Concluir/excluir remove as entradas do My Day (spec 03, RF-05/RF-09).
/// Concluir ocorrência recorrente cria a próxima em uma transação
/// (spec 04, RF-11).
class TasksService {
  TasksService(
    this._repository,
    this._myDay,
    this._recurrence, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TaskRepository _repository;
  final MyDayRepository _myDay;
  final RecurrenceRepository _recurrence;
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
  /// Sai do My Day (spec 03, RF-09) e, se recorrente, gera a próxima
  /// ocorrência futura na mesma transação (spec 04, RF-11).
  Future<Task> completeTask(String id) async {
    final task = await _require(id);
    final updated = task.complete(at: _clock());
    await _myDay.removeForTask(id);

    Task? next;
    final seriesId = task.seriesId;
    if (seriesId != null) {
      final series = await _recurrence.fetchSeries(seriesId);
      if (series != null) {
        final existing = await _repository.fetchAll();
        next = buildNextOccurrence(
          completed: updated,
          series: series,
          today: localDateKey(_clock()),
          now: _clock(),
          id: newId(),
          position: _nextPosition(existing),
        );
      }
    }

    if (next != null) {
      // Concluir ocorrência + criar próxima é atômico (spec 06, RF-04).
      await _repository.saveTasks([updated, next]);
    } else {
      await _repository.saveTask(updated);
    }
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
  /// Sai de todas as visões, incluindo My Day (spec 03, RF-05).
  Future<Task> moveToTrash(String id) async {
    final task = await _require(id);
    final updated = task.moveToTrash(at: _clock());
    await _repository.saveTask(updated);
    await _myDay.removeForTask(id);
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

  /// Define a prioridade (escopo do MVP 3.3); nula remove.
  Future<Task> setPriority(String id, TaskPriority? priority) async {
    final task = await _require(id);
    final updated = task.setPriority(priority, at: _clock());
    await _repository.saveTask(updated);
    return updated;
  }

  /// Define o prazo como data ISO de calendário local (spec 06, RF-11).
  ///
  /// Em ocorrência recorrente, a série passa a valer da ocorrência atual
  /// em diante, sem reescrever o histórico (spec 04, RF-12).
  Future<Task> setDueDate(String id, String? dueDate) async {
    final task = await _require(id);
    final updated = task.setDueDate(dueDate, at: _clock());
    final seriesId = task.seriesId;
    if (seriesId != null) {
      final series = await _recurrence.fetchSeries(seriesId);
      if (series != null && dueDate != null) {
        await _recurrence.saveSeries(series.copyWith(baseDate: dueDate));
      }
    }
    await _repository.saveTask(updated);
    return updated;
  }

  /// Define o lembrete como instante UTC (spec 06, RF-12).
  ///
  /// Lembrete no passado é rejeitado (spec 04, RF-04); lembretes já
  /// vencidos preservados não são revalidados (RF-05).
  Future<Task> setReminder(String id, DateTime? reminder) async {
    final task = await _require(id);
    if (reminder != null && !reminder.isAfter(_clock())) {
      throw const RecurrenceException(RecurrenceFailure.reminderInPast);
    }
    final updated = task.setReminder(reminder, at: _clock());
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
