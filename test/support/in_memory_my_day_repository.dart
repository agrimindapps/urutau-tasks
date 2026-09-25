import 'dart:async';

import 'package:urutau_tasks/src/features/my_day/domain/my_day.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day_repository.dart';

/// Repositório do My Day em memória para testes (spec 06, RF-26).
class InMemoryMyDayRepository implements MyDayRepository {
  final _entries = <String, MyDayEntry>{};
  final _controller = StreamController<List<MyDayEntry>>.broadcast();

  List<MyDayEntry> _snapshot() {
    final entries = _entries.values.toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.position.compareTo(b.position);
      });
    return entries;
  }

  void _notify() => _controller.add(_snapshot());

  @override
  Future<List<MyDayEntry>> fetchAll() async => _snapshot();

  @override
  Stream<List<MyDayEntry>> watchAll() async* {
    yield _snapshot();
    yield* _controller.stream;
  }

  @override
  Future<void> saveEntry(MyDayEntry entry) async {
    _entries[entry.id] = entry;
    _notify();
  }

  @override
  Future<void> removeEntry(String entryId) async {
    _entries.remove(entryId);
    _notify();
  }

  @override
  Future<void> removeForTask(String taskId) async {
    _entries.removeWhere((_, e) => e.taskId == taskId);
    _notify();
  }

  @override
  Future<void> removeBefore(String today) async {
    _entries.removeWhere((_, e) => e.date.compareTo(today) < 0);
    _notify();
  }

  Iterable<MyDayEntry> get allEntries => _entries.values;
}
