import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../tasks/presentation/task_errors.dart';
import '../application/data_transfer_service.dart';
import '../domain/backup_codec.dart';
import '../domain/data_snapshot.dart';
import 'password_dialog.dart';

/// Backup, exportação e restauração (spec 07; ADR-0001).
class DataTransferPage extends ConsumerWidget {
  const DataTransferPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(dataTransferServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l10n.backupWarning),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            key: const Key('export-backup'),
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.exportBackup),
            onTap: () => _exportBackup(context, service),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l10n.jsonWarning),
            ),
          ),
          ListTile(
            key: const Key('export-json'),
            leading: const Icon(Icons.data_object),
            title: Text(l10n.exportJson),
            onTap: () => _exportJson(context, service),
          ),
          const Divider(),
          ListTile(
            key: const Key('restore-backup'),
            leading: const Icon(Icons.restore),
            title: Text(l10n.restoreBackup),
            onTap: () => _restore(context, service, encrypted: true),
          ),
          ListTile(
            key: const Key('import-json'),
            leading: const Icon(Icons.upload_file),
            title: Text(l10n.importJson),
            onTap: () => _restore(context, service, encrypted: false),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(
    BuildContext context,
    DataTransferService service,
  ) async {
    final password = await PasswordDialog.show(context, confirm: true);
    if (password == null || !context.mounted) return;
    await runTaskAction(context, () async {
      final content = await service.createBackup(password: password);
      final saved = await _saveFile(
        content: content,
        name: 'urutau-backup.json',
      );
      if (saved && context.mounted) {
        _showSnack(context, AppLocalizations.of(context)!.fileSaved);
      }
    });
  }

  Future<void> _exportJson(
    BuildContext context,
    DataTransferService service,
  ) async {
    await runTaskAction(context, () async {
      final content = await service.createReadableExport();
      final saved = await _saveFile(
        content: content,
        name: 'urutau-export.json',
      );
      if (saved && context.mounted) {
        _showSnack(context, AppLocalizations.of(context)!.fileSaved);
      }
    });
  }

  Future<void> _restore(
    BuildContext context,
    DataTransferService service, {
    required bool encrypted,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !context.mounted) return;
    final content = await file.readAsString();
    if (!context.mounted) return;

    String? password;
    if (encrypted) {
      password = await PasswordDialog.show(context);
      if (password == null || !context.mounted) return;
    }

    try {
      final summary = encrypted
          ? await service.summarizeBackup(content: content, password: password!)
          : await service.summarizeJson(content: content);
      if (!context.mounted) return;

      final confirmed = await _confirmReplace(context, summary);
      if (!confirmed || !context.mounted) return;

      if (encrypted) {
        await service.restoreBackup(content: content, password: password!);
      } else {
        await service.importJson(content: content);
      }
      if (context.mounted) {
        _showSnack(context, l10n.fileSaved);
      }
    } on BackupException catch (error) {
      if (!context.mounted) return;
      _showSnack(
        context,
        error.failure == BackupFailure.authenticationFailed
            ? l10n.errorWrongPassword
            : l10n.errorInvalidFile,
      );
    } on SnapshotException {
      if (!context.mounted) return;
      _showSnack(context, l10n.errorInvalidFile);
    }
  }

  Future<bool> _confirmReplace(
    BuildContext context,
    BackupSummary summary,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.summaryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.isEncrypted ? l10n.typeBackup : l10n.typeJson),
            Text(
              '${l10n.summaryExportedAt}: '
              '${summary.exportedAt.toLocal().toIso8601String()}',
            ),
            Text('${l10n.summaryTasks}: ${summary.taskCount} '
                '(${l10n.summaryActive} ${summary.activeCount}, '
                '${l10n.summaryCompleted} ${summary.completedCount}, '
                '${l10n.summaryTrash} ${summary.trashCount})'),
            Text('${l10n.summarySubtasks}: ${summary.subtaskCount}'),
            Text('${l10n.summaryLists}: ${summary.listCount}'),
            Text('${l10n.summaryGroups}: ${summary.groupCount}'),
            Text('${l10n.summaryCategories}: ${summary.categoryCount}'),
            Text('${l10n.summaryTags}: ${summary.tagCount}'),
            Text('${l10n.summarySeries}: ${summary.seriesCount}'),
            Text('${l10n.summaryMyDay}: ${summary.myDayCount}'),
            const SizedBox(height: 12),
            Text(l10n.replaceWarning),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirmReplace),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _saveFile({
    required String content,
    required String name,
  }) async {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) return false;
    final bytes = utf8.encode(content);
    await XFile.fromData(
      bytes,
      name: name,
      mimeType: 'application/json',
    ).saveTo(location.path);
    return true;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
