// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Urutau Tasks';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navTrash => 'Trash';

  @override
  String get newTaskTooltip => 'New task';

  @override
  String get editTaskTitle => 'Edit task';

  @override
  String get createTaskTitle => 'New task';

  @override
  String get taskTitleLabel => 'Title';

  @override
  String get taskNotesLabel => 'Notes';

  @override
  String get taskTitleHint => 'What needs to be done?';

  @override
  String get taskNotesHint => 'Details (optional)';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get complete => 'Complete';

  @override
  String get reopen => 'Reopen';

  @override
  String get restore => 'Restore';

  @override
  String get deleteTaskTitle => 'Delete task?';

  @override
  String get deleteTaskMessage =>
      'The task and its steps will go to the trash. You can restore them later.';

  @override
  String get emptyTasks => 'No tasks yet. Create the first one!';

  @override
  String get emptyTrash => 'The trash is empty.';

  @override
  String get trashSubtitle => 'Deleted tasks stay here until restored.';

  @override
  String get errorTitleRequired => 'The title cannot be empty.';

  @override
  String get errorEditInTrash => 'Restore the task to edit it.';

  @override
  String get subtasksSection => 'Steps';

  @override
  String get addSubtaskTooltip => 'Add step';

  @override
  String get subtaskHint => 'Step title';

  @override
  String get removeSubtaskTooltip => 'Remove step';

  @override
  String get emptySubtasks => 'No steps added.';

  @override
  String progressOf(int completed, int total) {
    return '$completed of $total';
  }

  @override
  String get taskDetailTitle => 'Task details';

  @override
  String get errorUnexpected => 'The action could not be completed.';
}
