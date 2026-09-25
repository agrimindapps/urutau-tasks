import 'my_day.dart';

/// Porta de persistência do My Day (spec 06, RF-10/RF-21).
abstract class MyDayRepository {
  /// Entradas do My Day (todas as datas, ordenadas por data/posição).
  Future<List<MyDayEntry>> fetchAll();

  /// Observa as entradas reativamente.
  Stream<List<MyDayEntry>> watchAll();

  Future<void> saveEntry(MyDayEntry entry);

  /// Remove uma entrada individual (spec 03, RF-08).
  Future<void> removeEntry(String entryId);

  /// Remove todas as entradas de uma tarefa (conclusão/lixo — spec 03, RF-09;
  /// spec 06, RF-10).
  Future<void> removeForTask(String taskId);

  /// Rollover: remove entradas pendentes anteriores à [today] em uma
  /// transação, de forma idempotente (spec 03, RF-10).
  Future<void> removeBefore(String today);
}
