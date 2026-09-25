import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../../../data/providers.dart';

/// Fluxo único de permissão do primeiro lembrete (spec 08, seção 6 /
/// CA-01/CA-02): explica, solicita autorização apenas em resposta à
/// ação do usuário e nunca repete o pedido automaticamente após a
/// primeira execução.
Future<void> runFirstReminderPermissionFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final store = ref.read(reminderPermissionStoreProvider);
  if (await store.isExplained()) return;
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _PermissionDialog(onConfirm: () => Navigator.of(context).pop(true)),
  );
  if (confirmed != true || !context.mounted) return;

  // Ação explícita do usuário (spec 08, seção 6).
  await ref.read(notificationAdapterProvider).requestPermission();
  await store.markExplained();
}

class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reminderPermissionTitle),
      content: Text(l10n.reminderPermissionMessage),
      actions: [
        FilledButton(
          onPressed: onConfirm,
          child: Text(l10n.reminderPermissionConfirm),
        ),
      ],
    );
  }
}
