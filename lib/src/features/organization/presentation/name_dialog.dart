import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Diálogo de criação/edição de nome com validação (spec 02, RF-01).
class NameDialog extends StatefulWidget {
  const NameDialog({
    super.key,
    required this.title,
    this.initial,
  });

  final String title;
  final String? initial;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? initial,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => NameDialog(title: title, initial: initial),
    );
  }

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = l10n.errorNameRequired);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('name-field'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.nameLabel,
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
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
