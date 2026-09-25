import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../organization/domain/organization.dart';
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
      TaskFailure.duplicateTag ||
      TaskFailure.invalidTransition ||
      TaskFailure.unknownSubtask ||
      TaskFailure.unknownTask ||
      TaskFailure.nestedSubtask =>
        l10n.errorUnexpected,
    };
    _showError(context, message);
  } on OrganizationException catch (error) {
    if (!context.mounted) return;
    final message = switch (error.failure) {
      OrganizationFailure.emptyName => l10n.errorNameRequired,
      OrganizationFailure.duplicateName => l10n.errorDuplicateName,
      OrganizationFailure.listNotEmpty => l10n.errorListNotEmpty,
      OrganizationFailure.sameDestination => l10n.errorSameDestination,
      OrganizationFailure.unknownList ||
      OrganizationFailure.unknownGroup ||
      OrganizationFailure.unknownCategory ||
      OrganizationFailure.unknownTag =>
        l10n.errorUnexpected,
    };
    _showError(context, message);
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
