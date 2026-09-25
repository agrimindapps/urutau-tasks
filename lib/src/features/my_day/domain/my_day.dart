/// Domínio do My Day — foco diário (spec 03, RF-06 a RF-10).
library;

/// Falhas do My Day.
enum MyDayFailure {
  /// Tarefa concluída ou na lixeira não entra no My Day (spec 03, RF-06).
  taskNotEligible,

  /// Entrada não encontrada.
  unknownEntry,

  /// Tarefa já está no My Day do dia.
  alreadyAdded,
}

class MyDayException implements Exception {
  const MyDayException(this.failure);

  final MyDayFailure failure;

  @override
  String toString() => 'MyDayException(${failure.name})';
}

/// Data de calendário local no formato ISO `YYYY-MM-DD`
/// (spec 06, RF-13: sem conversão UTC que muda o dia).
String localDateKey(DateTime local) {
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Entrada do My Day: tarefa em uma data de foco, com ordem manual
/// (spec 03, RF-07; spec 06, RF-10).
class MyDayEntry {
  const MyDayEntry({
    required this.id,
    required this.taskId,
    required this.date,
    required this.position,
  });

  factory MyDayEntry.create({
    required String id,
    required String taskId,
    required String date,
    int position = 0,
  }) {
    return MyDayEntry(
      id: id,
      taskId: taskId,
      date: date,
      position: position,
    );
  }

  final String id;
  final String taskId;

  /// Data local do foco (`YYYY-MM-DD`).
  final String date;

  /// Ordem manual do dia (spec 03, RF-12); distinta da origem.
  final int position;

  MyDayEntry copyWith({int? position}) {
    return MyDayEntry(
      id: id,
      taskId: taskId,
      date: date,
      position: position ?? this.position,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MyDayEntry &&
      other.id == id &&
      other.taskId == taskId &&
      other.date == date &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, taskId, date, position);
}
