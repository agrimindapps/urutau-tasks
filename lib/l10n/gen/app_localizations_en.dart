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
  String get tasksTab => 'Tasks';

  @override
  String get trashTab => 'Trash';

  @override
  String get addTask => 'Add task';

  @override
  String get taskTitleLabel => 'Title';

  @override
  String get taskTitleHint => 'What needs to be done?';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint => 'Add a note';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get titleRequired => 'Enter a title.';

  @override
  String get markComplete => 'Complete';

  @override
  String get markIncomplete => 'Reopen';

  @override
  String get emptyTasks => 'No tasks here yet. Create the first one!';

  @override
  String get emptyTrash => 'The trash is empty.';

  @override
  String get subtasksSection => 'Subtasks';

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get subtaskTitleHint => 'New step';

  @override
  String get progressLabel => 'Progress';

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String get restore => 'Restore';

  @override
  String get trashBanner => 'This task is in the trash.';

  @override
  String get completedSection => 'Completed';

  @override
  String get activeSection => 'Active';

  @override
  String get taskDetail => 'Task details';

  @override
  String get openTaskDetail => 'Open task details';

  @override
  String get listsTab => 'Lists';

  @override
  String get listsSection => 'Lists';

  @override
  String get groupsSection => 'Groups';

  @override
  String get categoriesSection => 'Categories';

  @override
  String get tagsSection => 'Tags';

  @override
  String get newList => 'New list';

  @override
  String get newGroup => 'New group';

  @override
  String get newCategory => 'New category';

  @override
  String get newTag => 'New tag';

  @override
  String get nameField => 'Name';

  @override
  String get rename => 'Rename';

  @override
  String get groupLabel => 'Group';

  @override
  String get noGroup => 'No group';

  @override
  String get listLabel => 'List';

  @override
  String get noList => 'No list';

  @override
  String get categoryLabel => 'Category';

  @override
  String get noCategory => 'No category';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get addTagHint => 'Add tag';

  @override
  String get nameRequired => 'Enter a name.';

  @override
  String get nameDuplicate => 'An equivalent name already exists.';

  @override
  String get listNotEmpty => 'The list has tasks. Choose a destination list.';

  @override
  String get noDestination => 'There is no other list to receive the tasks.';

  @override
  String get destinationLabel => 'Destination list';

  @override
  String get tasksMoveNotice =>
      'Tasks will be moved to the chosen destination and the list will be deleted.';

  @override
  String get moveToList => 'Move to list';

  @override
  String get moveToGroup => 'Move to group';

  @override
  String get emptyLists => 'No lists yet. Create the first one!';

  @override
  String get emptyGroups => 'No groups created.';

  @override
  String get emptyCategories => 'No categories created.';

  @override
  String get emptyTags => 'No tags created.';

  @override
  String get filterAll => 'All';

  @override
  String get deleteGroupTitle => 'Delete group';

  @override
  String get deleteGroupNotice =>
      'The lists in the group will be preserved and become ungrouped.';

  @override
  String get deleteCategoryTitle => 'Delete category';

  @override
  String get deleteCategoryNotice =>
      'Tasks will be left without a category; other data is preserved.';

  @override
  String get deleteTagTitle => 'Delete tag';

  @override
  String get deleteTagNotice =>
      'The tag will be removed from tasks; other data is preserved.';

  @override
  String get deleteListTitle => 'Delete list';

  @override
  String get myDayTab => 'My Day';

  @override
  String get viewAll => 'All';

  @override
  String get viewImportant => 'Important';

  @override
  String get viewPlanned => 'Planned';

  @override
  String get viewCompleted => 'Completed';

  @override
  String get addToMyDay => 'Add to My Day';

  @override
  String get removeFromMyDay => 'Remove from My Day';

  @override
  String get emptyMyDay => 'My Day is empty. Add tasks to your daily focus!';

  @override
  String get addExistingTask => 'Add existing task';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get noDueDate => 'No due date';

  @override
  String get noReminder => 'No reminder';

  @override
  String get pickDueDate => 'Set due date';

  @override
  String get pickReminder => 'Set reminder';

  @override
  String get clearDueDate => 'Clear due date';

  @override
  String get clearReminder => 'Clear reminder';

  @override
  String get recurrenceLabel => 'Repeat';

  @override
  String get recurrenceNone => 'Does not repeat';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekdays => 'Weekdays';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get reminderInPast => 'Choose a future time for the reminder.';

  @override
  String get recurrenceRequiresDueDate =>
      'Set a due date before enabling repeat.';

  @override
  String get searchHint => 'Search tasks';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterActive => 'Active';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get dueOverdue => 'Overdue';

  @override
  String get dueToday => 'Today';

  @override
  String get dueNext7 => 'Next 7 days';

  @override
  String get dueCustom => 'Custom range';

  @override
  String get dueFrom => 'From';

  @override
  String get dueTo => 'To';

  @override
  String get reminderWith => 'With reminder';

  @override
  String get reminderWithout => 'Without reminder';

  @override
  String get recurrenceWithActive => 'Recurring';

  @override
  String get recurrenceWithout => 'Not recurring';

  @override
  String get recurrenceCanceled => 'Canceled recurrence';

  @override
  String get noTags => 'No tags';

  @override
  String get emptySearch => 'No results found.';

  @override
  String get statusSection => 'Status';

  @override
  String get dueSection => 'Due date';

  @override
  String get reminderSection => 'Reminder';

  @override
  String get recurrenceSection => 'Recurrence';

  @override
  String get listsSectionFilter => 'Lists';

  @override
  String get groupsSectionFilter => 'Groups';

  @override
  String get categoriesSectionFilter => 'Categories';

  @override
  String get tagsSectionFilter => 'Tags';

  @override
  String get prioritySection => 'Priority';

  @override
  String get dataSection => 'Data';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get importJson => 'Import JSON';

  @override
  String get createBackup => 'Create backup';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get exportJsonTitle => 'Export open format';

  @override
  String get exportJsonWarning =>
      'The JSON file is not encrypted and contains personal data such as notes and reminders. Do you want to continue?';

  @override
  String get backupPasswordTitle => 'Backup password';

  @override
  String get backupPasswordLabel => 'Password';

  @override
  String get backupPasswordConfirm => 'Confirm password';

  @override
  String get backupLostPasswordWarning =>
      'If the password is lost, the backup cannot be recovered. There is no recovery by account or server.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get passwordRequired => 'Enter a password.';

  @override
  String get backupCreated => 'Backup created successfully.';

  @override
  String get exportDone => 'File exported successfully.';

  @override
  String get replaceTitle => 'Replace all data?';

  @override
  String get replaceWarning =>
      'All current data will be fully replaced by the file data. This action cannot be undone.';

  @override
  String get confirmReplace => 'Replace';

  @override
  String get summaryTypeBackup => 'Encrypted backup';

  @override
  String get summaryTypeJson => 'Open JSON';

  @override
  String get summaryExportedAt => 'Exported at';

  @override
  String get summaryActiveTasks => 'Active tasks';

  @override
  String get summaryCompletedTasks => 'Completed tasks';

  @override
  String get summaryTrashedTasks => 'In trash';

  @override
  String get summarySubtasks => 'Subtasks';

  @override
  String get summarySeries => 'Recurring series';

  @override
  String get summaryMyDay => 'My Day entries';

  @override
  String get invalidPassword => 'Wrong password or corrupted file.';

  @override
  String get invalidFile => 'Invalid file.';

  @override
  String get unsupportedVersion => 'Unsupported file version.';

  @override
  String get importDone => 'Data replaced successfully.';

  @override
  String get operationCancelled => 'Operation cancelled.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'Automatic (system)';

  @override
  String get languagePt => 'Português (Brasil)';

  @override
  String get languageEn => 'English';

  @override
  String get languageEs => 'Español';

  @override
  String get languageUpdated => 'Language updated.';

  @override
  String get close => 'Close';

  @override
  String get reminderStateScheduled => 'Scheduled';

  @override
  String get reminderStatePermission => 'Permission needed';

  @override
  String get reminderStateUnavailable => 'Unavailable on this platform';

  @override
  String get reminderStateExpired => 'Expired';

  @override
  String get reminderStatePending => 'Pending verification';

  @override
  String get reminderPermissionTitle => 'Allow notifications';

  @override
  String get reminderPermissionMessage =>
      'To show reminders, the app needs system authorization. You can decline: the reminder stays saved, without alerts.';

  @override
  String get reminderPermissionConfirm => 'Got it';

  @override
  String get reminderNotificationsDisabled =>
      'Notifications disabled. Enable permission in system or browser settings.';

  @override
  String get openTask => 'Open task';
}
