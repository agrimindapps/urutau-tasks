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
  String get allTasks => 'Todas las tareas';

  @override
  String get completedTasks => 'Completadas';

  @override
  String get trash => 'Papelera';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get newSubtask => 'Nuevo paso';

  @override
  String get taskTitle => 'Título de la tarea';

  @override
  String get subtaskTitle => 'Título del paso';

  @override
  String get taskTitleRequired => 'Escribe un título.';

  @override
  String get add => 'Añadir';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get editTask => 'Editar tarea';

  @override
  String get editSubtask => 'Editar paso';

  @override
  String get taskDetails => 'Detalles de la tarea';

  @override
  String get subtasks => 'Pasos';

  @override
  String taskProgress(int completed, int total) {
    return '$completed/$total pasos completados';
  }

  @override
  String get noSubtasks => 'Todavía no hay pasos.';

  @override
  String get moveUp => 'Mover hacia arriba';

  @override
  String get moveDown => 'Mover hacia abajo';

  @override
  String get noActiveTasks => 'Todavía no hay tareas. Añade una para empezar.';

  @override
  String get noCompletedTasks => 'Todavía no hay tareas completadas.';

  @override
  String get trashEmpty => 'La papelera está vacía.';

  @override
  String get markComplete => 'Marcar como completada';

  @override
  String get reopenTask => 'Reabrir tarea';

  @override
  String get moveToTrash => 'Mover a la papelera';

  @override
  String get restore => 'Restaurar';

  @override
  String get removeSubtask => 'Eliminar paso';

  @override
  String get removeSubtaskConfirmation =>
      'Este paso se eliminará permanentemente.';

  @override
  String get remove => 'Eliminar';

  @override
  String get close => 'Cerrar';

  @override
  String get loading => 'Cargando…';

  @override
  String get unableToLoadTasks => 'No se pudieron cargar las tareas.';

  @override
  String get unableToLoadTask => 'No se pudo cargar esta tarea.';

  @override
  String get taskNotFound => 'Esta tarea ya no está disponible.';

  @override
  String get actionFailed =>
      'No se pudo guardar el cambio. Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get manageOrganization => 'Organizar';

  @override
  String get lists => 'Listas';

  @override
  String get groups => 'Grupos';

  @override
  String get categories => 'Categorías';

  @override
  String get tags => 'Etiquetas';

  @override
  String get newList => 'Nueva lista';

  @override
  String get newGroup => 'Nuevo grupo';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get newTag => 'Nueva etiqueta';

  @override
  String get listName => 'Nombre de la lista';

  @override
  String get groupName => 'Nombre del grupo';

  @override
  String get categoryName => 'Nombre de la categoría';

  @override
  String get tagName => 'Nombre de la etiqueta';

  @override
  String get editList => 'Editar lista';

  @override
  String get editGroup => 'Editar grupo';

  @override
  String get editCategory => 'Editar categoría';

  @override
  String get editTag => 'Editar etiqueta';

  @override
  String get deleteList => 'Eliminar lista';

  @override
  String get deleteGroup => 'Eliminar grupo';

  @override
  String get deleteCategory => 'Eliminar categoría';

  @override
  String get deleteTag => 'Eliminar etiqueta';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get noLists => 'Todavía no hay listas.';

  @override
  String get noGroups => 'Todavía no hay grupos.';

  @override
  String get noCategories => 'Todavía no hay categorías.';

  @override
  String get noTags => 'Todavía no hay etiquetas.';

  @override
  String get selectGroup => 'Elige un grupo';

  @override
  String get noGroup => 'Sin grupo';

  @override
  String get moveToGroup => 'Cambiar grupo';

  @override
  String get selectDestinationList => 'Elige una lista de destino';

  @override
  String get deleteListNeedsDestination =>
      'Esta lista tiene tareas. Elige otra lista para recibirlas.';

  @override
  String get deleteListConfirmation =>
      'Las tareas y los pasos se moverán a la lista elegida.';

  @override
  String get deleteGroupConfirmation =>
      'Las listas se conservarán y quedarán sin grupo.';

  @override
  String get deleteCategoryConfirmation =>
      'Las tareas conservarán sus otros datos y dejarán esta categoría.';

  @override
  String get deleteTagConfirmation =>
      'Esta etiqueta se quitará de las tareas asociadas.';

  @override
  String get duplicateName => 'Ya existe un elemento con este nombre.';

  @override
  String get taskList => 'Lista';

  @override
  String get taskCategory => 'Categoría';

  @override
  String get taskTags => 'Etiquetas';

  @override
  String get noList => 'Sin lista';

  @override
  String get noCategory => 'Sin categoría';

  @override
  String get priority => 'Prioridad';

  @override
  String get noPriority => 'Sin prioridad';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get notes => 'Notas';

  @override
  String get editNotes => 'Editar notas';

  @override
  String get noNotes => 'Todavía no hay notas.';

  @override
  String get dueDate => 'Fecha límite';

  @override
  String get noDueDate => 'Sin fecha límite';

  @override
  String get chooseDueDate => 'Definir fecha límite';

  @override
  String get removeDueDate => 'Quitar fecha límite';

  @override
  String get reminder => 'Recordatorio';

  @override
  String get noReminder => 'Sin recordatorio';

  @override
  String get chooseReminder => 'Definir recordatorio';

  @override
  String get removeReminder => 'Quitar recordatorio';

  @override
  String get reminderInPast =>
      'Elige una fecha y hora futuras para el recordatorio.';

  @override
  String get reminderDeliveryScheduled =>
      'El recordatorio está configurado. La entrega depende de la plataforma y sus ajustes de notificaciones.';

  @override
  String get reminderPermissionNeeded =>
      'Las notificaciones del sistema están desactivadas. El recordatorio se guardó; activa las notificaciones para recibir avisos del sistema.';

  @override
  String get reminderCancellationPending =>
      'No se pudo confirmar la cancelación de un recordatorio anterior del sistema; aún podría aparecer. La aplicación volverá a intentarlo.';

  @override
  String get webNotificationSettingsHelp =>
      'Si el navegador bloqueó la solicitud, permite las notificaciones en la configuración de este sitio y vuelve a comprobarlo.';

  @override
  String get checkNotificationPermission => 'Volver a comprobar';

  @override
  String get reminderUnavailable =>
      'Las notificaciones del sistema no están disponibles aquí. Mantén la aplicación abierta para recibir avisos de mejor esfuerzo.';

  @override
  String get reminderExpired =>
      'La hora del recordatorio ya pasó. No se enviará un aviso tardío.';

  @override
  String get reminderPending =>
      'Comprobando la disponibilidad de notificaciones…';

  @override
  String get reminderPaused =>
      'El recordatorio está guardado y pausado mientras la tarea esté completada o en la papelera.';

  @override
  String get reminderPermissionRationale =>
      'Los recordatorios usan notificaciones locales. La entrega depende del permiso del sistema o del navegador y puede variar según la plataforma. En la Web, el navegador puede pedir permiso ahora; si cancelas la selección de fecha u hora, no se guardará ningún recordatorio.';

  @override
  String get openTask => 'Abrir tarea';

  @override
  String get notificationChannelName => 'Recordatorios de tareas';

  @override
  String get notificationChannelDescription =>
      'Notificaciones para recordatorios de tareas';

  @override
  String get openNotificationSettings => 'Activar notificaciones del sistema';

  @override
  String get notNow => 'Ahora no';

  @override
  String get myDay => 'Mi día';

  @override
  String get importantTasks => 'Importantes';

  @override
  String get plannedTasks => 'Planificadas';

  @override
  String get addToMyDay => 'Añadir a Mi día';

  @override
  String get removeFromMyDay => 'Quitar de Mi día';

  @override
  String get myDayEmpty => 'Añade tareas aquí para centrarte hoy.';

  @override
  String get noImportantTasks => 'No hay tareas importantes por ahora.';

  @override
  String get noPlannedTasks => 'No hay tareas planificadas por ahora.';

  @override
  String get recurrence => 'Repetición';

  @override
  String get noRecurrence => 'No se repite';

  @override
  String get recurrenceDaily => 'Diaria';

  @override
  String get recurrenceWeekdays => 'Cada día laborable';

  @override
  String get recurrenceWeekly => 'Semanal';

  @override
  String get recurrenceMonthly => 'Mensual';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get recurrenceCancelled => 'Esta repetición se canceló.';

  @override
  String get recurrenceNeedsDueDate =>
      'Añade una fecha límite antes de configurar una repetición.';

  @override
  String get recurrenceHelp =>
      'Con la repetición activada, al completar esta tarea se guarda en el historial y se crea la siguiente ocurrencia. Los pasos no se copian.';

  @override
  String get recurrenceHistoryReadOnly =>
      'Ya existe una ocurrencia posterior. Edita la ocurrencia más reciente para cambiar la serie.';

  @override
  String get searchTasks => 'Buscar tareas';

  @override
  String get searchHint => 'Buscar en títulos, notas y pasos';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get searchMatchInNotes => 'Coincidencia en las notas';

  @override
  String get searchMatchInSteps => 'Coincidencia en un paso';

  @override
  String get searchMatchInTitle => 'Coincidencia en el título';

  @override
  String get noSearchResults =>
      'Ninguna tarea coincide con la búsqueda y los filtros.';

  @override
  String get filters => 'Filtros';

  @override
  String get clearFilters => 'Borrar filtros';

  @override
  String get apply => 'Aplicar';

  @override
  String get status => 'Estado';

  @override
  String get activeTasks => 'Activas';

  @override
  String get overdue => 'Atrasadas';

  @override
  String get dueToday => 'Para hoy';

  @override
  String get nextSevenDays => 'Próximos 7 días';

  @override
  String get customDateRange => 'Intervalo personalizado';

  @override
  String get withReminder => 'Con recordatorio';

  @override
  String get withoutReminder => 'Sin recordatorio';

  @override
  String get withRecurrence => 'Con repetición activa';

  @override
  String get withoutRecurrence => 'Sin repetición';

  @override
  String get cancelledRecurrence => 'Repetición cancelada';

  @override
  String get chooseDate => 'Elegir fechas';

  @override
  String get dateRangeRequired =>
      'Elige una fecha de inicio y una de fin antes de aplicar este filtro.';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma de la interfaz';

  @override
  String get languagePreferenceHelp =>
      'Elige el idioma de los textos de la aplicación. Las fechas y los números siguen la región del dispositivo.';

  @override
  String get automaticSystem => 'Automático (sistema)';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get backupAndPortability => 'Datos y portabilidad';

  @override
  String get backupAndPortabilityDescription =>
      'Crea una copia protegida con contraseña, exporta JSON legible o sustituye los datos locales desde un archivo compatible.';

  @override
  String get preparingEncryptedBackup =>
      'Cifrando y preparando la copia de seguridad…';

  @override
  String get preparingJsonExport => 'Preparando la exportación JSON…';

  @override
  String get preparingDataRestore => 'Validando y preparando la restauración…';

  @override
  String get createBackup => 'Crear copia cifrada';

  @override
  String get encryptedBackupDescription =>
      'Una copia completa protegida con la contraseña que elijas.';

  @override
  String get exportOpenJson => 'Exportar JSON abierto';

  @override
  String get unencryptedJsonDescription =>
      'Un archivo legible y sin cifrar con los datos de tus tareas.';

  @override
  String get importOrRestore => 'Importar o restaurar';

  @override
  String get encryptedBackupWarning =>
      'La copia estará protegida por esta contraseña. Si la pierdes, no se podrá recuperar.';

  @override
  String get unencryptedExportWarning =>
      'Este JSON no está cifrado. Es legible e incluye datos personales, como notas y recordatorios.';

  @override
  String get importReplaceWarning =>
      'La importación o restauración sustituye todos los datos locales después de revisar y confirmar el archivo.';

  @override
  String get backupExportDone => 'Copia cifrada guardada.';

  @override
  String get jsonExportDone => 'Archivo JSON guardado.';

  @override
  String get dataImportDone =>
      'Los datos locales se sustituyeron desde el archivo.';

  @override
  String get chooseExportDestination => 'Elige dónde guardar el archivo';

  @override
  String get restoreBackup => 'Restaurar copia';

  @override
  String get backupPasswordRequired =>
      'Introduce la contraseña usada al crear esta copia.';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get emptyPassword => 'Introduce una contraseña.';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get importPreview => 'Revisar los datos';

  @override
  String get exportDate => 'Exportado';

  @override
  String get openJsonFile => 'Archivo JSON abierto';

  @override
  String get encryptedBackupFile => 'Copia cifrada';

  @override
  String get replaceLocalData => 'Sustituir datos locales';

  @override
  String get wrongPasswordOrCorrupt =>
      'La contraseña es incorrecta o la copia está dañada.';

  @override
  String get invalidImportFile =>
      'El archivo no es válido o contiene datos incoherentes.';

  @override
  String get incompatibleFile => 'Esta versión del archivo no es compatible.';

  @override
  String get databaseFromNewerVersion =>
      'Estos datos se crearon con una versión más reciente de Urutau Tasks. Actualiza la aplicación para abrirlos; tus datos no se modificaron.';

  @override
  String get databaseMigrationFailed =>
      'No se pudo actualizar la base de datos local. La aplicación no pudo continuar para proteger tus datos.';
}
