import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';

/// Porta de persistência do My Day (spec 03; spec 06, RF-10/RF-21).
abstract interface class MyDayRepository {
  /// Entradas de uma data local, ordenadas por posição manual.
  Stream<List<MyDayEntry>> watchEntries(String date);

  Future<List<MyDayEntry>> getEntries(String date);

  Future<void> insertEntry(MyDayEntry entry);

  /// RF-08/RF-09: remove associações da tarefa sem tocar na tarefa.
  Future<void> removeEntriesForTask(String taskId);

  Future<void> updatePositions(List<MyDayEntry> entries);

  /// RF-10: descarta entradas de outras datas (idempotente).
  Future<void> purgeEntriesExcept(String date);
}
