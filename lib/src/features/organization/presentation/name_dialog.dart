import 'package:flutter/material.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';

/// Diálogo reutilizável de nome para criar/renomear entidades (spec 02).
/// Retorna o nome normalizado ou `null` quando cancelado.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(title: title, initial: initial),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    try {
      final name = normalizeName(_controller.text);
      Navigator.of(context).pop(name);
    } on InvalidNameException {
      setState(() => _errorText = l10n.nameRequired);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.nameField,
            errorText: _errorText,
          ),
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

/// Exibe a mensagem de domínio traduzida como snackbar.
void showDomainError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  final message = switch (error) {
    DuplicateNameException() => l10n.nameDuplicate,
    InvalidNameException() => l10n.nameRequired,
    ListNotEmptyException() => l10n.listNotEmpty,
    NoDestinationAvailableException() => l10n.noDestination,
    _ => error.toString(),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
