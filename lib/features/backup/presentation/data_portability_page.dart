import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/backup_providers.dart';
import '../data/data_portability_service.dart';
import '../../notifications/application/notification_providers.dart';

class DataPortabilityPage extends ConsumerStatefulWidget {
  const DataPortabilityPage({super.key});

  @override
  ConsumerState<DataPortabilityPage> createState() =>
      _DataPortabilityPageState();
}

class _DataPortabilityPageState extends ConsumerState<DataPortabilityPage> {
  bool _busy = false;
  String? _busyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupAndPortability)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_busy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(_busyMessage ?? l10n.backupAndPortability),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.backupAndPortabilityDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(l10n.createBackup),
                      subtitle: Text(l10n.encryptedBackupDescription),
                      onTap: _busy ? null : _createBackup,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.data_object),
                      title: Text(l10n.exportOpenJson),
                      subtitle: Text(l10n.unencryptedJsonDescription),
                      onTap: _busy ? null : _exportOpenJson,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_page_outlined),
                      title: Text(l10n.importOrRestore),
                      subtitle: Text(l10n.importReplaceWarning),
                      onTap: _busy ? null : _importOrRestore,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context);
    final password = await _askForPassword(
      title: l10n.createBackup,
      message: l10n.encryptedBackupWarning,
      confirm: true,
    );
    if (password == null || !mounted) return;
    await _run(
      () async {
        final bytes = await ref
            .read(dataPortabilityServiceProvider)
            .exportEncryptedBackup(password);
        return _saveFile(
          bytes,
          'urutau-tasks-backup-${_today()}.utbackup',
          mimeType: 'application/octet-stream',
        );
      },
      successMessage: l10n.backupExportDone,
      progressMessage: l10n.preparingEncryptedBackup,
    );
  }

  Future<void> _exportOpenJson() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: l10n.exportOpenJson,
      message: l10n.unencryptedExportWarning,
      confirmLabel: l10n.exportOpenJson,
    );
    if (!confirmed || !mounted) return;
    await _run(
      () async {
        final bytes = await ref
            .read(dataPortabilityServiceProvider)
            .exportOpenJson();
        return _saveFile(
          bytes,
          'urutau-tasks-export-${_today()}.json',
          mimeType: 'application/json',
        );
      },
      successMessage: l10n.jsonExportDone,
      progressMessage: l10n.preparingJsonExport,
    );
  }

  Future<void> _importOrRestore() async {
    final l10n = AppLocalizations.of(context);
    await _run(
      () async {
        final files = await FilePicker.pickFiles(
          dialogTitle: l10n.importOrRestore,
          type: FileType.custom,
          allowedExtensions: const ['json', 'utbackup'],
        );
        if (files.isEmpty || !mounted) return false;
        final bytes = await files.single.readAsBytes();
        final service = ref.read(dataPortabilityServiceProvider);
        PreparedImport prepared;
        try {
          prepared = await service.prepareImport(bytes);
        } on BackupPasswordRequiredException {
          final password = await _askForPassword(
            title: l10n.restoreBackup,
            message: l10n.backupPasswordRequired,
            confirm: false,
          );
          if (password == null || !mounted) return false;
          prepared = await service.prepareImport(bytes, password: password);
        }
        if (!mounted) return false;
        final confirmed = await _confirmImport(prepared);
        if (!confirmed || !mounted) return false;
        await service.replaceAllData(prepared);
        await ref.read(localNotificationServiceProvider).reconcileNow();
        return true;
      },
      successMessage: l10n.dataImportDone,
      progressMessage: l10n.preparingDataRestore,
    );
  }

  Future<bool> _saveFile(
    Uint8List bytes,
    String fileName, {
    required String mimeType,
  }) async {
    final l10n = AppLocalizations.of(context);
    final savedAt = await FilePicker.saveFile(
      dialogTitle: l10n.chooseExportDestination,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      type: FileType.custom,
      allowedExtensions: [fileName.split('.').last],
    );
    return savedAt != null && mounted;
  }

  Future<String?> _askForPassword({
    required String title,
    required String message,
    required bool confirm,
  }) => showDialog<String>(
    context: context,
    builder: (context) =>
        _PasswordDialog(title: title, message: message, confirm: confirm),
  );

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
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
          );
        },
      ) ??
      false;

  Future<bool> _confirmImport(PreparedImport prepared) async {
    final l10n = AppLocalizations.of(context);
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale
        .toString();
    final exportDate = DateFormat.yMMMd(deviceLocale)
        .add_jm()
        .format(prepared.exportedAtUtc.toLocal());
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.importPreview),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prepared.fileType == PortabilityFileType.encryptedBackup
                          ? l10n.encryptedBackupFile
                          : l10n.openJsonFile,
                    ),
                    const SizedBox(height: 8),
                    Text('${l10n.exportDate}: $exportDate'),
                    const SizedBox(height: 12),
                    _countLine(l10n.activeTasks, prepared.activeTaskCount),
                    _countLine(
                      l10n.completedTasks,
                      prepared.completedTaskCount,
                    ),
                    _countLine(l10n.trash, prepared.trashedTaskCount),
                    _countLine(l10n.subtasks, prepared.subtaskCount),
                    _countLine(l10n.lists, prepared.listCount),
                    _countLine(l10n.groups, prepared.groupCount),
                    _countLine(l10n.categories, prepared.categoryCount),
                    _countLine(l10n.tags, prepared.tagCount),
                    _countLine(l10n.recurrence, prepared.recurrenceSeriesCount),
                    _countLine(l10n.myDay, prepared.myDayEntryCount),
                    const SizedBox(height: 16),
                    Text(
                      l10n.importReplaceWarning,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.replaceLocalData),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _countLine(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text('$label: $count'),
  );

  Future<void> _run(
    Future<bool> Function() action, {
    required String successMessage,
    required String progressMessage,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyMessage = progressMessage;
    });
    try {
      final completed = await action();
      if (completed && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
        });
      }
    }
  }

  void _showError(Object error) {
    final l10n = AppLocalizations.of(context);
    final message = switch (error) {
      BackupAuthenticationFailedException() => l10n.wrongPasswordOrCorrupt,
      InvalidBackupPasswordException() => l10n.emptyPassword,
      InvalidBackupFileException() => l10n.invalidImportFile,
      UnsupportedLogicalFormatVersionException() ||
      UnsupportedBackupContainerVersionException() => l10n.incompatibleFile,
      _ => l10n.actionFailed,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({
    required this.title,
    required this.message,
    required this.confirm,
  });

  final String title;
  final String message;
  final bool confirm;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password),
            ),
            if (widget.confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmationController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.confirmPassword),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            final password = _passwordController.text;
            if (password.isEmpty) {
              setState(() => _error = l10n.emptyPassword);
              return;
            }
            if (widget.confirm && password != _confirmationController.text) {
              setState(() => _error = l10n.passwordMismatch);
              return;
            }
            Navigator.of(context).pop(password);
          },
          child: Text(l10n.continueLabel),
        ),
      ],
    );
  }
}
