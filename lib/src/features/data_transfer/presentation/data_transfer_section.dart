import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../../../app/device_format.dart';
import '../../../data/providers.dart';
import '../application/data_transfer_service.dart';
import '../domain/data_snapshot.dart';

/// Seção de portabilidade dos dados na tela de organizar (spec 07).
class DataTransferSection extends ConsumerWidget {
  const DataTransferSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(dataTransferServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            l10n.dataSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(l10n.exportJson),
                onTap: () => _exportJson(context, service),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: Text(l10n.importJson),
                onTap: () => _importJson(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.createBackup),
                onTap: () => _createBackup(context, service),
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(l10n.restoreBackup),
                onTap: () => _restoreBackup(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportJson(
    BuildContext context,
    DataTransferService service,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.exportJsonTitle,
      message: l10n.exportJsonWarning,
      confirmLabel: l10n.exportJson,
    );
    if (confirmed != true || !context.mounted) return;

    final location = await getSaveLocation(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
      suggestedName: 'urutau-tasks-export.json',
    );
    if (location == null || !context.mounted) return;

    final json = await service.exportJson();
    await XFile.fromData(
      utf8.encode(json),
      mimeType: 'application/json',
      name: 'urutau-tasks-export.json',
    ).saveTo(location.path);
    if (context.mounted) _snack(context, l10n.exportDone);
  }

  Future<void> _createBackup(
    BuildContext context,
    DataTransferService service,
  ) async {
    final l10n = AppLocalizations.of(context);
    final password = await _askPassword(
      context,
      title: l10n.backupPasswordTitle,
      withConfirmation: true,
      warning: l10n.backupLostPasswordWarning,
    );
    if (password == null || !context.mounted) return;

    final location = await getSaveLocation(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Backup', extensions: ['utbk']),
      ],
      suggestedName: 'urutau-tasks-backup.utbk',
    );
    if (location == null || !context.mounted) return;

    final bytes = await service.createBackup(password);
    await XFile.fromData(
      bytes,
      mimeType: 'application/octet-stream',
      name: 'urutau-tasks-backup.utbk',
    ).saveTo(location.path);
    if (context.mounted) _snack(context, l10n.backupCreated);
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null || !context.mounted) return;

    final source = await file.readAsString();
    if (!context.mounted) return;
    await _confirmAndApply(
      context,
      ref,
      isBackup: false,
      source: source,
      password: null,
    );
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Backup', extensions: ['utbk']),
      ],
    );
    if (file == null || !context.mounted) return;

    final password = await _askPassword(
      context,
      title: l10n.backupPasswordTitle,
      withConfirmation: false,
      warning: null,
    );
    if (password == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    await _confirmAndApply(
      context,
      ref,
      isBackup: true,
      source: null,
      password: password,
      bytes: bytes,
    );
  }

  Future<void> _confirmAndApply(
    BuildContext context,
    WidgetRef ref, {
    required bool isBackup,
    required String? source,
    required String? password,
    Uint8List? bytes,
  }) async {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(dataTransferServiceProvider);

    ValidatedImport validated;
    try {
      validated = isBackup
          ? await service.validateBackup(bytes!, password!)
          : service.validateJson(source!);
    } on SnapshotException catch (error) {
      if (!context.mounted) return;
      _snack(context, _errorMessage(l10n, error));
      return;
    }

    if (!context.mounted) return;
    final confirmed = await _showSummary(context, validated.summary);
    if (confirmed != true || !context.mounted) return;

    await service.apply(validated);
    if (context.mounted) _snack(context, l10n.importDone);
  }

  String _errorMessage(AppLocalizations l10n, SnapshotException error) {
    return switch (error.error) {
      SnapshotError.invalidPassword => l10n.invalidPassword,
      SnapshotError.unsupportedVersion => l10n.unsupportedVersion,
      SnapshotError.corruptContainer ||
      SnapshotError.malformed ||
      SnapshotError.missingField ||
      SnapshotError.wrongType ||
      SnapshotError.duplicateId ||
      SnapshotError.danglingReference ||
      SnapshotError.unknownField => l10n.invalidFile,
    };
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// RF-14/CA-07: resumo com data e contagens antes de substituir.
  /// RF-15/CA-08: cancelar deixa os dados locais inalterados.
  Future<bool?> _showSummary(BuildContext context, ImportSummary summary) {
    final l10n = AppLocalizations.of(context);
    final exportedAt = DateTime.tryParse(summary.exportedAt);
    final dateText =
        exportedAt == null ? summary.exportedAt : formatDeviceDateTime(exportedAt);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.replaceTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.isBackup ? l10n.summaryTypeBackup : l10n.summaryTypeJson,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text('${l10n.summaryExportedAt}: $dateText'),
            const Divider(height: 16),
            _count(l10n.summaryActiveTasks, summary.activeTasks),
            _count(l10n.summaryCompletedTasks, summary.completedTasks),
            _count(l10n.summaryTrashedTasks, summary.trashedTasks),
            _count(l10n.summarySubtasks, summary.subtasks),
            _count(l10n.listsSection, summary.lists),
            _count(l10n.groupsSection, summary.groups),
            _count(l10n.categoriesSection, summary.categories),
            _count(l10n.tagsSection, summary.tags),
            _count(l10n.summarySeries, summary.series),
            _count(l10n.summaryMyDay, summary.myDayEntries),
            const Divider(height: 16),
            Text(
              l10n.replaceWarning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
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
  }

  Widget _count(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text('$label: $value'),
      );

  Future<String?> _askPassword(
    BuildContext context, {
    required String title,
    required bool withConfirmation,
    required String? warning,
  }) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (warning != null) ...[
                  Text(
                    warning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.backupPasswordLabel,
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (withConfirmation) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.backupPasswordConfirm,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isEmpty) {
                  setState(() => errorText = l10n.passwordRequired);
                  return;
                }
                if (withConfirmation &&
                    controller.text != confirmController.text) {
                  setState(() => errorText = l10n.passwordMismatch);
                  return;
                }
                Navigator.of(context).pop(controller.text);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
