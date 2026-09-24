// Entradas do My Day (spec 03, RF-06 a RF-12).
/// Uma entrada do foco diário (spec 06, RF-10): associa uma tarefa a uma
/// data local sem copiar nem alterar a tarefa de origem.
class MyDayEntry {
  const MyDayEntry({
    required this.id,
    required this.taskId,
    required this.date,
    this.position = 0,
  });

  final String id;

  /// UUID da tarefa principal.
  final String taskId;

  /// Data local do foco, `yyyy-MM-dd` (spec 06, RF-13).
  final String date;

  final int position;

  MyDayEntry copyWith({int? position}) => MyDayEntry(
        id: id,
        taskId: taskId,
        date: date,
        position: position ?? this.position,
      );

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

/// Adicionar ao My Day exige tarefa principal ativa (spec 03, RF-06).
class InactiveTaskMyDayException implements Exception {
  const InactiveTaskMyDayException();

  @override
  String toString() => 'Only active tasks can be added to My Day.';
}
