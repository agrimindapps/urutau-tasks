// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Urutau Tasks';

  @override
  String get navTasks => 'Tareas';

  @override
  String get navTrash => 'Papelera';

  @override
  String get newTaskTooltip => 'Nueva tarea';

  @override
  String get editTaskTitle => 'Editar tarea';

  @override
  String get createTaskTitle => 'Nueva tarea';

  @override
  String get taskTitleLabel => 'Título';

  @override
  String get taskNotesLabel => 'Notas';

  @override
  String get taskTitleHint => '¿Qué hay que hacer?';

  @override
  String get taskNotesHint => 'Detalles (opcional)';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get complete => 'Completar';

  @override
  String get reopen => 'Reabrir';

  @override
  String get restore => 'Restaurar';

  @override
  String get deleteTaskTitle => '¿Eliminar tarea?';

  @override
  String get deleteTaskMessage =>
      'La tarea y sus pasos irán a la papelera. Puedes restaurarlos después.';

  @override
  String get emptyTasks => 'Aún no hay tareas. ¡Crea la primera!';

  @override
  String get emptyTrash => 'La papelera está vacía.';

  @override
  String get trashSubtitle =>
      'Las tareas eliminadas permanecen aquí hasta restaurarlas.';

  @override
  String get errorTitleRequired => 'El título no puede estar vacío.';

  @override
  String get errorEditInTrash => 'Restaura la tarea para editarla.';

  @override
  String get subtasksSection => 'Pasos';

  @override
  String get addSubtaskTooltip => 'Añadir paso';

  @override
  String get subtaskHint => 'Título del paso';

  @override
  String get removeSubtaskTooltip => 'Eliminar paso';

  @override
  String get emptySubtasks => 'Ningún paso añadido.';

  @override
  String progressOf(int completed, int total) {
    return '$completed de $total';
  }

  @override
  String get taskDetailTitle => 'Detalles de la tarea';

  @override
  String get errorUnexpected => 'No se pudo completar la acción.';

  @override
  String get errorNameRequired => 'El nombre no puede estar vacío.';

  @override
  String get errorDuplicateName => 'Ya existe un elemento con ese nombre.';

  @override
  String get errorListNotEmpty =>
      'La lista tiene tareas. Elige una lista de destino.';

  @override
  String get errorSameDestination => 'Elige una lista de destino diferente.';

  @override
  String get navLists => 'Listas';

  @override
  String get listsTitle => 'Listas y grupos';

  @override
  String get categoriesSection => 'Categorías';

  @override
  String get tagsSection => 'Etiquetas';

  @override
  String get groupsSection => 'Grupos';

  @override
  String get newListTooltip => 'Nueva lista';

  @override
  String get newGroupTooltip => 'Nuevo grupo';

  @override
  String get newCategoryTooltip => 'Nueva categoría';

  @override
  String get newTagTooltip => 'Nueva etiqueta';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get emptyLists => 'Ninguna lista creada.';

  @override
  String get emptyCategories => 'Ninguna categoría creada.';

  @override
  String get emptyTags => 'Ninguna etiqueta creada.';

  @override
  String get deleteListTitle => '¿Eliminar lista?';

  @override
  String get deleteListEmptyMessage => 'La lista será eliminada.';

  @override
  String get deleteListDestinationTitle => 'Elige la lista de destino';

  @override
  String deleteListDestinationMessage(String name) {
    return 'Las tareas de \"$name\" se moverán a la lista elegida, preservando subtareas y clasificaciones.';
  }

  @override
  String get deleteGroupTitle => '¿Eliminar grupo?';

  @override
  String get deleteGroupMessage =>
      'Las listas del grupo permanecen, sin grupo.';

  @override
  String get deleteCategoryTitle => '¿Eliminar categoría?';

  @override
  String get deleteCategoryMessage => 'Las tareas dejarán de tener categoría.';

  @override
  String get deleteTagTitle => '¿Eliminar etiqueta?';

  @override
  String get deleteTagMessage => 'Las asociaciones se quitarán de las tareas.';

  @override
  String get semLista => 'Sin lista';

  @override
  String get listLabel => 'Lista';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get tagsLabel => 'Etiquetas';

  @override
  String get noCategory => 'Sin categoría';

  @override
  String get addTagTooltip => 'Añadir etiqueta';

  @override
  String get removeTagTooltip => 'Quitar etiqueta';

  @override
  String get tagHint => 'Nombre de la etiqueta';

  @override
  String get organizationSection => 'Organización';

  @override
  String tasksCount(int count) {
    return '$count tareas';
  }

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get moveToGroup => 'Mover a grupo';

  @override
  String get semGrupo => 'Sin grupo';

  @override
  String get rename => 'Renombrar';

  @override
  String get navMyDay => 'Mi día';

  @override
  String get myDayTitle => 'Mi día';

  @override
  String get myDayEmpty => 'Aún no hay tareas en tu día.';

  @override
  String get addToMyDay => 'Añadir a Mi día';

  @override
  String get removeFromMyDay => 'Quitar de Mi día';

  @override
  String get addExistingTask => 'Elegir tarea existente';

  @override
  String get noTasksToAdd => 'No hay tareas disponibles para añadir.';

  @override
  String get viewAll => 'Todas';

  @override
  String get viewImportant => 'Importantes';

  @override
  String get viewPlanned => 'Planificadas';

  @override
  String get viewCompleted => 'Completadas';

  @override
  String get priorityLabel => 'Prioridad';

  @override
  String get priorityNone => 'Sin prioridad';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get dueDateLabel => 'Fecha límite';

  @override
  String get noDueDate => 'Sin fecha límite';

  @override
  String get clearDueDate => 'Quitar fecha límite';

  @override
  String get emptyView => 'Nada aquí todavía.';

  @override
  String get recurrenceLabel => 'Recurrencia';

  @override
  String get noRecurrence => 'Sin recurrencia';

  @override
  String get freqDaily => 'Diaria';

  @override
  String get freqWeekdays => 'Días laborables';

  @override
  String get freqWeekly => 'Semanal';

  @override
  String get freqMonthly => 'Mensual';

  @override
  String get freqAnnual => 'Anual';

  @override
  String get cancelSeries => 'Cancelar recurrencia';

  @override
  String get cancelSeriesTitle => '¿Cancelar recurrencia?';

  @override
  String get cancelSeriesMessage =>
      'No se crearán nuevas ocurrencias. El historial se preserva.';

  @override
  String get seriesCancelledNote => 'Recurrencia cancelada.';

  @override
  String get reminderLabel => 'Recordatorio';

  @override
  String get noReminder => 'Sin recordatorio';

  @override
  String get clearReminder => 'Quitar recordatorio';

  @override
  String get setReminder => 'Definir recordatorio';

  @override
  String get errorReminderPast => 'Elige una hora en el futuro.';

  @override
  String get errorDueDateRequired =>
      'Define una fecha límite antes de activar la recurrencia.';

  @override
  String get navSearch => 'Buscar';

  @override
  String get searchHint => 'Buscar tareas...';

  @override
  String get filtersTooltip => 'Filtros';

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get applyFilters => 'Aplicar';

  @override
  String get noResults => 'Sin resultados.';

  @override
  String get matchTitle => 'en el título';

  @override
  String get matchNotes => 'en las notas';

  @override
  String get matchSubtask => 'en el paso';

  @override
  String get filterStatus => 'Estado';

  @override
  String get filterActive => 'Activas';

  @override
  String get filterCompleted => 'Completadas';

  @override
  String get filterLists => 'Listas';

  @override
  String get filterGroups => 'Grupos';

  @override
  String get filterCategories => 'Categorías';

  @override
  String get filterTags => 'Etiquetas';

  @override
  String get filterPriority => 'Prioridad';

  @override
  String get filterDueDate => 'Fecha límite';

  @override
  String get dueNone => 'Sin fecha límite';

  @override
  String get dueOverdue => 'Atrasadas';

  @override
  String get dueToday => 'Hoy';

  @override
  String get dueNext7 => 'Próximos 7 días';

  @override
  String get dueRange => 'Intervalo personalizado';

  @override
  String get filterReminder => 'Recordatorio';

  @override
  String get reminderAny => 'Cualquiera';

  @override
  String get reminderWith => 'Con recordatorio';

  @override
  String get reminderWithout => 'Sin recordatorio';

  @override
  String get filterRecurrence => 'Recurrencia';

  @override
  String get recurrenceAny => 'Cualquiera';

  @override
  String get recurrenceActive => 'Activa';

  @override
  String get recurrenceCancelled => 'Cancelada';

  @override
  String get recurrenceNone => 'Sin recurrencia';

  @override
  String get noTags => 'Sin etiquetas';

  @override
  String get backupTooltip => 'Copia de seguridad y datos';

  @override
  String get backupTitle => 'Copia de seguridad y datos';

  @override
  String get exportBackup => 'Exportar copia cifrada';

  @override
  String get exportJson => 'Exportar JSON legible';

  @override
  String get restoreBackup => 'Restaurar copia';

  @override
  String get importJson => 'Importar JSON';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordRequired => 'Introduce una contraseña.';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get backupWarning =>
      'La contraseña no se guarda. Sin ella, la copia es inaccesible.';

  @override
  String get jsonWarning =>
      'El archivo legible contiene tus datos personales sin protección.';

  @override
  String get replaceWarning =>
      'Todos los datos actuales serán reemplazados. Esta acción no se puede deshacer.';

  @override
  String get confirmReplace => 'Reemplazar todo';

  @override
  String get summaryTitle => 'Resumen del archivo';

  @override
  String get summaryExportedAt => 'Exportado el';

  @override
  String get summaryTasks => 'Tareas';

  @override
  String get summaryActive => 'Activas';

  @override
  String get summaryCompleted => 'Completadas';

  @override
  String get summaryTrash => 'En la papelera';

  @override
  String get summarySubtasks => 'Pasos';

  @override
  String get summaryLists => 'Listas';

  @override
  String get summaryGroups => 'Grupos';

  @override
  String get summaryCategories => 'Categorías';

  @override
  String get summaryTags => 'Etiquetas';

  @override
  String get summarySeries => 'Series';

  @override
  String get summaryMyDay => 'Entradas de Mi día';

  @override
  String get fileSaved => 'Archivo guardado.';

  @override
  String get errorWrongPassword => 'Contraseña incorrecta o archivo dañado.';

  @override
  String get errorInvalidFile => 'Archivo inválido o incompatible.';

  @override
  String get typeBackup => 'Copia cifrada';

  @override
  String get typeJson => 'JSON legible';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get languageSystem => 'Automático (sistema)';

  @override
  String get languagePt => 'Português (Brasil)';

  @override
  String get languageEn => 'English';

  @override
  String get languageEs => 'Español';
}
