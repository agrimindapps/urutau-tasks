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
  String get allTasks => 'Todas as tarefas';

  @override
  String get completedTasks => 'Concluídas';

  @override
  String get trash => 'Lixeira';

  @override
  String get newTask => 'Nova tarefa';

  @override
  String get newSubtask => 'Nova etapa';

  @override
  String get taskTitle => 'Título da tarefa';

  @override
  String get subtaskTitle => 'Título da etapa';

  @override
  String get taskTitleRequired => 'Informe um título.';

  @override
  String get add => 'Adicionar';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get editTask => 'Editar tarefa';

  @override
  String get editSubtask => 'Editar etapa';

  @override
  String get taskDetails => 'Detalhes da tarefa';

  @override
  String get subtasks => 'Etapas';

  @override
  String taskProgress(int completed, int total) {
    return '$completed/$total etapas concluídas';
  }

  @override
  String get noSubtasks => 'Nenhuma etapa por enquanto.';

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String get noActiveTasks =>
      'Nada por aqui ainda. Adicione uma tarefa para começar.';

  @override
  String get noCompletedTasks => 'Ainda não há tarefas concluídas.';

  @override
  String get trashEmpty => 'A lixeira está vazia.';

  @override
  String get markComplete => 'Marcar como concluída';

  @override
  String get reopenTask => 'Reabrir tarefa';

  @override
  String get moveToTrash => 'Mover para a lixeira';

  @override
  String get restore => 'Restaurar';

  @override
  String get removeSubtask => 'Remover etapa';

  @override
  String get removeSubtaskConfirmation =>
      'Esta etapa será removida permanentemente.';

  @override
  String get remove => 'Remover';

  @override
  String get close => 'Fechar';

  @override
  String get loading => 'Carregando…';

  @override
  String get unableToLoadTasks => 'Não foi possível carregar as tarefas.';

  @override
  String get unableToLoadTask => 'Não foi possível carregar esta tarefa.';

  @override
  String get taskNotFound => 'Esta tarefa não está mais disponível.';

  @override
  String get actionFailed =>
      'Não foi possível salvar a alteração. Tente novamente.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get manageOrganization => 'Organizar';

  @override
  String get lists => 'Listas';

  @override
  String get groups => 'Grupos';

  @override
  String get categories => 'Categorias';

  @override
  String get tags => 'Tags';

  @override
  String get newList => 'Nova lista';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String get newCategory => 'Nova categoria';

  @override
  String get newTag => 'Nova tag';

  @override
  String get listName => 'Nome da lista';

  @override
  String get groupName => 'Nome do grupo';

  @override
  String get categoryName => 'Nome da categoria';

  @override
  String get tagName => 'Nome da tag';

  @override
  String get editList => 'Editar lista';

  @override
  String get editGroup => 'Editar grupo';

  @override
  String get editCategory => 'Editar categoria';

  @override
  String get editTag => 'Editar tag';

  @override
  String get deleteList => 'Excluir lista';

  @override
  String get deleteGroup => 'Excluir grupo';

  @override
  String get deleteCategory => 'Excluir categoria';

  @override
  String get deleteTag => 'Excluir tag';

  @override
  String get delete => 'Excluir';

  @override
  String get confirm => 'Confirmar';

  @override
  String get noLists => 'Nenhuma lista por enquanto.';

  @override
  String get noGroups => 'Nenhum grupo por enquanto.';

  @override
  String get noCategories => 'Nenhuma categoria por enquanto.';

  @override
  String get noTags => 'Nenhuma tag por enquanto.';

  @override
  String get selectGroup => 'Escolha um grupo';

  @override
  String get noGroup => 'Sem grupo';

  @override
  String get moveToGroup => 'Alterar grupo';

  @override
  String get selectDestinationList => 'Escolha uma lista de destino';

  @override
  String get deleteListNeedsDestination =>
      'Esta lista tem tarefas. Escolha outra lista para recebê-las.';

  @override
  String get deleteListConfirmation =>
      'As tarefas e etapas serão movidas para a lista escolhida.';

  @override
  String get deleteGroupConfirmation =>
      'As listas serão mantidas e ficarão sem grupo.';

  @override
  String get deleteCategoryConfirmation =>
      'As tarefas manterão os outros dados e ficarão sem esta categoria.';

  @override
  String get deleteTagConfirmation =>
      'Esta tag será removida das tarefas associadas.';

  @override
  String get duplicateName => 'Já existe um item com este nome.';

  @override
  String get taskList => 'Lista';

  @override
  String get taskCategory => 'Categoria';

  @override
  String get taskTags => 'Tags';

  @override
  String get noList => 'Sem lista';

  @override
  String get noCategory => 'Sem categoria';

  @override
  String get priority => 'Prioridade';

  @override
  String get noPriority => 'Sem prioridade';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get notes => 'Notas';

  @override
  String get editNotes => 'Editar notas';

  @override
  String get noNotes => 'Nenhuma nota por enquanto.';

  @override
  String get dueDate => 'Prazo';

  @override
  String get noDueDate => 'Sem prazo';

  @override
  String get chooseDueDate => 'Definir prazo';

  @override
  String get removeDueDate => 'Remover prazo';

  @override
  String get reminder => 'Lembrete';

  @override
  String get noReminder => 'Sem lembrete';

  @override
  String get chooseReminder => 'Definir lembrete';

  @override
  String get removeReminder => 'Remover lembrete';

  @override
  String get reminderInPast =>
      'Escolha uma data e horário futuros para o lembrete.';

  @override
  String get reminderDeliveryScheduled =>
      'O lembrete está configurado. A entrega depende da plataforma e das configurações de notificação.';

  @override
  String get reminderPermissionNeeded =>
      'As notificações do sistema estão desativadas. O lembrete foi salvo; ative as notificações para receber avisos do sistema.';

  @override
  String get reminderCancellationPending =>
      'Não foi possível confirmar o cancelamento de um aviso anterior do sistema; ele ainda pode aparecer. O app tentará novamente.';

  @override
  String get webNotificationSettingsHelp =>
      'Se o navegador bloqueou o pedido, permita notificações nas configurações deste site e depois verifique novamente.';

  @override
  String get checkNotificationPermission => 'Verificar novamente';

  @override
  String get reminderUnavailable =>
      'As notificações do sistema não estão disponíveis aqui. Mantenha o app aberto para receber avisos quando possível.';

  @override
  String get reminderExpired =>
      'O horário do lembrete já passou. Nenhum aviso atrasado será enviado.';

  @override
  String get reminderPending =>
      'Verificando a disponibilidade das notificações…';

  @override
  String get reminderPaused =>
      'O lembrete foi salvo e está pausado enquanto a tarefa estiver concluída ou na lixeira.';

  @override
  String get reminderPermissionRationale =>
      'Os lembretes usam notificações locais. A entrega depende da permissão do sistema ou navegador e pode variar por plataforma. Na Web, o navegador pode pedir permissão agora; se você cancelar a seleção de data ou hora, nenhum lembrete será salvo.';

  @override
  String get openTask => 'Abrir tarefa';

  @override
  String get notificationChannelName => 'Lembretes de tarefas';

  @override
  String get notificationChannelDescription =>
      'Notificações de lembretes de tarefas';

  @override
  String get openNotificationSettings => 'Ativar notificações do sistema';

  @override
  String get notNow => 'Agora não';

  @override
  String get myDay => 'Meu Dia';

  @override
  String get importantTasks => 'Importantes';

  @override
  String get plannedTasks => 'Planejadas';

  @override
  String get addToMyDay => 'Adicionar ao Meu Dia';

  @override
  String get removeFromMyDay => 'Remover do Meu Dia';

  @override
  String get myDayEmpty => 'Adicione tarefas aqui para focar no dia de hoje.';

  @override
  String get noImportantTasks => 'Não há tarefas importantes no momento.';

  @override
  String get noPlannedTasks => 'Não há tarefas planejadas no momento.';

  @override
  String get recurrence => 'Recorrência';

  @override
  String get noRecurrence => 'Não se repete';

  @override
  String get recurrenceDaily => 'Diária';

  @override
  String get recurrenceWeekdays => 'Em dias úteis';

  @override
  String get recurrenceWeekly => 'Semanal';

  @override
  String get recurrenceMonthly => 'Mensal';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get recurrenceCancelled => 'Esta recorrência foi cancelada.';

  @override
  String get recurrenceNeedsDueDate =>
      'Defina um prazo antes de configurar a recorrência.';

  @override
  String get recurrenceHelp =>
      'Com a recorrência ativa, concluir esta tarefa a mantém no histórico e cria a próxima ocorrência. As etapas não são copiadas.';

  @override
  String get recurrenceHistoryReadOnly =>
      'Já existe uma ocorrência posterior. Edite a ocorrência mais recente para alterar a série.';

  @override
  String get searchTasks => 'Buscar tarefas';

  @override
  String get searchHint => 'Buscar em títulos, notas e etapas';

  @override
  String get clearSearch => 'Limpar busca';

  @override
  String get searchMatchInNotes => 'Correspondência nas notas';

  @override
  String get searchMatchInSteps => 'Correspondência em uma etapa';

  @override
  String get searchMatchInTitle => 'Correspondência no título';

  @override
  String get noSearchResults =>
      'Nenhuma tarefa corresponde à busca e aos filtros.';

  @override
  String get filters => 'Filtros';

  @override
  String get clearFilters => 'Limpar filtros';

  @override
  String get apply => 'Aplicar';

  @override
  String get status => 'Status';

  @override
  String get activeTasks => 'Ativas';

  @override
  String get overdue => 'Atrasadas';

  @override
  String get dueToday => 'Para hoje';

  @override
  String get nextSevenDays => 'Próximos 7 dias';

  @override
  String get customDateRange => 'Intervalo personalizado';

  @override
  String get withReminder => 'Com lembrete';

  @override
  String get withoutReminder => 'Sem lembrete';

  @override
  String get withRecurrence => 'Com recorrência ativa';

  @override
  String get withoutRecurrence => 'Sem recorrência';

  @override
  String get cancelledRecurrence => 'Recorrência cancelada';

  @override
  String get chooseDate => 'Escolher datas';

  @override
  String get dateRangeRequired =>
      'Escolha as datas inicial e final antes de aplicar este filtro.';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma da interface';

  @override
  String get languagePreferenceHelp =>
      'Escolha o idioma dos textos do aplicativo. Datas e números continuam seguindo a região do dispositivo.';

  @override
  String get automaticSystem => 'Automático (sistema)';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get backupAndPortability => 'Dados e portabilidade';

  @override
  String get backupAndPortabilityDescription =>
      'Crie um backup protegido por senha, exporte JSON legível ou substitua os dados locais por um arquivo compatível.';

  @override
  String get preparingEncryptedBackup =>
      'Criptografando e preparando o backup…';

  @override
  String get preparingJsonExport => 'Preparando a exportação JSON…';

  @override
  String get preparingDataRestore => 'Validando e preparando a restauração…';

  @override
  String get createBackup => 'Criar backup criptografado';

  @override
  String get encryptedBackupDescription =>
      'Um backup completo protegido pela senha que você escolher.';

  @override
  String get exportOpenJson => 'Exportar JSON aberto';

  @override
  String get unencryptedJsonDescription =>
      'Um arquivo legível e sem criptografia com os dados das tarefas.';

  @override
  String get importOrRestore => 'Importar ou restaurar';

  @override
  String get encryptedBackupWarning =>
      'O backup será protegido por esta senha. Se você perdê-la, não será possível recuperá-lo.';

  @override
  String get unencryptedExportWarning =>
      'Este JSON não é criptografado. Ele é legível e contém dados pessoais, como notas e lembretes.';

  @override
  String get importReplaceWarning =>
      'A importação ou restauração substitui todos os dados locais depois que você revisar e confirmar o arquivo.';

  @override
  String get backupExportDone => 'Backup criptografado salvo.';

  @override
  String get jsonExportDone => 'Arquivo JSON salvo.';

  @override
  String get dataImportDone =>
      'Os dados locais foram substituídos pelo arquivo.';

  @override
  String get chooseExportDestination => 'Escolha onde salvar o arquivo';

  @override
  String get restoreBackup => 'Restaurar backup';

  @override
  String get backupPasswordRequired =>
      'Informe a senha usada quando este backup foi criado.';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar senha';

  @override
  String get emptyPassword => 'Informe uma senha.';

  @override
  String get passwordMismatch => 'As senhas não correspondem.';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get importPreview => 'Revise os dados';

  @override
  String get exportDate => 'Exportado em';

  @override
  String get openJsonFile => 'Arquivo JSON aberto';

  @override
  String get encryptedBackupFile => 'Backup criptografado';

  @override
  String get replaceLocalData => 'Substituir dados locais';

  @override
  String get wrongPasswordOrCorrupt =>
      'A senha está incorreta ou o backup está danificado.';

  @override
  String get invalidImportFile =>
      'O arquivo é inválido ou contém dados inconsistentes.';

  @override
  String get incompatibleFile => 'Esta versão do arquivo não é compatível.';

  @override
  String get databaseFromNewerVersion =>
      'Estes dados foram criados por uma versão mais recente do Urutau Tasks. Atualize o app para abri-los; os dados foram preservados.';

  @override
  String get databaseMigrationFailed =>
      'Não foi possível atualizar o banco de dados local. O app não pôde continuar para proteger seus dados.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'Urutau Tasks';

  @override
  String get allTasks => 'Todas as tarefas';

  @override
  String get completedTasks => 'Concluídas';

  @override
  String get trash => 'Lixeira';

  @override
  String get newTask => 'Nova tarefa';

  @override
  String get newSubtask => 'Nova etapa';

  @override
  String get taskTitle => 'Título da tarefa';

  @override
  String get subtaskTitle => 'Título da etapa';

  @override
  String get taskTitleRequired => 'Informe um título.';

  @override
  String get add => 'Adicionar';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get editTask => 'Editar tarefa';

  @override
  String get editSubtask => 'Editar etapa';

  @override
  String get taskDetails => 'Detalhes da tarefa';

  @override
  String get subtasks => 'Etapas';

  @override
  String taskProgress(int completed, int total) {
    return '$completed/$total etapas concluídas';
  }

  @override
  String get noSubtasks => 'Nenhuma etapa por enquanto.';

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String get noActiveTasks =>
      'Nada por aqui ainda. Adicione uma tarefa para começar.';

  @override
  String get noCompletedTasks => 'Ainda não há tarefas concluídas.';

  @override
  String get trashEmpty => 'A lixeira está vazia.';

  @override
  String get markComplete => 'Marcar como concluída';

  @override
  String get reopenTask => 'Reabrir tarefa';

  @override
  String get moveToTrash => 'Mover para a lixeira';

  @override
  String get restore => 'Restaurar';

  @override
  String get removeSubtask => 'Remover etapa';

  @override
  String get removeSubtaskConfirmation =>
      'Esta etapa será removida permanentemente.';

  @override
  String get remove => 'Remover';

  @override
  String get close => 'Fechar';

  @override
  String get loading => 'Carregando…';

  @override
  String get unableToLoadTasks => 'Não foi possível carregar as tarefas.';

  @override
  String get unableToLoadTask => 'Não foi possível carregar esta tarefa.';

  @override
  String get taskNotFound => 'Esta tarefa não está mais disponível.';

  @override
  String get actionFailed =>
      'Não foi possível salvar a alteração. Tente novamente.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get manageOrganization => 'Organizar';

  @override
  String get lists => 'Listas';

  @override
  String get groups => 'Grupos';

  @override
  String get categories => 'Categorias';

  @override
  String get tags => 'Tags';

  @override
  String get newList => 'Nova lista';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String get newCategory => 'Nova categoria';

  @override
  String get newTag => 'Nova tag';

  @override
  String get listName => 'Nome da lista';

  @override
  String get groupName => 'Nome do grupo';

  @override
  String get categoryName => 'Nome da categoria';

  @override
  String get tagName => 'Nome da tag';

  @override
  String get editList => 'Editar lista';

  @override
  String get editGroup => 'Editar grupo';

  @override
  String get editCategory => 'Editar categoria';

  @override
  String get editTag => 'Editar tag';

  @override
  String get deleteList => 'Excluir lista';

  @override
  String get deleteGroup => 'Excluir grupo';

  @override
  String get deleteCategory => 'Excluir categoria';

  @override
  String get deleteTag => 'Excluir tag';

  @override
  String get delete => 'Excluir';

  @override
  String get confirm => 'Confirmar';

  @override
  String get noLists => 'Nenhuma lista por enquanto.';

  @override
  String get noGroups => 'Nenhum grupo por enquanto.';

  @override
  String get noCategories => 'Nenhuma categoria por enquanto.';

  @override
  String get noTags => 'Nenhuma tag por enquanto.';

  @override
  String get selectGroup => 'Escolha um grupo';

  @override
  String get noGroup => 'Sem grupo';

  @override
  String get moveToGroup => 'Alterar grupo';

  @override
  String get selectDestinationList => 'Escolha uma lista de destino';

  @override
  String get deleteListNeedsDestination =>
      'Esta lista tem tarefas. Escolha outra lista para recebê-las.';

  @override
  String get deleteListConfirmation =>
      'As tarefas e etapas serão movidas para a lista escolhida.';

  @override
  String get deleteGroupConfirmation =>
      'As listas serão mantidas e ficarão sem grupo.';

  @override
  String get deleteCategoryConfirmation =>
      'As tarefas manterão os outros dados e ficarão sem esta categoria.';

  @override
  String get deleteTagConfirmation =>
      'Esta tag será removida das tarefas associadas.';

  @override
  String get duplicateName => 'Já existe um item com este nome.';

  @override
  String get taskList => 'Lista';

  @override
  String get taskCategory => 'Categoria';

  @override
  String get taskTags => 'Tags';

  @override
  String get noList => 'Sem lista';

  @override
  String get noCategory => 'Sem categoria';

  @override
  String get priority => 'Prioridade';

  @override
  String get noPriority => 'Sem prioridade';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get notes => 'Notas';

  @override
  String get editNotes => 'Editar notas';

  @override
  String get noNotes => 'Nenhuma nota por enquanto.';

  @override
  String get dueDate => 'Prazo';

  @override
  String get noDueDate => 'Sem prazo';

  @override
  String get chooseDueDate => 'Definir prazo';

  @override
  String get removeDueDate => 'Remover prazo';

  @override
  String get reminder => 'Lembrete';

  @override
  String get noReminder => 'Sem lembrete';

  @override
  String get chooseReminder => 'Definir lembrete';

  @override
  String get removeReminder => 'Remover lembrete';

  @override
  String get reminderInPast =>
      'Escolha uma data e horário futuros para o lembrete.';

  @override
  String get reminderDeliveryScheduled =>
      'O lembrete está configurado. A entrega depende da plataforma e das configurações de notificação.';

  @override
  String get reminderPermissionNeeded =>
      'As notificações do sistema estão desativadas. O lembrete foi salvo; ative as notificações para receber avisos do sistema.';

  @override
  String get reminderCancellationPending =>
      'Não foi possível confirmar o cancelamento de um aviso anterior do sistema; ele ainda pode aparecer. O app tentará novamente.';

  @override
  String get webNotificationSettingsHelp =>
      'Se o navegador bloqueou o pedido, permita notificações nas configurações deste site e depois verifique novamente.';

  @override
  String get checkNotificationPermission => 'Verificar novamente';

  @override
  String get reminderUnavailable =>
      'As notificações do sistema não estão disponíveis aqui. Mantenha o app aberto para receber avisos quando possível.';

  @override
  String get reminderExpired =>
      'O horário do lembrete já passou. Nenhum aviso atrasado será enviado.';

  @override
  String get reminderPending =>
      'Verificando a disponibilidade das notificações…';

  @override
  String get reminderPaused =>
      'O lembrete foi salvo e está pausado enquanto a tarefa estiver concluída ou na lixeira.';

  @override
  String get reminderPermissionRationale =>
      'Os lembretes usam notificações locais. A entrega depende da permissão do sistema ou navegador e pode variar por plataforma. Na Web, o navegador pode pedir permissão agora; se você cancelar a seleção de data ou hora, nenhum lembrete será salvo.';

  @override
  String get openTask => 'Abrir tarefa';

  @override
  String get notificationChannelName => 'Lembretes de tarefas';

  @override
  String get notificationChannelDescription =>
      'Notificações de lembretes de tarefas';

  @override
  String get openNotificationSettings => 'Ativar notificações do sistema';

  @override
  String get notNow => 'Agora não';

  @override
  String get myDay => 'Meu Dia';

  @override
  String get importantTasks => 'Importantes';

  @override
  String get plannedTasks => 'Planejadas';

  @override
  String get addToMyDay => 'Adicionar ao Meu Dia';

  @override
  String get removeFromMyDay => 'Remover do Meu Dia';

  @override
  String get myDayEmpty => 'Adicione tarefas aqui para focar no dia de hoje.';

  @override
  String get noImportantTasks => 'Não há tarefas importantes no momento.';

  @override
  String get noPlannedTasks => 'Não há tarefas planejadas no momento.';

  @override
  String get recurrence => 'Recorrência';

  @override
  String get noRecurrence => 'Não se repete';

  @override
  String get recurrenceDaily => 'Diária';

  @override
  String get recurrenceWeekdays => 'Em dias úteis';

  @override
  String get recurrenceWeekly => 'Semanal';

  @override
  String get recurrenceMonthly => 'Mensal';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get recurrenceCancelled => 'Esta recorrência foi cancelada.';

  @override
  String get recurrenceNeedsDueDate =>
      'Defina um prazo antes de configurar a recorrência.';

  @override
  String get recurrenceHelp =>
      'Com a recorrência ativa, concluir esta tarefa a mantém no histórico e cria a próxima ocorrência. As etapas não são copiadas.';

  @override
  String get recurrenceHistoryReadOnly =>
      'Já existe uma ocorrência posterior. Edite a ocorrência mais recente para alterar a série.';

  @override
  String get searchTasks => 'Buscar tarefas';

  @override
  String get searchHint => 'Buscar em títulos, notas e etapas';

  @override
  String get clearSearch => 'Limpar busca';

  @override
  String get searchMatchInNotes => 'Correspondência nas notas';

  @override
  String get searchMatchInSteps => 'Correspondência em uma etapa';

  @override
  String get searchMatchInTitle => 'Correspondência no título';

  @override
  String get noSearchResults =>
      'Nenhuma tarefa corresponde à busca e aos filtros.';

  @override
  String get filters => 'Filtros';

  @override
  String get clearFilters => 'Limpar filtros';

  @override
  String get apply => 'Aplicar';

  @override
  String get status => 'Status';

  @override
  String get activeTasks => 'Ativas';

  @override
  String get overdue => 'Atrasadas';

  @override
  String get dueToday => 'Para hoje';

  @override
  String get nextSevenDays => 'Próximos 7 dias';

  @override
  String get customDateRange => 'Intervalo personalizado';

  @override
  String get withReminder => 'Com lembrete';

  @override
  String get withoutReminder => 'Sem lembrete';

  @override
  String get withRecurrence => 'Com recorrência ativa';

  @override
  String get withoutRecurrence => 'Sem recorrência';

  @override
  String get cancelledRecurrence => 'Recorrência cancelada';

  @override
  String get chooseDate => 'Escolher datas';

  @override
  String get dateRangeRequired =>
      'Escolha as datas inicial e final antes de aplicar este filtro.';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma da interface';

  @override
  String get languagePreferenceHelp =>
      'Escolha o idioma dos textos do aplicativo. Datas e números continuam seguindo a região do dispositivo.';

  @override
  String get automaticSystem => 'Automático (sistema)';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get backupAndPortability => 'Dados e portabilidade';

  @override
  String get backupAndPortabilityDescription =>
      'Crie um backup protegido por senha, exporte JSON legível ou substitua os dados locais por um arquivo compatível.';

  @override
  String get preparingEncryptedBackup =>
      'Criptografando e preparando o backup…';

  @override
  String get preparingJsonExport => 'Preparando a exportação JSON…';

  @override
  String get preparingDataRestore => 'Validando e preparando a restauração…';

  @override
  String get createBackup => 'Criar backup criptografado';

  @override
  String get encryptedBackupDescription =>
      'Um backup completo protegido pela senha que você escolher.';

  @override
  String get exportOpenJson => 'Exportar JSON aberto';

  @override
  String get unencryptedJsonDescription =>
      'Um arquivo legível e sem criptografia com os dados das tarefas.';

  @override
  String get importOrRestore => 'Importar ou restaurar';

  @override
  String get encryptedBackupWarning =>
      'O backup será protegido por esta senha. Se você perdê-la, não será possível recuperá-lo.';

  @override
  String get unencryptedExportWarning =>
      'Este JSON não é criptografado. Ele é legível e contém dados pessoais, como notas e lembretes.';

  @override
  String get importReplaceWarning =>
      'A importação ou restauração substitui todos os dados locais depois que você revisar e confirmar o arquivo.';

  @override
  String get backupExportDone => 'Backup criptografado salvo.';

  @override
  String get jsonExportDone => 'Arquivo JSON salvo.';

  @override
  String get dataImportDone =>
      'Os dados locais foram substituídos pelo arquivo.';

  @override
  String get chooseExportDestination => 'Escolha onde salvar o arquivo';

  @override
  String get restoreBackup => 'Restaurar backup';

  @override
  String get backupPasswordRequired =>
      'Informe a senha usada quando este backup foi criado.';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar senha';

  @override
  String get emptyPassword => 'Informe uma senha.';

  @override
  String get passwordMismatch => 'As senhas não correspondem.';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get importPreview => 'Revise os dados';

  @override
  String get exportDate => 'Exportado em';

  @override
  String get openJsonFile => 'Arquivo JSON aberto';

  @override
  String get encryptedBackupFile => 'Backup criptografado';

  @override
  String get replaceLocalData => 'Substituir dados locais';

  @override
  String get wrongPasswordOrCorrupt =>
      'A senha está incorreta ou o backup está danificado.';

  @override
  String get invalidImportFile =>
      'O arquivo é inválido ou contém dados inconsistentes.';

  @override
  String get incompatibleFile => 'Esta versão do arquivo não é compatível.';

  @override
  String get databaseFromNewerVersion =>
      'Estes dados foram criados por uma versão mais recente do Urutau Tasks. Atualize o app para abri-los; os dados foram preservados.';

  @override
  String get databaseMigrationFailed =>
      'Não foi possível atualizar o banco de dados local. O app não pôde continuar para proteger seus dados.';
}
