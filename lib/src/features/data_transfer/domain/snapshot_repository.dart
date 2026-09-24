import 'data_snapshot.dart';

/// Porta de leitura e substituição integral do conjunto de dados
/// (spec 07, RF-01/RF-16; spec 06, RF-21).
abstract interface class SnapshotRepository {
  Future<DataSnapshot> loadSnapshot();

  /// Substitui todos os dados locais em uma única transação atômica
  /// (spec 07, RF-16 / CA-09/CA-10).
  Future<void> replaceAll(DataSnapshot snapshot);
}
