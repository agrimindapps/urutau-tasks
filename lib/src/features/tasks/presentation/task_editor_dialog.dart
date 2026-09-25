import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Resultado do formulário de criação/edição de tarefa.
class TaskDraft {
  const TaskDraft({required this.title, required this.notes});

  final String title;
  final String notes;
}

/// Formulário de título + notas com validação de título (spec 01, RF-01).
class TaskEditorDialog extends StatefulWidget {
  const TaskEditorDialog({
    super.key,
    this.initialTitle,
    this.initialNotes,
    this.isEditing = false,
  });

  final String? initialTitle;
  final String? initialNotes;
  final bool isEditing;

  static Future<TaskDraft?> show(
    BuildContext context, {
    String? initialTitle,
    String? initialNotes,
    bool isEditing = false,
  }) {
    return showDialog<TaskDraft>(
      context: context,
      builder: (context) => TaskEditorDialog(
        initialTitle: initialTitle,
        initialNotes: initialNotes,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = l10n.errorTitleRequired);
      return;
    }
    Navigator.of(context).pop(
      TaskDraft(title: title, notes: _notesController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.isEditing ? l10n.editTaskTitle : l10n.createTaskTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('task-title-field'),
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.taskTitleLabel,
              hintText: l10n.taskTitleHint,
              errorText: _errorText,
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('task-notes-field'),
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.taskNotesLabel,
              hintText: l10n.taskNotesHint,
            ),
            minLines: 1,
            maxLines: 4,
          ),
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
