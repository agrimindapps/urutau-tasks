import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence_repository.dart';

/// Repositório de séries em memória para testes (spec 06, RF-26).
class InMemoryRecurrenceRepository implements RecurrenceRepository {
  final _series = <String, RecurringSeries>{};

  @override
  Future<RecurringSeries?> fetchSeries(String id) async => _series[id];

  @override
  Future<List<RecurringSeries>> fetchAll() async => _series.values.toList();

  @override
  Future<void> saveSeries(RecurringSeries series) async {
    _series[series.id] = series;
  }

  Iterable<RecurringSeries> get allSeries => _series.values;
}
