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
}
