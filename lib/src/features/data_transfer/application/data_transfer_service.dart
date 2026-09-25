import '../domain/backup_codec.dart';
import '../domain/data_snapshot.dart';
import '../data/drift_snapshot_repository.dart';

/// Resumo pré-restauração (spec 07, RF-14).
class BackupSummary {
  const BackupSummary({
    required this.isEncrypted,
    required this.exportedAt,
    required this.taskCount,
    required this.activeCount,
    required this.completedCount,
    required this.trashCount,
    required this.subtaskCount,
    required this.listCount,
    required this.groupCount,
    required this.categoryCount,
    required this.tagCount,
    required this.seriesCount,
    required this.myDayCount,
  });

  final bool isEncrypted;
  final DateTime exportedAt;
  final int taskCount;
  final int activeCount;
  final int completedCount;
  final int trashCount;
  final int subtaskCount;
  final int listCount;
  final int groupCount;
  final int categoryCount;
  final int tagCount;
  final int seriesCount;
  final int myDayCount;
}

/// Casos de uso de backup, exportação e restauração (spec 07).
///
/// Backup = arquivo único criptografado com senha; exportação/importação =
/// JSON aberto UTF-8 (ADR-0001). Restaurar/importar **substitui tudo** após
/// validação e confirmação — nunca mescla (RF-12/RF-15).
class DataTransferService {
  DataTransferService(this._repository, {BackupCodec? codec})
      : _codec = codec ?? BackupCodec();

  final DriftSnapshotRepository _repository;
  final BackupCodec _codec;

  /// Gera o arquivo de backup criptografado (spec 07, RF-05/RF-06).
  Future<String> createBackup({required String password}) async {
    final snapshot = await _repository.exportSnapshot();
    return _codec.encrypt(plaintext: snapshot.encode(), password: password);
  }

  /// Gera o JSON legível (spec 07, RF-09); dados pessoais ficam visíveis.
  Future<String> createReadableExport() async {
    final snapshot = await _repository.exportSnapshot();
    return snapshot.encode();
  }

  /// Valida e resume antes de substituir (spec 07, RF-13/RF-14).
  Future<BackupSummary> summarizeBackup({
    required String content,
    required String password,
  }) async {
    final clear = await _codec.decrypt(envelope: content, password: password);
    return _summarize(DataSnapshot.decode(clear), isEncrypted: true);
  }

  /// Valida e resume um JSON aberto (spec 07, RF-13/RF-14).
  Future<BackupSummary> summarizeJson({required String content}) async {
    return _summarize(DataSnapshot.decode(content), isEncrypted: false);
  }

  /// Restaura o backup substituindo integralmente os dados locais, com
  /// rollback em falha (spec 07, RF-12/RF-16/RF-17).
  Future<void> restoreBackup({
    required String content,
    required String password,
  }) async {
    final clear = await _codec.decrypt(envelope: content, password: password);
    final snapshot = DataSnapshot.decode(clear);
    await _repository.replaceAll(snapshot);
  }

  /// Importa o JSON aberto com substituição integral (spec 07, RF-12).
  Future<void> importJson({required String content}) async {
    final snapshot = DataSnapshot.decode(content);
    await _repository.replaceAll(snapshot);
  }

  BackupSummary _summarize(DataSnapshot snapshot, {required bool isEncrypted}) {
    var active = 0;
    var completed = 0;
    var trash = 0;
    for (final task in snapshot.tasks) {
      switch (task['status']) {
        case 'active':
          active++;
        case 'completed':
          completed++;
        case 'trash':
          trash++;
      }
    }
    return BackupSummary(
      isEncrypted: isEncrypted,
      exportedAt: snapshot.exportedAt,
      taskCount: snapshot.tasks.length,
      activeCount: active,
      completedCount: completed,
      trashCount: trash,
      subtaskCount: snapshot.subtasks.length,
      listCount: snapshot.lists.length,
      groupCount: snapshot.groups.length,
      categoryCount: snapshot.categories.length,
      tagCount: snapshot.tags.length,
      seriesCount: snapshot.recurringSeries.length,
      myDayCount: snapshot.myDayEntries.length,
    );
  }
}
