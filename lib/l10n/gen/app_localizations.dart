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
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Urutau Tasks'**
  String get appTitle;

  /// No description provided for @tasksTab.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get tasksTab;

  /// No description provided for @trashTab.
  ///
  /// In pt, this message translates to:
  /// **'Lixeira'**
  String get trashTab;

  /// No description provided for @addTask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa'**
  String get addTask;

  /// No description provided for @taskTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get taskTitleLabel;

  /// No description provided for @taskTitleHint.
  ///
  /// In pt, this message translates to:
  /// **'O que precisa ser feito?'**
  String get taskTitleHint;

  /// No description provided for @notesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar uma nota'**
  String get notesHint;

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

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @titleRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe um título.'**
  String get titleRequired;

  /// No description provided for @markComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get markComplete;

  /// No description provided for @markIncomplete.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir'**
  String get markIncomplete;

  /// No description provided for @emptyTasks.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa por aqui. Crie a primeira!'**
  String get emptyTasks;

  /// No description provided for @emptyTrash.
  ///
  /// In pt, this message translates to:
  /// **'A lixeira está vazia.'**
  String get emptyTrash;

  /// No description provided for @subtasksSection.
  ///
  /// In pt, this message translates to:
  /// **'Subtarefas'**
  String get subtasksSection;

  /// No description provided for @addSubtask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar subtarefa'**
  String get addSubtask;

  /// No description provided for @subtaskTitleHint.
  ///
  /// In pt, this message translates to:
  /// **'Nova etapa'**
  String get subtaskTitleHint;

  /// No description provided for @progressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get progressLabel;

  /// No description provided for @moveToTrash.
  ///
  /// In pt, this message translates to:
  /// **'Mover para a lixeira'**
  String get moveToTrash;

  /// No description provided for @restore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @trashBanner.
  ///
  /// In pt, this message translates to:
  /// **'Esta tarefa está na lixeira.'**
  String get trashBanner;

  /// No description provided for @completedSection.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas'**
  String get completedSection;

  /// No description provided for @activeSection.
  ///
  /// In pt, this message translates to:
  /// **'Ativas'**
  String get activeSection;

  /// No description provided for @taskDetail.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da tarefa'**
  String get taskDetail;

  /// No description provided for @openTaskDetail.
  ///
  /// In pt, this message translates to:
  /// **'Abrir detalhes da tarefa'**
  String get openTaskDetail;

  /// No description provided for @listsTab.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get listsTab;

  /// No description provided for @listsSection.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get listsSection;

  /// No description provided for @groupsSection.
  ///
  /// In pt, this message translates to:
  /// **'Grupos'**
  String get groupsSection;

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

  /// No description provided for @newList.
  ///
  /// In pt, this message translates to:
  /// **'Nova lista'**
  String get newList;

  /// No description provided for @newGroup.
  ///
  /// In pt, this message translates to:
  /// **'Novo grupo'**
  String get newGroup;

  /// No description provided for @newCategory.
  ///
  /// In pt, this message translates to:
  /// **'Nova categoria'**
  String get newCategory;

  /// No description provided for @newTag.
  ///
  /// In pt, this message translates to:
  /// **'Nova tag'**
  String get newTag;

  /// No description provided for @nameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get nameField;

  /// No description provided for @rename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get rename;

  /// No description provided for @groupLabel.
  ///
  /// In pt, this message translates to:
  /// **'Grupo'**
  String get groupLabel;

  /// No description provided for @noGroup.
  ///
  /// In pt, this message translates to:
  /// **'Sem grupo'**
  String get noGroup;

  /// No description provided for @listLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get listLabel;

  /// No description provided for @noList.
  ///
  /// In pt, this message translates to:
  /// **'Sem lista'**
  String get noList;

  /// No description provided for @categoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get categoryLabel;

  /// No description provided for @noCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem categoria'**
  String get noCategory;

  /// No description provided for @tagsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @addTagHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tag'**
  String get addTagHint;

  /// No description provided for @nameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome.'**
  String get nameRequired;

  /// No description provided for @nameDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Já existe um nome equivalente.'**
  String get nameDuplicate;

  /// No description provided for @listNotEmpty.
  ///
  /// In pt, this message translates to:
  /// **'A lista possui tarefas. Escolha uma lista de destino.'**
  String get listNotEmpty;

  /// No description provided for @noDestination.
  ///
  /// In pt, this message translates to:
  /// **'Não há outra lista para receber as tarefas.'**
  String get noDestination;

  /// No description provided for @destinationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lista de destino'**
  String get destinationLabel;

  /// No description provided for @tasksMoveNotice.
  ///
  /// In pt, this message translates to:
  /// **'As tarefas serão movidas para o destino escolhido e a lista será excluída.'**
  String get tasksMoveNotice;

  /// No description provided for @moveToList.
  ///
  /// In pt, this message translates to:
  /// **'Mover para lista'**
  String get moveToList;

  /// No description provided for @moveToGroup.
  ///
  /// In pt, this message translates to:
  /// **'Mover para grupo'**
  String get moveToGroup;

  /// No description provided for @emptyLists.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma lista. Crie a primeira!'**
  String get emptyLists;

  /// No description provided for @emptyGroups.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum grupo criado.'**
  String get emptyGroups;

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

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir grupo'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupNotice.
  ///
  /// In pt, this message translates to:
  /// **'As listas do grupo serão preservadas e ficarão sem grupo.'**
  String get deleteGroupNotice;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir categoria'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryNotice.
  ///
  /// In pt, this message translates to:
  /// **'As tarefas ficarão sem categoria; os demais dados serão preservados.'**
  String get deleteCategoryNotice;

  /// No description provided for @deleteTagTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tag'**
  String get deleteTagTitle;

  /// No description provided for @deleteTagNotice.
  ///
  /// In pt, this message translates to:
  /// **'A tag será removida das tarefas; os demais dados serão preservados.'**
  String get deleteTagNotice;

  /// No description provided for @deleteListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir lista'**
  String get deleteListTitle;

  /// No description provided for @myDayTab.
  ///
  /// In pt, this message translates to:
  /// **'My Day'**
  String get myDayTab;

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

  /// No description provided for @addToMyDay.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao My Day'**
  String get addToMyDay;

  /// No description provided for @removeFromMyDay.
  ///
  /// In pt, this message translates to:
  /// **'Remover do My Day'**
  String get removeFromMyDay;

  /// No description provided for @emptyMyDay.
  ///
  /// In pt, this message translates to:
  /// **'My Day vazio. Adicione tarefas ao foco do dia!'**
  String get emptyMyDay;

  /// No description provided for @addExistingTask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa existente'**
  String get addExistingTask;

  /// No description provided for @priorityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get priorityLabel;

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

  /// No description provided for @reminderLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get reminderLabel;

  /// No description provided for @noDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem prazo'**
  String get noDueDate;

  /// No description provided for @noReminder.
  ///
  /// In pt, this message translates to:
  /// **'Sem lembrete'**
  String get noReminder;

  /// No description provided for @pickDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Definir prazo'**
  String get pickDueDate;

  /// No description provided for @pickReminder.
  ///
  /// In pt, this message translates to:
  /// **'Definir lembrete'**
  String get pickReminder;

  /// No description provided for @clearDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Remover prazo'**
  String get clearDueDate;

  /// No description provided for @clearReminder.
  ///
  /// In pt, this message translates to:
  /// **'Remover lembrete'**
  String get clearReminder;

  /// No description provided for @recurrenceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Repetição'**
  String get recurrenceLabel;

  /// No description provided for @recurrenceNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem repetição'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diária'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekdays.
  ///
  /// In pt, this message translates to:
  /// **'Dias úteis'**
  String get recurrenceWeekdays;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get recurrenceYearly;

  /// No description provided for @reminderInPast.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um horário futuro para o lembrete.'**
  String get reminderInPast;

  /// No description provided for @recurrenceRequiresDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Defina um prazo antes de ativar a repetição.'**
  String get recurrenceRequiresDueDate;

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar tarefas'**
  String get searchHint;

  /// No description provided for @filtersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get filtersTitle;

  /// No description provided for @clearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get clearFilters;

  /// No description provided for @filterActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativas'**
  String get filterActive;

  /// No description provided for @filterCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas'**
  String get filterCompleted;

  /// No description provided for @dueOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get dueOverdue;

  /// No description provided for @dueToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get dueToday;

  /// No description provided for @dueNext7.
  ///
  /// In pt, this message translates to:
  /// **'Próximos 7 dias'**
  String get dueNext7;

  /// No description provided for @dueCustom.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo personalizado'**
  String get dueCustom;

  /// No description provided for @dueFrom.
  ///
  /// In pt, this message translates to:
  /// **'De'**
  String get dueFrom;

  /// No description provided for @dueTo.
  ///
  /// In pt, this message translates to:
  /// **'Até'**
  String get dueTo;

  /// No description provided for @reminderWith.
  ///
  /// In pt, this message translates to:
  /// **'Com lembrete'**
  String get reminderWith;

  /// No description provided for @reminderWithout.
  ///
  /// In pt, this message translates to:
  /// **'Sem lembrete'**
  String get reminderWithout;

  /// No description provided for @recurrenceWithActive.
  ///
  /// In pt, this message translates to:
  /// **'Com recorrência'**
  String get recurrenceWithActive;

  /// No description provided for @recurrenceWithout.
  ///
  /// In pt, this message translates to:
  /// **'Sem recorrência'**
  String get recurrenceWithout;

  /// No description provided for @recurrenceCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Recorrência cancelada'**
  String get recurrenceCanceled;

  /// No description provided for @noTags.
  ///
  /// In pt, this message translates to:
  /// **'Sem tags'**
  String get noTags;

  /// No description provided for @emptySearch.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado encontrado.'**
  String get emptySearch;

  /// No description provided for @statusSection.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get statusSection;

  /// No description provided for @dueSection.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get dueSection;

  /// No description provided for @reminderSection.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get reminderSection;

  /// No description provided for @recurrenceSection.
  ///
  /// In pt, this message translates to:
  /// **'Recorrência'**
  String get recurrenceSection;

  /// No description provided for @listsSectionFilter.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get listsSectionFilter;

  /// No description provided for @groupsSectionFilter.
  ///
  /// In pt, this message translates to:
  /// **'Grupos'**
  String get groupsSectionFilter;

  /// No description provided for @categoriesSectionFilter.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get categoriesSectionFilter;

  /// No description provided for @tagsSectionFilter.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get tagsSectionFilter;

  /// No description provided for @prioritySection.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get prioritySection;

  /// No description provided for @dataSection.
  ///
  /// In pt, this message translates to:
  /// **'Dados'**
  String get dataSection;

  /// No description provided for @exportJson.
  ///
  /// In pt, this message translates to:
  /// **'Exportar JSON'**
  String get exportJson;

  /// No description provided for @importJson.
  ///
  /// In pt, this message translates to:
  /// **'Importar JSON'**
  String get importJson;

  /// No description provided for @createBackup.
  ///
  /// In pt, this message translates to:
  /// **'Criar backup'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar backup'**
  String get restoreBackup;

  /// No description provided for @exportJsonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar formato aberto'**
  String get exportJsonTitle;

  /// No description provided for @exportJsonWarning.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo JSON não é criptografado e contém dados pessoais, como notas e lembretes. Deseja continuar?'**
  String get exportJsonWarning;

  /// No description provided for @backupPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Senha do backup'**
  String get backupPasswordTitle;

  /// No description provided for @backupPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get backupPasswordLabel;

  /// No description provided for @backupPasswordConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get backupPasswordConfirm;

  /// No description provided for @backupLostPasswordWarning.
  ///
  /// In pt, this message translates to:
  /// **'Se a senha for perdida, o backup não poderá ser recuperado. Não existe recuperação por conta ou servidor.'**
  String get backupLostPasswordWarning;

  /// No description provided for @passwordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get passwordMismatch;

  /// No description provided for @passwordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a senha.'**
  String get passwordRequired;

  /// No description provided for @backupCreated.
  ///
  /// In pt, this message translates to:
  /// **'Backup criado com sucesso.'**
  String get backupCreated;

  /// No description provided for @exportDone.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo exportado com sucesso.'**
  String get exportDone;

  /// No description provided for @replaceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Substituir todos os dados?'**
  String get replaceTitle;

  /// No description provided for @replaceWarning.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados atuais serão substituídos integralmente pelos dados do arquivo. Esta ação não pode ser desfeita.'**
  String get replaceWarning;

  /// No description provided for @confirmReplace.
  ///
  /// In pt, this message translates to:
  /// **'Substituir'**
  String get confirmReplace;

  /// No description provided for @summaryTypeBackup.
  ///
  /// In pt, this message translates to:
  /// **'Backup criptografado'**
  String get summaryTypeBackup;

  /// No description provided for @summaryTypeJson.
  ///
  /// In pt, this message translates to:
  /// **'JSON aberto'**
  String get summaryTypeJson;

  /// No description provided for @summaryExportedAt.
  ///
  /// In pt, this message translates to:
  /// **'Exportado em'**
  String get summaryExportedAt;

  /// No description provided for @summaryActiveTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas ativas'**
  String get summaryActiveTasks;

  /// No description provided for @summaryCompletedTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas concluídas'**
  String get summaryCompletedTasks;

  /// No description provided for @summaryTrashedTasks.
  ///
  /// In pt, this message translates to:
  /// **'Na lixeira'**
  String get summaryTrashedTasks;

  /// No description provided for @summarySubtasks.
  ///
  /// In pt, this message translates to:
  /// **'Subtarefas'**
  String get summarySubtasks;

  /// No description provided for @summarySeries.
  ///
  /// In pt, this message translates to:
  /// **'Séries recorrentes'**
  String get summarySeries;

  /// No description provided for @summaryMyDay.
  ///
  /// In pt, this message translates to:
  /// **'Entradas do My Day'**
  String get summaryMyDay;

  /// No description provided for @invalidPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha incorreta ou arquivo corrompido.'**
  String get invalidPassword;

  /// No description provided for @invalidFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo inválido.'**
  String get invalidFile;

  /// No description provided for @unsupportedVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão do arquivo não suportada.'**
  String get unsupportedVersion;

  /// No description provided for @importDone.
  ///
  /// In pt, this message translates to:
  /// **'Dados substituídos com sucesso.'**
  String get importDone;

  /// No description provided for @operationCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Operação cancelada.'**
  String get operationCancelled;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Automático (sistema)'**
  String get languageSystem;

  /// No description provided for @languagePt.
  ///
  /// In pt, this message translates to:
  /// **'Português (Brasil)'**
  String get languagePt;

  /// No description provided for @languageEn.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageEs.
  ///
  /// In pt, this message translates to:
  /// **'Español'**
  String get languageEs;

  /// No description provided for @languageUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Idioma atualizado.'**
  String get languageUpdated;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @reminderStateScheduled.
  ///
  /// In pt, this message translates to:
  /// **'Agendado'**
  String get reminderStateScheduled;

  /// No description provided for @reminderStatePermission.
  ///
  /// In pt, this message translates to:
  /// **'Permissão necessária'**
  String get reminderStatePermission;

  /// No description provided for @reminderStateUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível nesta plataforma'**
  String get reminderStateUnavailable;

  /// No description provided for @reminderStateExpired.
  ///
  /// In pt, this message translates to:
  /// **'Vencido'**
  String get reminderStateExpired;

  /// No description provided for @reminderStatePending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente de verificação'**
  String get reminderStatePending;

  /// No description provided for @reminderPermissionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Permitir avisos'**
  String get reminderPermissionTitle;

  /// No description provided for @reminderPermissionMessage.
  ///
  /// In pt, this message translates to:
  /// **'Para exibir lembretes, o aplicativo precisa da autorização do sistema. Você pode recusar: o lembrete continuará salvo, mas sem avisos.'**
  String get reminderPermissionMessage;

  /// No description provided for @reminderPermissionConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get reminderPermissionConfirm;

  /// No description provided for @reminderNotificationsDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Avisos desativados. Ative a permissão nas configurações do sistema ou navegador.'**
  String get reminderNotificationsDisabled;

  /// No description provided for @openTask.
  ///
  /// In pt, this message translates to:
  /// **'Abrir tarefa'**
  String get openTask;
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
