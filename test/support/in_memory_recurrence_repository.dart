import 'dart:async';

import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence_repository.dart';

/// Séries em memória para testes (spec 06, RF-26).
class InMemoryRecurrenceRepository implements RecurrenceRepository {
  final _series = <String, RecurrenceSeries>{};

  @override
  Future<RecurrenceSeries?> getSeries(String id) async => _series[id];

  @override
  Future<void> insertSeries(RecurrenceSeries series) async {
    if (_series.containsKey(series.id)) {
      throw StateError('Duplicate series id: ${series.id}');
    }
    _series[series.id] = series;
  }

  @override
  Future<void> saveSeries(RecurrenceSeries series) async {
    if (!_series.containsKey(series.id)) {
      throw StateError('Unknown series id: ${series.id}');
    }
    _series[series.id] = series;
  }

  @override
  Stream<List<RecurrenceSeries>> watchAll() async* {
    yield _series.values.toList();
  }
}
