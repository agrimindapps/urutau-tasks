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
}
