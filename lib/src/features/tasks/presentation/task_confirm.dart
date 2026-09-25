import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Diálogo de confirmação da exclusão lógica (spec 01, RF-09).
Future<bool> confirmDeleteTask(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteTaskTitle),
      content: Text(l10n.deleteTaskMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
