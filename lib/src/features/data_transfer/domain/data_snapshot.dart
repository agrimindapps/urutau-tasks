// Retrato lógico versionado para backup e formato aberto (spec 07, RF-01).

/// Registros lógicos do conjunto de dados — independentes do esquema
/// SQLite/Drift (spec 07, RF-01/RF-03).
class TaskData {
  const TaskData({
    required this.id,
    required this.title,
    required this.notes,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.reminder,
    required this.listId,
    required this.categoryId,
    required this.seriesId,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.deletedAt,
  });

  final String id;
  final String title;
  final String? notes;

  /// `active` | `completed`; lixeira = [deletedAt] (spec 06).
  final String status;
  final String priority;

  /// Data local `yyyy-MM-dd` (spec 07, RF-04).
  final String? dueDate;

  /// Instante UTC ISO 8601 (spec 07, RF-04).
  final String? reminder;

  final String? listId;
  final String? categoryId;
  final String? seriesId;
  final int position;

  /// Instantes UTC ISO 8601.
  final String createdAt;
  final String? updatedAt;
  final String? completedAt;
  final String? deletedAt;
}

class SubtaskData {
  const SubtaskData({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.position,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int position;
}

class ListData {
  const ListData({
    required this.id,
    required this.name,
    required this.position,
    required this.groupId,
  });

  final String id;
  final String name;
  final int position;
  final String? groupId;
}

class GroupData {
  const GroupData({required this.id, required this.name, required this.position});

  final String id;
  final String name;
  final int position;
}

class CategoryData {
  const CategoryData({required this.id, required this.name});

  final String id;
  final String name;
}

class TagData {
  const TagData({required this.id, required this.name});

  final String id;
  final String name;
}

class TaskTagData {
  const TaskTagData({required this.taskId, required this.tagId});

  final String taskId;
  final String tagId;
}

class SeriesData {
  const SeriesData({
    required this.id,
    required this.frequency,
    required this.anchorDate,
    required this.active,
  });

  final String id;
  final String frequency;

  /// Data-base `yyyy-MM-dd` (spec 04, RF-07).
  final String anchorDate;
  final bool active;
}

class MyDayEntryData {
  const MyDayEntryData({
    required this.id,
    required this.taskId,
    required this.date,
    required this.position,
  });

  final String id;
  final String taskId;

  /// Data local `yyyy-MM-dd` (spec 06, RF-13).
  final String date;
  final int position;
}

/// Conjunto completo persistido (spec 07, RF-01).
class DataSnapshot {
  const DataSnapshot({
    required this.formatVersion,
    required this.exportedAt,
    required this.tasks,
    required this.subtasks,
    required this.lists,
    required this.groups,
    required this.categories,
    required this.tags,
    required this.taskTags,
    required this.series,
    required this.myDayEntries,
  });

  /// Versão monotônica do contrato, independente do esquema Drift
  /// (spec 07, RF-07/RF-10).
  final int formatVersion;

  /// Instante UTC ISO 8601 de criação do arquivo (spec 07, RF-07).
  final String exportedAt;

  final List<TaskData> tasks;
  final List<SubtaskData> subtasks;
  final List<ListData> lists;
  final List<GroupData> groups;
  final List<CategoryData> categories;
  final List<TagData> tags;
  final List<TaskTagData> taskTags;
  final List<SeriesData> series;
  final List<MyDayEntryData> myDayEntries;
}

/// Motivos de rejeição de um arquivo (spec 07, RF-13/RF-17).
enum SnapshotError {
  malformed,
  unsupportedVersion,
  missingField,
  wrongType,
  duplicateId,
  danglingReference,
  unknownField,
  invalidPassword,
  corruptContainer,
}

class SnapshotException implements Exception {
  const SnapshotException(this.error, [this.detail]);

  final SnapshotError error;
  final String? detail;

  @override
  String toString() => 'SnapshotException(${error.name}${detail == null ? '' : ': $detail'})';
}

/// Resumo exibido antes da substituição (spec 07, RF-14 / CA-07).
class ImportSummary {
  const ImportSummary({
    required this.isBackup,
    required this.exportedAt,
    required this.activeTasks,
    required this.completedTasks,
    required this.trashedTasks,
    required this.subtasks,
    required this.lists,
    required this.groups,
    required this.categories,
    required this.tags,
    required this.series,
    required this.myDayEntries,
  });

  final bool isBackup;
  final String exportedAt;
  final int activeTasks;
  final int completedTasks;
  final int trashedTasks;
  final int subtasks;
  final int lists;
  final int groups;
  final int categories;
  final int tags;
  final int series;
  final int myDayEntries;
}

/// Arquivo validado pronto para aplicação (spec 07, RF-14).
class ValidatedImport {
  const ValidatedImport({required this.snapshot, required this.summary});

  final DataSnapshot snapshot;
  final ImportSummary summary;
}
