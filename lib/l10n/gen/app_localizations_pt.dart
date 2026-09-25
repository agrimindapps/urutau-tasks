// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Urutau Tasks';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navTrash => 'Lixeira';

  @override
  String get newTaskTooltip => 'Nova tarefa';

  @override
  String get editTaskTitle => 'Editar tarefa';

  @override
  String get createTaskTitle => 'Nova tarefa';

  @override
  String get taskTitleLabel => 'Título';

  @override
  String get taskNotesLabel => 'Notas';

  @override
  String get taskTitleHint => 'O que precisa ser feito?';

  @override
  String get taskNotesHint => 'Detalhes (opcional)';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get complete => 'Concluir';

  @override
  String get reopen => 'Reabrir';

  @override
  String get restore => 'Restaurar';

  @override
  String get deleteTaskTitle => 'Excluir tarefa?';

  @override
  String get deleteTaskMessage =>
      'A tarefa e suas etapas irão para a lixeira. Você pode restaurá-las depois.';

  @override
  String get emptyTasks => 'Nenhuma tarefa ainda. Crie a primeira!';

  @override
  String get emptyTrash => 'A lixeira está vazia.';

  @override
  String get trashSubtitle =>
      'Tarefas excluídas ficam aqui até serem restauradas.';

  @override
  String get errorTitleRequired => 'O título não pode ficar vazio.';

  @override
  String get errorEditInTrash => 'Restaure a tarefa para editá-la.';

  @override
  String get subtasksSection => 'Etapas';

  @override
  String get addSubtaskTooltip => 'Adicionar etapa';

  @override
  String get subtaskHint => 'Título da etapa';

  @override
  String get removeSubtaskTooltip => 'Remover etapa';

  @override
  String get emptySubtasks => 'Nenhuma etapa adicionada.';

  @override
  String progressOf(int completed, int total) {
    return '$completed de $total';
  }

  @override
  String get taskDetailTitle => 'Detalhes da tarefa';

  @override
  String get errorUnexpected => 'Não foi possível concluir a ação.';

  @override
  String get errorNameRequired => 'O nome não pode ficar vazio.';

  @override
  String get errorDuplicateName => 'Já existe um item com esse nome.';

  @override
  String get errorListNotEmpty =>
      'A lista tem tarefas. Escolha uma lista de destino.';

  @override
  String get errorSameDestination => 'Escolha uma lista de destino diferente.';

  @override
  String get navLists => 'Listas';

  @override
  String get listsTitle => 'Listas e grupos';

  @override
  String get categoriesSection => 'Categorias';

  @override
  String get tagsSection => 'Tags';

  @override
  String get groupsSection => 'Grupos';

  @override
  String get newListTooltip => 'Nova lista';

  @override
  String get newGroupTooltip => 'Novo grupo';

  @override
  String get newCategoryTooltip => 'Nova categoria';

  @override
  String get newTagTooltip => 'Nova tag';

  @override
  String get nameLabel => 'Nome';

  @override
  String get emptyLists => 'Nenhuma lista criada.';

  @override
  String get emptyCategories => 'Nenhuma categoria criada.';

  @override
  String get emptyTags => 'Nenhuma tag criada.';

  @override
  String get deleteListTitle => 'Excluir lista?';

  @override
  String get deleteListEmptyMessage => 'A lista será excluída.';

  @override
  String get deleteListDestinationTitle => 'Escolha a lista de destino';

  @override
  String deleteListDestinationMessage(String name) {
    return 'As tarefas de \"$name\" serão movidas para a lista escolhida, preservando subtarefas e classificações.';
  }

  @override
  String get deleteGroupTitle => 'Excluir grupo?';

  @override
  String get deleteGroupMessage => 'As listas do grupo permanecem, sem grupo.';

  @override
  String get deleteCategoryTitle => 'Excluir categoria?';

  @override
  String get deleteCategoryMessage => 'As tarefas deixam de ter categoria.';

  @override
  String get deleteTagTitle => 'Excluir tag?';

  @override
  String get deleteTagMessage => 'As associações serão removidas das tarefas.';

  @override
  String get semLista => 'Sem lista';

  @override
  String get listLabel => 'Lista';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get noCategory => 'Sem categoria';

  @override
  String get addTagTooltip => 'Adicionar tag';

  @override
  String get removeTagTooltip => 'Remover tag';

  @override
  String get tagHint => 'Nome da tag';

  @override
  String get organizationSection => 'Organização';

  @override
  String tasksCount(int count) {
    return '$count tarefas';
  }

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Descer';

  @override
  String get moveToGroup => 'Mover para grupo';

  @override
  String get semGrupo => 'Sem grupo';

  @override
  String get rename => 'Renomear';

  @override
  String get navMyDay => 'Meu dia';

  @override
  String get myDayTitle => 'Meu dia';

  @override
  String get myDayEmpty => 'Nenhuma tarefa no seu dia ainda.';

  @override
  String get addToMyDay => 'Adicionar ao Meu dia';

  @override
  String get removeFromMyDay => 'Remover do Meu dia';

  @override
  String get addExistingTask => 'Escolher tarefa existente';

  @override
  String get noTasksToAdd => 'Não há tarefas disponíveis para adicionar.';

  @override
  String get viewAll => 'Todas';

  @override
  String get viewImportant => 'Importante';

  @override
  String get viewPlanned => 'Planejado';

  @override
  String get viewCompleted => 'Concluídas';

  @override
  String get priorityLabel => 'Prioridade';

  @override
  String get priorityNone => 'Sem prioridade';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get dueDateLabel => 'Prazo';

  @override
  String get noDueDate => 'Sem prazo';

  @override
  String get clearDueDate => 'Remover prazo';

  @override
  String get emptyView => 'Nada por aqui ainda.';

  @override
  String get recurrenceLabel => 'Recorrência';

  @override
  String get noRecurrence => 'Sem recorrência';

  @override
  String get freqDaily => 'Diária';

  @override
  String get freqWeekdays => 'Dias úteis';

  @override
  String get freqWeekly => 'Semanal';

  @override
  String get freqMonthly => 'Mensal';

  @override
  String get freqAnnual => 'Anual';

  @override
  String get cancelSeries => 'Cancelar recorrência';

  @override
  String get cancelSeriesTitle => 'Cancelar recorrência?';

  @override
  String get cancelSeriesMessage =>
      'Novas ocorrências não serão criadas. O histórico é preservado.';

  @override
  String get seriesCancelledNote => 'Recorrência cancelada.';

  @override
  String get reminderLabel => 'Lembrete';

  @override
  String get noReminder => 'Sem lembrete';

  @override
  String get clearReminder => 'Remover lembrete';

  @override
  String get setReminder => 'Definir lembrete';

  @override
  String get errorReminderPast => 'Escolha um horário no futuro.';

  @override
  String get errorDueDateRequired =>
      'Defina um prazo antes de ativar a recorrência.';
}
