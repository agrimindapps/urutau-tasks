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
  String get allTasks => 'All tasks';

  @override
  String get completedTasks => 'Completed';

  @override
  String get trash => 'Trash';

  @override
  String get newTask => 'New task';

  @override
  String get newSubtask => 'New step';

  @override
  String get taskTitle => 'Task title';

  @override
  String get subtaskTitle => 'Step title';

  @override
  String get taskTitleRequired => 'Enter a title.';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get editTask => 'Edit task';

  @override
  String get editSubtask => 'Edit step';

  @override
  String get taskDetails => 'Task details';

  @override
  String get subtasks => 'Steps';

  @override
  String taskProgress(int completed, int total) {
    return '$completed/$total steps completed';
  }

  @override
  String get noSubtasks => 'No steps yet.';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get noActiveTasks => 'Nothing here yet. Add a task to get started.';

  @override
  String get noCompletedTasks => 'No completed tasks yet.';

  @override
  String get trashEmpty => 'Trash is empty.';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get reopenTask => 'Reopen task';

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String get restore => 'Restore';

  @override
  String get removeSubtask => 'Remove step';

  @override
  String get removeSubtaskConfirmation =>
      'This will permanently remove this step.';

  @override
  String get remove => 'Remove';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading…';

  @override
  String get unableToLoadTasks => 'Could not load tasks.';

  @override
  String get unableToLoadTask => 'Could not load this task.';

  @override
  String get taskNotFound => 'This task is no longer available.';

  @override
  String get actionFailed => 'The change could not be saved. Try again.';

  @override
  String get retry => 'Retry';

  @override
  String get manageOrganization => 'Organize';

  @override
  String get lists => 'Lists';

  @override
  String get groups => 'Groups';

  @override
  String get categories => 'Categories';

  @override
  String get tags => 'Tags';

  @override
  String get newList => 'New list';

  @override
  String get newGroup => 'New group';

  @override
  String get newCategory => 'New category';

  @override
  String get newTag => 'New tag';

  @override
  String get listName => 'List name';

  @override
  String get groupName => 'Group name';

  @override
  String get categoryName => 'Category name';

  @override
  String get tagName => 'Tag name';

  @override
  String get editList => 'Edit list';

  @override
  String get editGroup => 'Edit group';

  @override
  String get editCategory => 'Edit category';

  @override
  String get editTag => 'Edit tag';

  @override
  String get deleteList => 'Delete list';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get deleteTag => 'Delete tag';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get noLists => 'No lists yet.';

  @override
  String get noGroups => 'No groups yet.';

  @override
  String get noCategories => 'No categories yet.';

  @override
  String get noTags => 'No tags yet.';

  @override
  String get selectGroup => 'Choose a group';

  @override
  String get noGroup => 'No group';

  @override
  String get moveToGroup => 'Change group';

  @override
  String get selectDestinationList => 'Choose a destination list';

  @override
  String get deleteListNeedsDestination =>
      'This list has tasks. Choose another list to receive them.';

  @override
  String get deleteListConfirmation =>
      'Its tasks and steps will be moved to the selected list.';

  @override
  String get deleteGroupConfirmation =>
      'The lists will remain and become ungrouped.';

  @override
  String get deleteCategoryConfirmation =>
      'Tasks will keep their other details and lose this category.';

  @override
  String get deleteTagConfirmation =>
      'This tag will be removed from its tasks.';

  @override
  String get duplicateName => 'An item with this name already exists.';

  @override
  String get taskList => 'List';

  @override
  String get taskCategory => 'Category';

  @override
  String get taskTags => 'Tags';

  @override
  String get noList => 'No list';

  @override
  String get noCategory => 'No category';

  @override
  String get priority => 'Priority';

  @override
  String get noPriority => 'No priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get notes => 'Notes';

  @override
  String get editNotes => 'Edit notes';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get dueDate => 'Due date';

  @override
  String get noDueDate => 'No due date';

  @override
  String get chooseDueDate => 'Set due date';

  @override
  String get removeDueDate => 'Remove due date';

  @override
  String get reminder => 'Reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String get chooseReminder => 'Set reminder';

  @override
  String get removeReminder => 'Remove reminder';

  @override
  String get reminderInPast =>
      'Choose a future date and time for the reminder.';

  @override
  String get reminderDeliveryScheduled =>
      'A reminder is set. Delivery depends on this platform and its notification settings.';

  @override
  String get reminderPermissionNeeded =>
      'System notifications are off. The reminder is saved; enable notifications for system alerts.';

  @override
  String get reminderCancellationPending =>
      'A previous system reminder could not be confirmed as canceled and may still appear. The app will retry.';

  @override
  String get webNotificationSettingsHelp =>
      'If your browser blocked the request, allow notifications in this site\'s settings, then check again.';

  @override
  String get checkNotificationPermission => 'Check again';

  @override
  String get reminderUnavailable =>
      'System notifications are unavailable here. Keep the app open for best-effort alerts.';

  @override
  String get reminderExpired =>
      'The reminder time has passed. No late alert will be sent.';

  @override
  String get reminderPending => 'Checking notification availability…';

  @override
  String get reminderPaused =>
      'The reminder is saved and paused while this task is completed or in Trash.';

  @override
  String get reminderPermissionRationale =>
      'Task reminders use local notifications. Delivery depends on system or browser permission and may vary by platform. On the web, the browser may ask now; canceling date or time selection will not save a reminder.';

  @override
  String get openTask => 'Open task';

  @override
  String get notificationChannelName => 'Task reminders';

  @override
  String get notificationChannelDescription =>
      'Notifications for task reminders';

  @override
  String get openNotificationSettings => 'Enable system notifications';

  @override
  String get notNow => 'Not now';

  @override
  String get myDay => 'My Day';

  @override
  String get importantTasks => 'Important';

  @override
  String get plannedTasks => 'Planned';

  @override
  String get addToMyDay => 'Add to My Day';

  @override
  String get removeFromMyDay => 'Remove from My Day';

  @override
  String get myDayEmpty => 'Add tasks here to focus on today.';

  @override
  String get noImportantTasks => 'No important tasks right now.';

  @override
  String get noPlannedTasks => 'No planned tasks right now.';

  @override
  String get recurrence => 'Repeat';

  @override
  String get noRecurrence => 'Does not repeat';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekdays => 'Every weekday';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get recurrenceCancelled => 'This recurrence was canceled.';

  @override
  String get recurrenceNeedsDueDate =>
      'Add a due date before setting a recurrence.';

  @override
  String get recurrenceHelp =>
      'With recurrence enabled, completing this task saves it in history and creates the next occurrence. Steps are not copied.';

  @override
  String get recurrenceHistoryReadOnly =>
      'A later occurrence already exists. Edit the latest occurrence to change the series.';

  @override
  String get searchTasks => 'Search tasks';

  @override
  String get searchHint => 'Search titles, notes, and steps';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get searchMatchInNotes => 'Match in notes';

  @override
  String get searchMatchInSteps => 'Match in a step';

  @override
  String get searchMatchInTitle => 'Match in title';

  @override
  String get noSearchResults =>
      'No tasks match the current search and filters.';

  @override
  String get filters => 'Filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get apply => 'Apply';

  @override
  String get status => 'Status';

  @override
  String get activeTasks => 'Active';

  @override
  String get overdue => 'Overdue';

  @override
  String get dueToday => 'Due today';

  @override
  String get nextSevenDays => 'Next 7 days';

  @override
  String get customDateRange => 'Custom date range';

  @override
  String get withReminder => 'With reminder';

  @override
  String get withoutReminder => 'Without reminder';

  @override
  String get withRecurrence => 'With active recurrence';

  @override
  String get withoutRecurrence => 'Without recurrence';

  @override
  String get cancelledRecurrence => 'Canceled recurrence';

  @override
  String get chooseDate => 'Choose dates';

  @override
  String get dateRangeRequired =>
      'Choose a start and end date before applying this filter.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Interface language';

  @override
  String get languagePreferenceHelp =>
      'Choose the language used for app text. Dates and number formats continue to follow your device region.';

  @override
  String get automaticSystem => 'Automatic (system)';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get backupAndPortability => 'Data and portability';

  @override
  String get backupAndPortabilityDescription =>
      'Create a password-protected backup, export readable JSON, or replace local data from a compatible file.';

  @override
  String get preparingEncryptedBackup => 'Encrypting and preparing the backup…';

  @override
  String get preparingJsonExport => 'Preparing the JSON export…';

  @override
  String get preparingDataRestore => 'Validating and preparing the restore…';

  @override
  String get createBackup => 'Create encrypted backup';

  @override
  String get encryptedBackupDescription =>
      'A complete backup protected with a password you choose.';

  @override
  String get exportOpenJson => 'Export open JSON';

  @override
  String get unencryptedJsonDescription =>
      'A readable, unencrypted file containing your task data.';

  @override
  String get importOrRestore => 'Import or restore';

  @override
  String get encryptedBackupWarning =>
      'The backup is protected by this password. If you lose it, the backup cannot be recovered.';

  @override
  String get unencryptedExportWarning =>
      'This JSON is not encrypted. It is readable and contains personal data, including task notes and reminders.';

  @override
  String get importReplaceWarning =>
      'Importing or restoring replaces all current local data after you review and confirm the file.';

  @override
  String get backupExportDone => 'Encrypted backup saved.';

  @override
  String get jsonExportDone => 'JSON export saved.';

  @override
  String get dataImportDone => 'Local data replaced from the file.';

  @override
  String get chooseExportDestination => 'Choose where to save the file';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get backupPasswordRequired =>
      'Enter the password used when this backup was created.';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get emptyPassword => 'Enter a password.';

  @override
  String get passwordMismatch => 'The passwords do not match.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get importPreview => 'Review imported data';

  @override
  String get exportDate => 'Exported';

  @override
  String get openJsonFile => 'Open JSON file';

  @override
  String get encryptedBackupFile => 'Encrypted backup file';

  @override
  String get replaceLocalData => 'Replace local data';

  @override
  String get wrongPasswordOrCorrupt =>
      'The password is incorrect or the backup is damaged.';

  @override
  String get invalidImportFile =>
      'The file is invalid or contains inconsistent data.';

  @override
  String get incompatibleFile => 'This file version is not supported.';

  @override
  String get databaseFromNewerVersion =>
      'This data was created by a newer version of Urutau Tasks. Update the app to open it; your data was left unchanged.';

  @override
  String get databaseMigrationFailed =>
      'The local database could not be updated. The app could not continue to protect your data.';
}
