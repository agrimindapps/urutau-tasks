import 'dart:typed_data';

import 'package:urutau_tasks/src/features/data_transfer/domain/backup_codec.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/data_snapshot.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/snapshot_codec.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/snapshot_repository.dart';

/// Casos de uso de exportação, importação, backup e restauração
/// (spec 07, RF-05 a RF-16).
class DataTransferService {
  DataTransferService(this._repository);

  final SnapshotRepository _repository;

  /// RF-09/RF-10/CA-05: JSON UTF-8 versão 1, legível, sem criptografia.
  Future<String> exportJson() async {
    final snapshot = await _repository.loadSnapshot();
    return encodeSnapshot(snapshot);
  }

  /// RF-05/RF-06/CA-04: um único arquivo criptografado por senha.
  Future<Uint8List> createBackup(String password) async {
    _ensurePassword(password);
    final snapshot = await _repository.loadSnapshot();
    final document = encodeSnapshot(snapshot);
    return encryptBackup(documentJson: document, password: password);
  }

  /// RF-14: lê e valida sem alterar nada localmente.
  ValidatedImport validateJson(String source) {
    final snapshot = decodeSnapshot(source);
    return ValidatedImport(
      snapshot: snapshot,
      summary: summarize(snapshot, isBackup: false),
    );
  }

  /// RF-06/RF-14/RF-17: descriptografa e valida; senha errada ou arquivo
  /// corrompido são rejeitados sem tocar nos dados locais (CA-11).
  Future<ValidatedImport> validateBackup(
    Uint8List bytes,
    String password,
  ) async {
    _ensurePassword(password);
    final document =
        await decryptBackup(bytes: bytes, password: password);
    final snapshot = decodeSnapshot(document);
    return ValidatedImport(
      snapshot: snapshot,
      summary: summarize(snapshot, isBackup: true),
    );
  }

  /// RF-12/RF-16/CA-09: substituição integral em transação atômica.
  Future<void> apply(ValidatedImport validated) =>
      _repository.replaceAll(validated.snapshot);

  /// RF-12: importar JSON direto (validar + aplicar) — usado em testes e
  /// fluxos sem resumo; a UI usa validar → confirmar → [apply].
  Future<void> importJson(String source) async =>
      apply(validateJson(source));

  Future<void> restoreBackup(Uint8List bytes, String password) async =>
      apply(await validateBackup(bytes, password));

  void _ensurePassword(String password) {
    if (password.isEmpty) {
      throw const FormatException('empty password');
    }
  }
}
