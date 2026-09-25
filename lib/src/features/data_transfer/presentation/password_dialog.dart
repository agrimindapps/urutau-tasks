import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Diálogo de senha para backup/restauração (spec 07, RF-06).
class PasswordDialog extends StatefulWidget {
  const PasswordDialog({super.key, this.confirm = false});

  /// Quando verdadeiro, exige a confirmação da senha na criação.
  final bool confirm;

  static Future<String?> show(BuildContext context, {bool confirm = false}) {
    return showDialog<String>(
      context: context,
      builder: (context) => PasswordDialog(confirm: confirm),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final value = _password.text;
    if (value.isEmpty) {
      setState(() => _errorText = l10n.passwordRequired);
      return;
    }
    if (widget.confirm && value != _confirmation.text) {
      setState(() => _errorText = l10n.passwordMismatch);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.passwordLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('password-field'),
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('confirm-password-field'),
              controller: _confirmation,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: l10n.confirmPasswordLabel),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_errorText!),
            ),
          const SizedBox(height: 8),
          Text(l10n.backupWarning),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
