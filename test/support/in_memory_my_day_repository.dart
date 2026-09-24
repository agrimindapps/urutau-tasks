import 'dart:async';

import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day_repository.dart';

/// My Day em memória para testes (spec 06, RF-26), com a unicidade
/// tarefa+data do esquema.
class InMemoryMyDayRepository implements MyDayRepository {
  final _entries = <String, MyDayEntry>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  void _notify() => _changes.add(null);

  List<MyDayEntry> _of(String date) {
    final entries = _entries.values.where((e) => e.date == date).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return entries;
  }

  @override
  Stream<List<MyDayEntry>> watchEntries(String date) async* {
    yield _of(date);
    yield* _changes.stream.map((_) => _of(date));
  }

  @override
  Future<List<MyDayEntry>> getEntries(String date) async => _of(date);

  @override
  Future<void> insertEntry(MyDayEntry entry) async {
    final duplicate = _entries.values.any(
      (e) => e.taskId == entry.taskId && e.date == entry.date,
    );
    if (duplicate) {
      throw StateError('My Day entry already exists for this task and date.');
    }
    _entries[entry.id] = entry;
    _notify();
  }

  @override
  Future<void> removeEntriesForTask(String taskId) async {
    _entries.removeWhere((_, entry) => entry.taskId == taskId);
    _notify();
  }

  @override
  Future<void> updatePositions(List<MyDayEntry> entries) async {
    for (final entry in entries) {
      _entries[entry.id] = entry;
    }
    _notify();
  }

  @override
  Future<void> purgeEntriesExcept(String date) async {
    _entries.removeWhere((_, entry) => entry.date != date);
    _notify();
  }
}
