import '../../../core/ids.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/recurrence.dart';
import '../domain/recurrence_repository.dart';

/// Casos de uso de prazos, lembretes e recorrência (spec 04).
class RecurrenceService {
  RecurrenceService(
    this._repository,
    this._taskRepository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RecurrenceRepository _repository;
  final TaskRepository _taskRepository;
  final DateTime Function() _clock;

  Future<RecurringSeries?> fetchSeries(String id) => _repository.fetchSeries(id);

  /// Cria série para a tarefa; exige prazo como data-base (spec 04, RF-07).
  Future<RecurringSeries> createSeries(
    String taskId, {
    required RecurrenceFrequency frequency,
  }) async {
    final task = await _requireTask(taskId);
    final dueDate = task.dueDate;
    if (dueDate == null) {
      throw const RecurrenceException(RecurrenceFailure.dueDateRequired);
    }
    final series = RecurringSeries.create(
      id: newId(),
      frequency: frequency,
      baseDate: dueDate,
    );
    await _repository.saveSeries(series);
    await _taskRepository.saveTask(task.setSeries(series.id, at: _clock()));
    return series;
  }

  /// Cancela a série: impede novas ocorrências e preserva o histórico
  /// (spec 04, RF-10/CA-17).
  Future<void> cancelSeries(String seriesId) async {
    final series = await _requireSeries(seriesId);
    await _repository.saveSeries(series.cancel());
  }

  /// Troca a frequência a partir da ocorrência atual (spec 04, RF-12).
  Future<RecurringSeries> changeFrequency(
    String seriesId, {
    required RecurrenceFrequency frequency,
  }) async {
    final series = await _requireSeries(seriesId);
    if (series.cancelled) {
      throw const RecurrenceException(RecurrenceFailure.seriesCancelled);
    }
    final updated = series.copyWith(frequency: frequency);
    await _repository.saveSeries(updated);
    return updated;
  }

  /// Reprograma o prazo da ocorrência atual; a série passa a valer da
  /// ocorrência atual em diante, sem reescrever o histórico (spec 04, RF-12).
  Future<Task> rescheduleOccurrence(String taskId, {required String dueDate}) async {
    final task = await _requireTask(taskId);
    final updated = task.setDueDate(dueDate, at: _clock());
    if (task.seriesId != null) {
      final series = await _requireSeries(task.seriesId!);
      await _repository.saveSeries(series.copyWith(baseDate: dueDate));
    }
    await _taskRepository.saveTask(updated);
    return updated;
  }

  Future<Task> _requireTask(String id) async {
    final task = await _taskRepository.fetchById(id);
    if (task == null) {
      throw const TaskException(TaskFailure.unknownTask);
    }
    return task;
  }

  Future<RecurringSeries> _requireSeries(String id) async {
    final series = await _repository.fetchSeries(id);
    if (series == null) {
      throw const RecurrenceException(RecurrenceFailure.unknownSeries);
    }
    return series;
  }
}
