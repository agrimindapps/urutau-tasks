import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class _TitleDialog extends StatefulWidget {
  const _TitleDialog({
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    this.initialValue = '',
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;
  final String initialValue;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.fieldLabel,
          errorText: _showError ? l10n.taskTitleRequired : null,
        ),
        onChanged: (value) {
          if (_showError && value.trim().isNotEmpty) {
            setState(() => _showError = false);
          }
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(title);
  }
}

Future<String?> showTaskTitleDialog(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  required String submitLabel,
  String initialValue = '',
}) => showDialog<String>(
  context: context,
  builder: (context) => _TitleDialog(
    title: title,
    fieldLabel: fieldLabel,
    submitLabel: submitLabel,
    initialValue: initialValue,
  ),
);
