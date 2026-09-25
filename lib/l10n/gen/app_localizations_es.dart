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
  String get tasksTab => 'Tareas';

  @override
  String get trashTab => 'Papelera';

  @override
  String get addTask => 'Añadir tarea';

  @override
  String get taskTitleLabel => 'Título';

  @override
  String get taskTitleHint => '¿Qué hay que hacer?';

  @override
  String get notesLabel => 'Notas';

  @override
  String get notesHint => 'Añadir una nota';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get titleRequired => 'Introduce un título.';

  @override
  String get markComplete => 'Completar';

  @override
  String get markIncomplete => 'Reabrir';

  @override
  String get emptyTasks => 'No hay tareas aquí. ¡Crea la primera!';

  @override
  String get emptyTrash => 'La papelera está vacía.';

  @override
  String get subtasksSection => 'Subtareas';

  @override
  String get addSubtask => 'Añadir subtarea';

  @override
  String get subtaskTitleHint => 'Nuevo paso';

  @override
  String get progressLabel => 'Progreso';

  @override
  String get moveToTrash => 'Mover a la papelera';

  @override
  String get restore => 'Restaurar';

  @override
  String get trashBanner => 'Esta tarea está en la papelera.';

  @override
  String get completedSection => 'Completadas';

  @override
  String get activeSection => 'Activas';

  @override
  String get taskDetail => 'Detalles de la tarea';

  @override
  String get openTaskDetail => 'Abrir detalles de la tarea';

  @override
  String get listsTab => 'Listas';

  @override
  String get listsSection => 'Listas';

  @override
  String get groupsSection => 'Grupos';

  @override
  String get categoriesSection => 'Categorías';

  @override
  String get tagsSection => 'Etiquetas';

  @override
  String get newList => 'Nueva lista';

  @override
  String get newGroup => 'Nuevo grupo';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get newTag => 'Nueva etiqueta';

  @override
  String get nameField => 'Nombre';

  @override
  String get rename => 'Renombrar';

  @override
  String get groupLabel => 'Grupo';

  @override
  String get noGroup => 'Sin grupo';

  @override
  String get listLabel => 'Lista';

  @override
  String get noList => 'Sin lista';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get noCategory => 'Sin categoría';

  @override
  String get tagsLabel => 'Etiquetas';

  @override
  String get addTagHint => 'Añadir etiqueta';

  @override
  String get nameRequired => 'Introduce un nombre.';

  @override
  String get nameDuplicate => 'Ya existe un nombre equivalente.';

  @override
  String get listNotEmpty =>
      'La lista tiene tareas. Elige una lista de destino.';

  @override
  String get noDestination => 'No hay otra lista para recibir las tareas.';

  @override
  String get destinationLabel => 'Lista de destino';

  @override
  String get tasksMoveNotice =>
      'Las tareas se moverán al destino elegido y la lista se eliminará.';

  @override
  String get moveToList => 'Mover a la lista';

  @override
  String get moveToGroup => 'Mover al grupo';

  @override
  String get emptyLists => 'Ninguna lista. ¡Crea la primera!';

  @override
  String get emptyGroups => 'Ningún grupo creado.';

  @override
  String get emptyCategories => 'Ninguna categoría creada.';

  @override
  String get emptyTags => 'Ninguna etiqueta creada.';

  @override
  String get filterAll => 'Todas';

  @override
  String get deleteGroupTitle => 'Eliminar grupo';

  @override
  String get deleteGroupNotice =>
      'Las listas del grupo se conservarán y quedarán sin grupo.';

  @override
  String get deleteCategoryTitle => 'Eliminar categoría';

  @override
  String get deleteCategoryNotice =>
      'Las tareas quedarán sin categoría; se conservan los demás datos.';

  @override
  String get deleteTagTitle => 'Eliminar etiqueta';

  @override
  String get deleteTagNotice =>
      'La etiqueta se quitará de las tareas; se conservan los demás datos.';

  @override
  String get deleteListTitle => 'Eliminar lista';

  @override
  String get myDayTab => 'My Day';

  @override
  String get viewAll => 'Todas';

  @override
  String get viewImportant => 'Importante';

  @override
  String get viewPlanned => 'Planificado';

  @override
  String get viewCompleted => 'Completadas';

  @override
  String get addToMyDay => 'Añadir a My Day';

  @override
  String get removeFromMyDay => 'Quitar de My Day';

  @override
  String get emptyMyDay => 'My Day está vacío. ¡Añade tareas al foco del día!';

  @override
  String get addExistingTask => 'Añadir tarea existente';

  @override
  String get priorityLabel => 'Prioridad';

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
  String get reminderLabel => 'Recordatorio';

  @override
  String get noDueDate => 'Sin fecha límite';

  @override
  String get noReminder => 'Sin recordatorio';

  @override
  String get pickDueDate => 'Establecer fecha límite';

  @override
  String get pickReminder => 'Establecer recordatorio';

  @override
  String get clearDueDate => 'Quitar fecha límite';

  @override
  String get clearReminder => 'Quitar recordatorio';

  @override
  String get recurrenceLabel => 'Repetir';

  @override
  String get recurrenceNone => 'No se repite';

  @override
  String get recurrenceDaily => 'Diaria';

  @override
  String get recurrenceWeekdays => 'Días laborables';

  @override
  String get recurrenceWeekly => 'Semanal';

  @override
  String get recurrenceMonthly => 'Mensual';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get reminderInPast => 'Elige una hora futura para el recordatorio.';

  @override
  String get recurrenceRequiresDueDate =>
      'Establece una fecha límite antes de activar la repetición.';

  @override
  String get searchHint => 'Buscar tareas';

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get filterActive => 'Activas';

  @override
  String get filterCompleted => 'Completadas';

  @override
  String get dueOverdue => 'Atrasadas';

  @override
  String get dueToday => 'Hoy';

  @override
  String get dueNext7 => 'Próximos 7 días';

  @override
  String get dueCustom => 'Intervalo personalizado';

  @override
  String get dueFrom => 'De';

  @override
  String get dueTo => 'Hasta';

  @override
  String get reminderWith => 'Con recordatorio';

  @override
  String get reminderWithout => 'Sin recordatorio';

  @override
  String get recurrenceWithActive => 'Con repetición';

  @override
  String get recurrenceWithout => 'Sin repetición';

  @override
  String get recurrenceCanceled => 'Repetición cancelada';

  @override
  String get noTags => 'Sin etiquetas';

  @override
  String get emptySearch => 'No se encontraron resultados.';

  @override
  String get statusSection => 'Estado';

  @override
  String get dueSection => 'Fecha límite';

  @override
  String get reminderSection => 'Recordatorio';

  @override
  String get recurrenceSection => 'Repetición';

  @override
  String get listsSectionFilter => 'Listas';

  @override
  String get groupsSectionFilter => 'Grupos';

  @override
  String get categoriesSectionFilter => 'Categorías';

  @override
  String get tagsSectionFilter => 'Etiquetas';

  @override
  String get prioritySection => 'Prioridad';

  @override
  String get dataSection => 'Datos';

  @override
  String get exportJson => 'Exportar JSON';

  @override
  String get importJson => 'Importar JSON';

  @override
  String get createBackup => 'Crear copia de seguridad';

  @override
  String get restoreBackup => 'Restaurar copia de seguridad';

  @override
  String get exportJsonTitle => 'Exportar formato abierto';

  @override
  String get exportJsonWarning =>
      'El archivo JSON no está cifrado y contiene datos personales, como notas y recordatorios. ¿Deseas continuar?';

  @override
  String get backupPasswordTitle => 'Contraseña de la copia';

  @override
  String get backupPasswordLabel => 'Contraseña';

  @override
  String get backupPasswordConfirm => 'Confirmar contraseña';

  @override
  String get backupLostPasswordWarning =>
      'Si se pierde la contraseña, la copia no podrá recuperarse. No hay recuperación por cuenta ni servidor.';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get passwordRequired => 'Introduce la contraseña.';

  @override
  String get backupCreated => 'Copia de seguridad creada.';

  @override
  String get exportDone => 'Archivo exportado correctamente.';

  @override
  String get replaceTitle => '¿Reemplazar todos los datos?';

  @override
  String get replaceWarning =>
      'Todos los datos actuales serán reemplazados íntegramente por los del archivo. Esta acción no se puede deshacer.';

  @override
  String get confirmReplace => 'Reemplazar';

  @override
  String get summaryTypeBackup => 'Copia cifrada';

  @override
  String get summaryTypeJson => 'JSON abierto';

  @override
  String get summaryExportedAt => 'Exportado el';

  @override
  String get summaryActiveTasks => 'Tareas activas';

  @override
  String get summaryCompletedTasks => 'Tareas completadas';

  @override
  String get summaryTrashedTasks => 'En la papelera';

  @override
  String get summarySubtasks => 'Subtareas';

  @override
  String get summarySeries => 'Series recurrentes';

  @override
  String get summaryMyDay => 'Entradas de My Day';

  @override
  String get invalidPassword => 'Contraseña incorrecta o archivo dañado.';

  @override
  String get invalidFile => 'Archivo inválido.';

  @override
  String get unsupportedVersion => 'Versión de archivo no compatible.';

  @override
  String get importDone => 'Datos reemplazados correctamente.';

  @override
  String get operationCancelled => 'Operación cancelada.';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Automático (sistema)';

  @override
  String get languagePt => 'Português (Brasil)';

  @override
  String get languageEn => 'English';

  @override
  String get languageEs => 'Español';

  @override
  String get languageUpdated => 'Idioma actualizado.';

  @override
  String get close => 'Cerrar';

  @override
  String get reminderStateScheduled => 'Programado';

  @override
  String get reminderStatePermission => 'Permiso necesario';

  @override
  String get reminderStateUnavailable => 'No disponible en esta plataforma';

  @override
  String get reminderStateExpired => 'Vencido';

  @override
  String get reminderStatePending => 'Pendiente de verificación';

  @override
  String get reminderPermissionTitle => 'Permitir avisos';

  @override
  String get reminderPermissionMessage =>
      'Para mostrar recordatorios, la app necesita la autorización del sistema. Puedes rechazarlo: el recordatorio seguirá guardado, sin avisos.';

  @override
  String get reminderPermissionConfirm => 'Entendido';

  @override
  String get reminderNotificationsDisabled =>
      'Avisos desactivados. Activa el permiso en la configuración del sistema o del navegador.';

  @override
  String get openTask => 'Abrir tarea';
}
