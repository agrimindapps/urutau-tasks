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

  @override
  String get errorNameRequired => 'The name cannot be empty.';

  @override
  String get errorDuplicateName => 'An item with this name already exists.';

  @override
  String get errorListNotEmpty =>
      'The list has tasks. Choose a destination list.';

  @override
  String get errorSameDestination => 'Choose a different destination list.';

  @override
  String get navLists => 'Lists';

  @override
  String get listsTitle => 'Lists and groups';

  @override
  String get categoriesSection => 'Categories';

  @override
  String get tagsSection => 'Tags';

  @override
  String get groupsSection => 'Groups';

  @override
  String get newListTooltip => 'New list';

  @override
  String get newGroupTooltip => 'New group';

  @override
  String get newCategoryTooltip => 'New category';

  @override
  String get newTagTooltip => 'New tag';

  @override
  String get nameLabel => 'Name';

  @override
  String get emptyLists => 'No lists created.';

  @override
  String get emptyCategories => 'No categories created.';

  @override
  String get emptyTags => 'No tags created.';

  @override
  String get deleteListTitle => 'Delete list?';

  @override
  String get deleteListEmptyMessage => 'The list will be deleted.';

  @override
  String get deleteListDestinationTitle => 'Choose the destination list';

  @override
  String deleteListDestinationMessage(String name) {
    return 'Tasks from \"$name\" will be moved to the chosen list, preserving subtasks and classifications.';
  }

  @override
  String get deleteGroupTitle => 'Delete group?';

  @override
  String get deleteGroupMessage =>
      'The group\'s lists remain, without a group.';

  @override
  String get deleteCategoryTitle => 'Delete category?';

  @override
  String get deleteCategoryMessage => 'Tasks will no longer have a category.';

  @override
  String get deleteTagTitle => 'Delete tag?';

  @override
  String get deleteTagMessage => 'Associations will be removed from tasks.';

  @override
  String get semLista => 'No list';

  @override
  String get listLabel => 'List';

  @override
  String get categoryLabel => 'Category';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get noCategory => 'No category';

  @override
  String get addTagTooltip => 'Add tag';

  @override
  String get removeTagTooltip => 'Remove tag';

  @override
  String get tagHint => 'Tag name';

  @override
  String get organizationSection => 'Organization';

  @override
  String tasksCount(int count) {
    return '$count tasks';
  }

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get moveToGroup => 'Move to group';

  @override
  String get semGrupo => 'No group';

  @override
  String get rename => 'Rename';

  @override
  String get navMyDay => 'My Day';

  @override
  String get myDayTitle => 'My Day';

  @override
  String get myDayEmpty => 'No tasks in your day yet.';

  @override
  String get addToMyDay => 'Add to My Day';

  @override
  String get removeFromMyDay => 'Remove from My Day';

  @override
  String get addExistingTask => 'Choose existing task';

  @override
  String get noTasksToAdd => 'No tasks available to add.';

  @override
  String get viewAll => 'All';

  @override
  String get viewImportant => 'Important';

  @override
  String get viewPlanned => 'Planned';

  @override
  String get viewCompleted => 'Completed';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityNone => 'No priority';

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
  String get noDueDate => 'No due date';

  @override
  String get clearDueDate => 'Remove due date';

  @override
  String get emptyView => 'Nothing here yet.';

  @override
  String get recurrenceLabel => 'Recurrence';

  @override
  String get noRecurrence => 'No recurrence';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekdays => 'Weekdays';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqAnnual => 'Yearly';

  @override
  String get cancelSeries => 'Cancel recurrence';

  @override
  String get cancelSeriesTitle => 'Cancel recurrence?';

  @override
  String get cancelSeriesMessage =>
      'New occurrences will not be created. History is preserved.';

  @override
  String get seriesCancelledNote => 'Recurrence cancelled.';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String get clearReminder => 'Remove reminder';

  @override
  String get setReminder => 'Set reminder';

  @override
  String get errorReminderPast => 'Choose a time in the future.';

  @override
  String get errorDueDateRequired =>
      'Set a due date before enabling recurrence.';
}
