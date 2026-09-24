import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Urutau Tasks'**
  String get appTitle;

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get allTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @newSubtask.
  ///
  /// In en, this message translates to:
  /// **'New step'**
  String get newSubtask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle;

  /// No description provided for @subtaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Step title'**
  String get subtaskTitle;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title.'**
  String get taskTitleRequired;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @editSubtask.
  ///
  /// In en, this message translates to:
  /// **'Edit step'**
  String get editSubtask;

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get taskDetails;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get subtasks;

  /// No description provided for @taskProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} steps completed'**
  String taskProgress(int completed, int total);

  /// No description provided for @noSubtasks.
  ///
  /// In en, this message translates to:
  /// **'No steps yet.'**
  String get noSubtasks;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @noActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Add a task to get started.'**
  String get noActiveTasks;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.'**
  String get noCompletedTasks;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty.'**
  String get trashEmpty;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @reopenTask.
  ///
  /// In en, this message translates to:
  /// **'Reopen task'**
  String get reopenTask;

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get moveToTrash;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @removeSubtask.
  ///
  /// In en, this message translates to:
  /// **'Remove step'**
  String get removeSubtask;

  /// No description provided for @removeSubtaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this step.'**
  String get removeSubtaskConfirmation;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @unableToLoadTasks.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks.'**
  String get unableToLoadTasks;

  /// No description provided for @unableToLoadTask.
  ///
  /// In en, this message translates to:
  /// **'Could not load this task.'**
  String get unableToLoadTask;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'This task is no longer available.'**
  String get taskNotFound;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'The change could not be saved. Try again.'**
  String get actionFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @manageOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get manageOrganization;

  /// No description provided for @lists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get lists;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get newTag;

  /// No description provided for @listName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// No description provided for @editList.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get editList;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @editTag.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get editTag;

  /// No description provided for @deleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get deleteList;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategory;

  /// No description provided for @deleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get deleteTag;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noLists.
  ///
  /// In en, this message translates to:
  /// **'No lists yet.'**
  String get noLists;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet.'**
  String get noGroups;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get noCategories;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet.'**
  String get noTags;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Choose a group'**
  String get selectGroup;

  /// No description provided for @noGroup.
  ///
  /// In en, this message translates to:
  /// **'No group'**
  String get noGroup;

  /// No description provided for @moveToGroup.
  ///
  /// In en, this message translates to:
  /// **'Change group'**
  String get moveToGroup;

  /// No description provided for @selectDestinationList.
  ///
  /// In en, this message translates to:
  /// **'Choose a destination list'**
  String get selectDestinationList;

  /// No description provided for @deleteListNeedsDestination.
  ///
  /// In en, this message translates to:
  /// **'This list has tasks. Choose another list to receive them.'**
  String get deleteListNeedsDestination;

  /// No description provided for @deleteListConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Its tasks and steps will be moved to the selected list.'**
  String get deleteListConfirmation;

  /// No description provided for @deleteGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'The lists will remain and become ungrouped.'**
  String get deleteGroupConfirmation;

  /// No description provided for @deleteCategoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Tasks will keep their other details and lose this category.'**
  String get deleteCategoryConfirmation;

  /// No description provided for @deleteTagConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This tag will be removed from its tasks.'**
  String get deleteTagConfirmation;

  /// No description provided for @duplicateName.
  ///
  /// In en, this message translates to:
  /// **'An item with this name already exists.'**
  String get duplicateName;

  /// No description provided for @taskList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get taskList;

  /// No description provided for @taskCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get taskCategory;

  /// No description provided for @taskTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get taskTags;

  /// No description provided for @noList.
  ///
  /// In en, this message translates to:
  /// **'No list'**
  String get noList;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @noPriority.
  ///
  /// In en, this message translates to:
  /// **'No priority'**
  String get noPriority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @editNotes.
  ///
  /// In en, this message translates to:
  /// **'Edit notes'**
  String get editNotes;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @chooseDueDate.
  ///
  /// In en, this message translates to:
  /// **'Set due date'**
  String get chooseDueDate;

  /// No description provided for @removeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get removeDueDate;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get noReminder;

  /// No description provided for @chooseReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get chooseReminder;

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminder;

  /// No description provided for @reminderInPast.
  ///
  /// In en, this message translates to:
  /// **'Choose a future date and time for the reminder.'**
  String get reminderInPast;

  /// No description provided for @reminderDeliveryScheduled.
  ///
  /// In en, this message translates to:
  /// **'A reminder is set. Delivery depends on this platform and its notification settings.'**
  String get reminderDeliveryScheduled;

  /// No description provided for @reminderPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'System notifications are off. The reminder is saved; enable notifications for system alerts.'**
  String get reminderPermissionNeeded;

  /// No description provided for @reminderCancellationPending.
  ///
  /// In en, this message translates to:
  /// **'A previous system reminder could not be confirmed as canceled and may still appear. The app will retry.'**
  String get reminderCancellationPending;

  /// No description provided for @webNotificationSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'If your browser blocked the request, allow notifications in this site\'s settings, then check again.'**
  String get webNotificationSettingsHelp;

  /// No description provided for @checkNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkNotificationPermission;

  /// No description provided for @reminderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'System notifications are unavailable here. Keep the app open for best-effort alerts.'**
  String get reminderUnavailable;

  /// No description provided for @reminderExpired.
  ///
  /// In en, this message translates to:
  /// **'The reminder time has passed. No late alert will be sent.'**
  String get reminderExpired;

  /// No description provided for @reminderPending.
  ///
  /// In en, this message translates to:
  /// **'Checking notification availability…'**
  String get reminderPending;

  /// No description provided for @reminderPaused.
  ///
  /// In en, this message translates to:
  /// **'The reminder is saved and paused while this task is completed or in Trash.'**
  String get reminderPaused;

  /// No description provided for @reminderPermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'Task reminders use local notifications. Delivery depends on system or browser permission and may vary by platform. On the web, the browser may ask now; canceling date or time selection will not save a reminder.'**
  String get reminderPermissionRationale;

  /// No description provided for @openTask.
  ///
  /// In en, this message translates to:
  /// **'Open task'**
  String get openTask;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for task reminders'**
  String get notificationChannelDescription;

  /// No description provided for @openNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable system notifications'**
  String get openNotificationSettings;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @myDay.
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get myDay;

  /// No description provided for @importantTasks.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get importantTasks;

  /// No description provided for @plannedTasks.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get plannedTasks;

  /// No description provided for @addToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add to My Day'**
  String get addToMyDay;

  /// No description provided for @removeFromMyDay.
  ///
  /// In en, this message translates to:
  /// **'Remove from My Day'**
  String get removeFromMyDay;

  /// No description provided for @myDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add tasks here to focus on today.'**
  String get myDayEmpty;

  /// No description provided for @noImportantTasks.
  ///
  /// In en, this message translates to:
  /// **'No important tasks right now.'**
  String get noImportantTasks;

  /// No description provided for @noPlannedTasks.
  ///
  /// In en, this message translates to:
  /// **'No planned tasks right now.'**
  String get noPlannedTasks;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurrence;

  /// No description provided for @noRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get noRecurrence;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Every weekday'**
  String get recurrenceWeekdays;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @recurrenceCancelled.
  ///
  /// In en, this message translates to:
  /// **'This recurrence was canceled.'**
  String get recurrenceCancelled;

  /// No description provided for @recurrenceNeedsDueDate.
  ///
  /// In en, this message translates to:
  /// **'Add a due date before setting a recurrence.'**
  String get recurrenceNeedsDueDate;

  /// No description provided for @recurrenceHelp.
  ///
  /// In en, this message translates to:
  /// **'With recurrence enabled, completing this task saves it in history and creates the next occurrence. Steps are not copied.'**
  String get recurrenceHelp;

  /// No description provided for @recurrenceHistoryReadOnly.
  ///
  /// In en, this message translates to:
  /// **'A later occurrence already exists. Edit the latest occurrence to change the series.'**
  String get recurrenceHistoryReadOnly;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles, notes, and steps'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @searchMatchInNotes.
  ///
  /// In en, this message translates to:
  /// **'Match in notes'**
  String get searchMatchInNotes;

  /// No description provided for @searchMatchInSteps.
  ///
  /// In en, this message translates to:
  /// **'Match in a step'**
  String get searchMatchInSteps;

  /// No description provided for @searchMatchInTitle.
  ///
  /// In en, this message translates to:
  /// **'Match in title'**
  String get searchMatchInTitle;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No tasks match the current search and filters.'**
  String get noSearchResults;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @activeTasks.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTasks;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @nextSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get nextSevenDays;

  /// No description provided for @customDateRange.
  ///
  /// In en, this message translates to:
  /// **'Custom date range'**
  String get customDateRange;

  /// No description provided for @withReminder.
  ///
  /// In en, this message translates to:
  /// **'With reminder'**
  String get withReminder;

  /// No description provided for @withoutReminder.
  ///
  /// In en, this message translates to:
  /// **'Without reminder'**
  String get withoutReminder;

  /// No description provided for @withRecurrence.
  ///
  /// In en, this message translates to:
  /// **'With active recurrence'**
  String get withRecurrence;

  /// No description provided for @withoutRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Without recurrence'**
  String get withoutRecurrence;

  /// No description provided for @cancelledRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Canceled recurrence'**
  String get cancelledRecurrence;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get chooseDate;

  /// No description provided for @dateRangeRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a start and end date before applying this filter.'**
  String get dateRangeRequired;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get language;

  /// No description provided for @languagePreferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used for app text. Dates and number formats continue to follow your device region.'**
  String get languagePreferenceHelp;

  /// No description provided for @automaticSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic (system)'**
  String get automaticSystem;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português (Brasil)'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @backupAndPortability.
  ///
  /// In en, this message translates to:
  /// **'Data and portability'**
  String get backupAndPortability;

  /// No description provided for @backupAndPortabilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a password-protected backup, export readable JSON, or replace local data from a compatible file.'**
  String get backupAndPortabilityDescription;

  /// No description provided for @preparingEncryptedBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypting and preparing the backup…'**
  String get preparingEncryptedBackup;

  /// No description provided for @preparingJsonExport.
  ///
  /// In en, this message translates to:
  /// **'Preparing the JSON export…'**
  String get preparingJsonExport;

  /// No description provided for @preparingDataRestore.
  ///
  /// In en, this message translates to:
  /// **'Validating and preparing the restore…'**
  String get preparingDataRestore;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create encrypted backup'**
  String get createBackup;

  /// No description provided for @encryptedBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'A complete backup protected with a password you choose.'**
  String get encryptedBackupDescription;

  /// No description provided for @exportOpenJson.
  ///
  /// In en, this message translates to:
  /// **'Export open JSON'**
  String get exportOpenJson;

  /// No description provided for @unencryptedJsonDescription.
  ///
  /// In en, this message translates to:
  /// **'A readable, unencrypted file containing your task data.'**
  String get unencryptedJsonDescription;

  /// No description provided for @importOrRestore.
  ///
  /// In en, this message translates to:
  /// **'Import or restore'**
  String get importOrRestore;

  /// No description provided for @encryptedBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'The backup is protected by this password. If you lose it, the backup cannot be recovered.'**
  String get encryptedBackupWarning;

  /// No description provided for @unencryptedExportWarning.
  ///
  /// In en, this message translates to:
  /// **'This JSON is not encrypted. It is readable and contains personal data, including task notes and reminders.'**
  String get unencryptedExportWarning;

  /// No description provided for @importReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Importing or restoring replaces all current local data after you review and confirm the file.'**
  String get importReplaceWarning;

  /// No description provided for @backupExportDone.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup saved.'**
  String get backupExportDone;

  /// No description provided for @jsonExportDone.
  ///
  /// In en, this message translates to:
  /// **'JSON export saved.'**
  String get jsonExportDone;

  /// No description provided for @dataImportDone.
  ///
  /// In en, this message translates to:
  /// **'Local data replaced from the file.'**
  String get dataImportDone;

  /// No description provided for @chooseExportDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save the file'**
  String get chooseExportDestination;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @backupPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the password used when this backup was created.'**
  String get backupPasswordRequired;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @emptyPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get emptyPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'Review imported data'**
  String get importPreview;

  /// No description provided for @exportDate.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exportDate;

  /// No description provided for @openJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Open JSON file'**
  String get openJsonFile;

  /// No description provided for @encryptedBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup file'**
  String get encryptedBackupFile;

  /// No description provided for @replaceLocalData.
  ///
  /// In en, this message translates to:
  /// **'Replace local data'**
  String get replaceLocalData;

  /// No description provided for @wrongPasswordOrCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect or the backup is damaged.'**
  String get wrongPasswordOrCorrupt;

  /// No description provided for @invalidImportFile.
  ///
  /// In en, this message translates to:
  /// **'The file is invalid or contains inconsistent data.'**
  String get invalidImportFile;

  /// No description provided for @incompatibleFile.
  ///
  /// In en, this message translates to:
  /// **'This file version is not supported.'**
  String get incompatibleFile;

  /// No description provided for @databaseFromNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This data was created by a newer version of Urutau Tasks. Update the app to open it; your data was left unchanged.'**
  String get databaseFromNewerVersion;

  /// No description provided for @databaseMigrationFailed.
  ///
  /// In en, this message translates to:
  /// **'The local database could not be updated. The app could not continue to protect your data.'**
  String get databaseMigrationFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
