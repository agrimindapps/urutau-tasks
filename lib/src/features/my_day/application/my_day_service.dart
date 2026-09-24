import 'package:urutau_tasks/src/core/ids.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task_repository.dart';

/// Casos de uso do My Day (spec 03, RF-06 a RF-12).
class MyDayService {
  MyDayService(
    this._myDay,
    this._tasks, {
    DateTime Function()? now,
    String Function()? generateId,
  })  : _now = now ?? DateTime.now,
        _generateId = generateId ?? newId;

  final MyDayRepository _myDay;
  final TaskRepository _tasks;
  final DateTime Function() _now;
  final String Function() _generateId;

  /// Data local do foco corrente (spec 06, RF-13).
  String get today {
    final local = _now().toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Stream<List<MyDayEntry>> watchToday() => _myDay.watchEntries(today);

  /// RF-06/CA-09: associa a tarefa ativa ao foco do dia sem alterar nenhum
  /// dado de origem (CA-10).
  Future<void> addToMyDay(String taskId) async {
    final task = await _tasks.getTask(taskId);
    if (task == null) throw StateError('Task not found: $taskId');
    if (!task.isActive) throw const InactiveTaskMyDayException();

    final entries = await _myDay.getEntries(today);
    if (entries.any((e) => e.taskId == taskId)) return;

    final position = entries.isEmpty
        ? 0
        : entries.map((e) => e.position).reduce((a, b) => a > b ? a : b) + 1;
    await _myDay.insertEntry(MyDayEntry(
      id: _generateId(),
      taskId: taskId,
      date: today,
      position: position,
    ));
  }

  /// RF-08/CA-12: remove só a associação; a tarefa permanece na origem.
  Future<void> removeFromMyDay(String taskId) =>
      _myDay.removeEntriesForTask(taskId);

  /// RF-07/CA-11: ordem manual do dia, persistida por posição.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final entries = await _myDay.getEntries(today);
    if (oldIndex < 0 || oldIndex >= entries.length) {
      throw RangeError.index(oldIndex, entries, 'oldIndex');
    }
    final items = List<MyDayEntry>.from(entries);
    final item = items.removeAt(oldIndex);
    var insertAt = newIndex;
    if (insertAt < 0) insertAt = 0;
    if (insertAt > items.length) insertAt = items.length;
    items.insert(insertAt, item);
    await _myDay.updatePositions([
      for (var i = 0; i < items.length; i++)
        items[i].copyWith(position: i),
    ]);
  }

  /// RF-10/CA-14/CA-15: descarta entradas que não são de hoje. Idempotente —
  /// não altera tarefas, listas nem demais dados (a entrada é a única coisa
  /// removida, então a tarefa "retorna à origem" por construção).
  Future<void> rollover() => _myDay.purgeEntriesExcept(today);
}
