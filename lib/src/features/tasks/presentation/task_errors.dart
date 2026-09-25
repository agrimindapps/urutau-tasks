import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../domain/task.dart';

/// Executa uma ação de serviço traduzindo falhas de domínio em avisos.
Future<void> runTaskAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    await action();
  } on TaskException catch (error) {
    if (!context.mounted) return;
    final message = switch (error.failure) {
      TaskFailure.emptyTitle => l10n.errorTitleRequired,
      TaskFailure.editInTrash => l10n.errorEditInTrash,
      TaskFailure.invalidTransition ||
      TaskFailure.unknownSubtask ||
      TaskFailure.unknownTask ||
      TaskFailure.nestedSubtask =>
        l10n.errorUnexpected,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
