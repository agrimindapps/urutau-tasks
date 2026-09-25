import 'package:drift/drift.dart';

/// Séries recorrentes (esquema v4; spec 04, RF-09/RF-10).
@DataClassName('SeriesRow')
class Series extends Table {
  TextColumn get id => text()();

  /// `daily` | `weekdays` | `weekly` | `monthly` | `annual` (spec 04, RF-08).
  TextColumn get frequency => text()();

  /// Data-base da série `YYYY-MM-DD` no calendário original (RF-09).
  TextColumn get baseDate => text()();

  /// Cancelamento manual preserva o histórico (RF-10).
  BoolColumn get cancelled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
