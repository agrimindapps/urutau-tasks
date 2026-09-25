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
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Urutau Tasks'**
  String get appTitle;

  /// No description provided for @navTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get navTasks;

  /// No description provided for @navTrash.
  ///
  /// In pt, this message translates to:
  /// **'Lixeira'**
  String get navTrash;

  /// No description provided for @newTaskTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa'**
  String get newTaskTooltip;

  /// No description provided for @editTaskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar tarefa'**
  String get editTaskTitle;

  /// No description provided for @createTaskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa'**
  String get createTaskTitle;

  /// No description provided for @taskTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get taskTitleLabel;

  /// No description provided for @taskNotesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get taskNotesLabel;

  /// No description provided for @taskTitleHint.
  ///
  /// In pt, this message translates to:
  /// **'O que precisa ser feito?'**
  String get taskTitleHint;

  /// No description provided for @taskNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes (opcional)'**
  String get taskNotesHint;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @complete.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get complete;

  /// No description provided for @reopen.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir'**
  String get reopen;

  /// No description provided for @restore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tarefa?'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskMessage.
  ///
  /// In pt, this message translates to:
  /// **'A tarefa e suas etapas irão para a lixeira. Você pode restaurá-las depois.'**
  String get deleteTaskMessage;

  /// No description provided for @emptyTasks.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa ainda. Crie a primeira!'**
  String get emptyTasks;

  /// No description provided for @emptyTrash.
  ///
  /// In pt, this message translates to:
  /// **'A lixeira está vazia.'**
  String get emptyTrash;

  /// No description provided for @trashSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas excluídas ficam aqui até serem restauradas.'**
  String get trashSubtitle;

  /// No description provided for @errorTitleRequired.
  ///
  /// In pt, this message translates to:
  /// **'O título não pode ficar vazio.'**
  String get errorTitleRequired;

  /// No description provided for @errorEditInTrash.
  ///
  /// In pt, this message translates to:
  /// **'Restaure a tarefa para editá-la.'**
  String get errorEditInTrash;

  /// No description provided for @subtasksSection.
  ///
  /// In pt, this message translates to:
  /// **'Etapas'**
  String get subtasksSection;

  /// No description provided for @addSubtaskTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar etapa'**
  String get addSubtaskTooltip;

  /// No description provided for @subtaskHint.
  ///
  /// In pt, this message translates to:
  /// **'Título da etapa'**
  String get subtaskHint;

  /// No description provided for @removeSubtaskTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover etapa'**
  String get removeSubtaskTooltip;

  /// No description provided for @emptySubtasks.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma etapa adicionada.'**
  String get emptySubtasks;

  /// Progresso de etapas concluídas
  ///
  /// In pt, this message translates to:
  /// **'{completed} de {total}'**
  String progressOf(int completed, int total);

  /// No description provided for @taskDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da tarefa'**
  String get taskDetailTitle;

  /// No description provided for @errorUnexpected.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a ação.'**
  String get errorUnexpected;
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
