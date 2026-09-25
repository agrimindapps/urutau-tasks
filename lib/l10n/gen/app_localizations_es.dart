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
}
