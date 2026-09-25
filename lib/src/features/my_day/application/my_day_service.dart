import '../../../core/ids.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_repository.dart';
import '../domain/my_day.dart';
import '../domain/my_day_repository.dart';

/// Casos de uso do My Day (spec 03, RF-06 a RF-10).
class MyDayService {
  MyDayService(
    this._repository,
    this._taskRepository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final MyDayRepository _repository;
  final TaskRepository _taskRepository;
  final DateTime Function() _clock;

  Future<List<MyDayEntry>> fetchEntries() => _repository.fetchAll();

  Stream<List<MyDayEntry>> watchEntries() => _repository.watchAll();

  /// Data local de foco de hoje (spec 06, RF-13).
  String get todayKey => localDateKey(_clock());

  /// Adiciona tarefa ativa ao My Day de hoje (spec 03, RF-06).
  ///
  /// Concluídas/lixeira não entram; duplicar no mesmo dia é bloqueado
  /// (spec 06, RF-19).
  Future<MyDayEntry> addToday(String taskId) async {
    final task = await _requireTask(taskId);
    if (task.status != TaskStatus.active) {
      throw const MyDayException(MyDayFailure.taskNotEligible);
    }
    final date = todayKey;
    final entries = await _repository.fetchAll();
    final existing =
        entries.where((e) => e.taskId == taskId && e.date == date).toList();
    if (existing.isNotEmpty) {
      throw const MyDayException(MyDayFailure.alreadyAdded);
    }
    final position = entries.where((e) => e.date == date).isEmpty
        ? 0
        : entries
                .where((e) => e.date == date)
                .map((e) => e.position)
                .reduce((a, b) => a > b ? a : b) +
            1;
    final entry = MyDayEntry.create(
      id: newId(),
      taskId: taskId,
      date: date,
      position: position,
    );
    await _repository.saveEntry(entry);
    return entry;
  }

  /// Remove a tarefa do foco sem alterar a tarefa (spec 03, RF-08).
  Future<void> removeToday(String taskId) async {
    final date = todayKey;
    final entries = await _repository.fetchAll();
    for (final entry in entries.where(
      (e) => e.taskId == taskId && e.date == date,
    )) {
      await _repository.removeEntry(entry.id);
    }
  }

  /// Reordena o My Day de hoje preservando a ordem manual (spec 03, RF-12).
  Future<void> reorderToday(List<String> orderedTaskIds) async {
    final date = todayKey;
    final entries = await _repository.fetchAll();
    final byTask = {
      for (final e in entries.where((e) => e.date == date)) e.taskId: e,
    };
    if (orderedTaskIds.length != byTask.length ||
        !orderedTaskIds.toSet().containsAll(byTask.keys)) {
      throw const MyDayException(MyDayFailure.unknownEntry);
    }
    for (var i = 0; i < orderedTaskIds.length; i++) {
      await _repository.saveEntry(
        byTask[orderedTaskIds[i]]!.copyWith(position: i),
      );
    }
  }

  /// Rollover diário (spec 03, RF-10): à meia-noite local as não concluídas
  /// saem do My Day; nada mais é alterado; idempotente.
  Future<void> rollover() => _repository.removeBefore(todayKey);

  Future<Task> _requireTask(String id) async {
    final task = await _taskRepository.fetchById(id);
    if (task == null) {
      throw const TaskException(TaskFailure.unknownTask);
    }
    return task;
  }
}
