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

  /// No description provided for @errorNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'O nome não pode ficar vazio.'**
  String get errorNameRequired;

  /// No description provided for @errorDuplicateName.
  ///
  /// In pt, this message translates to:
  /// **'Já existe um item com esse nome.'**
  String get errorDuplicateName;

  /// No description provided for @errorListNotEmpty.
  ///
  /// In pt, this message translates to:
  /// **'A lista tem tarefas. Escolha uma lista de destino.'**
  String get errorListNotEmpty;

  /// No description provided for @errorSameDestination.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma lista de destino diferente.'**
  String get errorSameDestination;

  /// No description provided for @navLists.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get navLists;

  /// No description provided for @listsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Listas e grupos'**
  String get listsTitle;

  /// No description provided for @categoriesSection.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get categoriesSection;

  /// No description provided for @tagsSection.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get tagsSection;

  /// No description provided for @groupsSection.
  ///
  /// In pt, this message translates to:
  /// **'Grupos'**
  String get groupsSection;

  /// No description provided for @newListTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Nova lista'**
  String get newListTooltip;

  /// No description provided for @newGroupTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Novo grupo'**
  String get newGroupTooltip;

  /// No description provided for @newCategoryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Nova categoria'**
  String get newCategoryTooltip;

  /// No description provided for @newTagTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Nova tag'**
  String get newTagTooltip;

  /// No description provided for @nameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get nameLabel;

  /// No description provided for @emptyLists.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma lista criada.'**
  String get emptyLists;

  /// No description provided for @emptyCategories.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma categoria criada.'**
  String get emptyCategories;

  /// No description provided for @emptyTags.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tag criada.'**
  String get emptyTags;

  /// No description provided for @deleteListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir lista?'**
  String get deleteListTitle;

  /// No description provided for @deleteListEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'A lista será excluída.'**
  String get deleteListEmptyMessage;

  /// No description provided for @deleteListDestinationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a lista de destino'**
  String get deleteListDestinationTitle;

  /// Aviso de migração de tarefas ao excluir lista
  ///
  /// In pt, this message translates to:
  /// **'As tarefas de \"{name}\" serão movidas para a lista escolhida, preservando subtarefas e classificações.'**
  String deleteListDestinationMessage(String name);

  /// No description provided for @deleteGroupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir grupo?'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupMessage.
  ///
  /// In pt, this message translates to:
  /// **'As listas do grupo permanecem, sem grupo.'**
  String get deleteGroupMessage;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir categoria?'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In pt, this message translates to:
  /// **'As tarefas deixam de ter categoria.'**
  String get deleteCategoryMessage;

  /// No description provided for @deleteTagTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tag?'**
  String get deleteTagTitle;

  /// No description provided for @deleteTagMessage.
  ///
  /// In pt, this message translates to:
  /// **'As associações serão removidas das tarefas.'**
  String get deleteTagMessage;

  /// No description provided for @semLista.
  ///
  /// In pt, this message translates to:
  /// **'Sem lista'**
  String get semLista;

  /// No description provided for @listLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get listLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get categoryLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @noCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem categoria'**
  String get noCategory;

  /// No description provided for @addTagTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tag'**
  String get addTagTooltip;

  /// No description provided for @removeTagTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover tag'**
  String get removeTagTooltip;

  /// No description provided for @tagHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome da tag'**
  String get tagHint;

  /// No description provided for @organizationSection.
  ///
  /// In pt, this message translates to:
  /// **'Organização'**
  String get organizationSection;

  /// Contagem de tarefas de uma lista
  ///
  /// In pt, this message translates to:
  /// **'{count} tarefas'**
  String tasksCount(int count);

  /// No description provided for @moveUp.
  ///
  /// In pt, this message translates to:
  /// **'Subir'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In pt, this message translates to:
  /// **'Descer'**
  String get moveDown;

  /// No description provided for @moveToGroup.
  ///
  /// In pt, this message translates to:
  /// **'Mover para grupo'**
  String get moveToGroup;

  /// No description provided for @semGrupo.
  ///
  /// In pt, this message translates to:
  /// **'Sem grupo'**
  String get semGrupo;

  /// No description provided for @rename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get rename;

  /// No description provided for @navMyDay.
  ///
  /// In pt, this message translates to:
  /// **'Meu dia'**
  String get navMyDay;

  /// No description provided for @myDayTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meu dia'**
  String get myDayTitle;

  /// No description provided for @myDayEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa no seu dia ainda.'**
  String get myDayEmpty;

  /// No description provided for @addToMyDay.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao Meu dia'**
  String get addToMyDay;

  /// No description provided for @removeFromMyDay.
  ///
  /// In pt, this message translates to:
  /// **'Remover do Meu dia'**
  String get removeFromMyDay;

  /// No description provided for @addExistingTask.
  ///
  /// In pt, this message translates to:
  /// **'Escolher tarefa existente'**
  String get addExistingTask;

  /// No description provided for @noTasksToAdd.
  ///
  /// In pt, this message translates to:
  /// **'Não há tarefas disponíveis para adicionar.'**
  String get noTasksToAdd;

  /// No description provided for @viewAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get viewAll;

  /// No description provided for @viewImportant.
  ///
  /// In pt, this message translates to:
  /// **'Importante'**
  String get viewImportant;

  /// No description provided for @viewPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Planejado'**
  String get viewPlanned;

  /// No description provided for @viewCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas'**
  String get viewCompleted;

  /// No description provided for @priorityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get priorityLabel;

  /// No description provided for @priorityNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem prioridade'**
  String get priorityNone;

  /// No description provided for @priorityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In pt, this message translates to:
  /// **'Urgente'**
  String get priorityUrgent;

  /// No description provided for @dueDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get dueDateLabel;

  /// No description provided for @noDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem prazo'**
  String get noDueDate;

  /// No description provided for @clearDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Remover prazo'**
  String get clearDueDate;

  /// No description provided for @emptyView.
  ///
  /// In pt, this message translates to:
  /// **'Nada por aqui ainda.'**
  String get emptyView;
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
