import 'package:urutau_tasks/src/core/ids.dart';
import 'package:urutau_tasks/src/features/my_day/domain/my_day_repository.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence_repository.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization_repository.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task_repository.dart';

/// Casos de uso do ciclo de vida de tarefas e subtarefas (spec 01).
///
/// As regras de domínio vivem em `task.dart`; este serviço aplica as
/// restrições de transição e orquestra o repositório.
class TasksService {
  TasksService(
    this._repository, {
    OrganizationRepository? organizationRepository,
    MyDayRepository? myDayRepository,
    RecurrenceRepository? recurrenceRepository,
    DateTime Function()? now,
    String Function()? generateId,
  })  : _organization = organizationRepository,
        _myDay = myDayRepository,
        _recurrence = recurrenceRepository,
        _now = now ?? DateTime.now,
        _generateId = generateId ?? newId;

  final TaskRepository _repository;
  final OrganizationRepository? _organization;
  final MyDayRepository? _myDay;
  final RecurrenceRepository? _recurrence;
  final DateTime Function() _now;
  final String Function() _generateId;

  Future<String> createTask({
    required String title,
    String? notes,
    String? listId,
    String? categoryId,
    Priority priority = Priority.medium,
    DateTime? dueDate,
    DateTime? reminder,
  }) async {
    final normalized = normalizeTitle(title);
    await _ensureListExists(listId);
    _ensureReminderFuture(reminder);
    final now = _now();
    final task = Task(
      id: _generateId(),
      title: normalized,
      notes: _normalizeNotes(notes),
      createdAt: now,
      position: await _repository.nextTaskPosition(),
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      listId: listId,
      categoryId: categoryId,
    );
    await _repository.insertTask(task);
    return task.id;
  }

  /// RF-07/CA-05: move a hierarquia da tarefa alterando apenas a lista da
  /// tarefa principal; subtarefas e demais dados permanecem intactos.
  Future<void> moveTaskToList(String taskId, String? listId) async {
    await _ensureListExists(listId);
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    await _repository.saveTask(
      listId == null
          ? task.copyWith(clearListId: true)
          : task.copyWith(listId: listId),
    );
  }

  /// RF-08/CA-10: atribui, substitui ou remove a categoria da tarefa.
  Future<void> setTaskCategory(String taskId, String? categoryId) async {
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    await _repository.saveTask(
      categoryId == null
          ? task.copyWith(clearCategoryId: true)
          : task.copyWith(categoryId: categoryId),
    );
  }

  /// RF-09: substitui o conjunto de tags da tarefa (nomes equivalentes
  /// são resolvidos pela camada de organização antes).
  Future<void> setTaskTags(String taskId, List<Tag> tags) async {
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    await _repository.saveTask(task.copyWith(tags: tags));
  }

  Future<void> _ensureListExists(String? listId) async {
    if (listId == null) return;
    final organization = _organization;
    if (organization == null) {
      throw StateError('Organization repository is not configured.');
    }
    final lists = await organization.getLists();
    if (!lists.any((l) => l.id == listId)) {
      throw StateError('List not found: $listId');
    }
  }

  /// RF-01/RF-03: títulos sempre validados; itens na lixeira não são
  /// editados até serem restaurados.
  Future<void> editTask(
    String id, {
    required String title,
    String? notes,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? reminder,
    bool clearReminder = false,
  }) async {
    final task = await _requireTask(id);
    _ensureEditable(task);
    final normalized = normalizeTitle(title);
    // RF-04: rejeita apenas quando o lembrete é alterado para o passado.
    // Valores vencidos já registrados podem permanecer (CA-08).
    final reminderChanged = !clearReminder &&
        reminder != null &&
        !reminder.isAtSameMomentAs(task.reminder ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (reminderChanged) _ensureReminderFuture(reminder);
    await _repository.saveTask(
      task.copyWith(
        title: normalized,
        notes: _normalizeNotes(notes),
        priority: priority,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
        reminder: reminder,
        clearReminder: clearReminder,
        updatedAt: _now(),
      ),
    );
  }

  /// RF-04/CA-05: lembrete no passado é rejeitado; prazos passados são
  /// válidos (atrasados).
  void _ensureReminderFuture(DateTime? reminder) {
    if (reminder == null) return;
    if (reminder.isBefore(_now())) {
      throw const ReminderInPastException();
    }
  }

  /// RF-07 a RF-12: ativa, altera ou cancela a recorrência da tarefa.
  ///
  /// - [frequency] nulo cancela a série (RF-10/CA-17); o vínculo da
  ///   ocorrência atual é preservado para distinção "recorrência
  ///   cancelada" no filtro (spec 05, RF-15) e ocorrências históricas
  ///   mantêm o vínculo.
  /// - Ativar exige prazo (RF-07/CA-18).
  /// - Alterar regra/prazo vale a partir da ocorrência atual, sem
  ///   reescrever histórico (RF-12/CA-16).
  Future<void> setRecurrence(
    String taskId,
    RecurrenceFrequency? frequency,
  ) async {
    final recurrence = _recurrence;
    if (recurrence == null) return;
    final task = await _requireTask(taskId);
    _ensureEditable(task);

    if (frequency == null) {
      if (task.seriesId == null) return;
      final series = await recurrence.getSeries(task.seriesId!);
      if (series != null && series.active) {
        await recurrence.saveSeries(series.copyWith(active: false));
      }
      return;
    }

    if (task.dueDate == null) {
      throw const RecurrenceRequiresDueDateException();
    }
    final anchor = _encodeDate(task.dueDate!);

    if (task.seriesId != null) {
      final series = await recurrence.getSeries(task.seriesId!);
      if (series != null) {
        await recurrence.saveSeries(
          series.copyWith(frequency: frequency, anchorDate: anchor),
        );
        return;
      }
    }

    final series = RecurrenceSeries(
      id: _generateId(),
      frequency: frequency,
      anchorDate: anchor,
    );
    await recurrence.insertSeries(series);
    await _repository.saveTask(task.copyWith(seriesId: series.id));
  }

  Future<void> toggleCompletion(String id) async {
    final task = await _requireTask(id);
    _ensureNotInTrash(task);
    final updated = toggleTaskCompletion(task, _now());
    await _repository.saveTask(updated);
    // RF-09/CA-13 (spec 03): concluir sai do My Day imediatamente.
    if (updated.isCompleted) {
      await _myDay?.removeEntriesForTask(id);
      // RF-11 (spec 04): gera a próxima ocorrência da série ativa.
      await _createNextOccurrence(updated);
    }
  }

  /// RF-11/CA-11 a CA-15: a ocorrência concluída fica no histórico e apenas
  /// a próxima data futura vira nova tarefa, sem copiar subtarefas.
  Future<void> _createNextOccurrence(Task completed) async {
    final recurrence = _recurrence;
    final seriesId = completed.seriesId;
    if (recurrence == null || seriesId == null || completed.dueDate == null) {
      return;
    }
    final series = await recurrence.getSeries(seriesId);
    if (series == null || !series.active) return;

    final due = _decodeDate(series.anchorDate);
    final next = nextOccurrenceDate(
      fromDue: completed.dueDate!,
      anchor: due,
      frequency: series.frequency,
      today: _now(),
    );
    if (next == null) return;

    final now = _now();
    final nextTask = Task(
      id: _generateId(),
      title: completed.title,
      notes: completed.notes,
      createdAt: now,
      position: await _repository.nextTaskPosition(),
      priority: completed.priority,
      dueDate: next,
      reminder: inheritReminder(
        oldReminder: completed.reminder,
        oldDue: completed.dueDate!,
        newDue: next,
      ),
      listId: completed.listId,
      categoryId: completed.categoryId,
      seriesId: seriesId,
      tags: completed.tags,
    );
    await _repository.insertTask(nextTask);
  }

  static String _encodeDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static DateTime _decodeDate(String encoded) {
    final parts = encoded.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Future<void> moveToTrash(String id) async {
    final task = await _requireTask(id);
    await _repository.saveTask(trashTask(task, _now()));
    // RF-05/CA-08: sai de todas as visões, incluindo My Day.
    await _myDay?.removeEntriesForTask(id);
  }

  Future<void> restoreFromTrash(String id) async {
    final task = await _requireTask(id);
    await _repository.saveTask(restoreTask(task, _now()));
  }

  /// RF-05: subtarefas só em tarefas ativas ou concluídas, nunca na
  /// lixeira.
  Future<void> addSubtask(String taskId, {required String title}) async {
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    final normalized = normalizeTitle(title);
    final subtask = Subtask(
      id: _generateId(),
      taskId: task.id,
      title: normalized,
      position: await _repository.nextSubtaskPosition(task.id),
    );
    await _repository
        .saveTask(task.copyWith(subtasks: [...task.subtasks, subtask]));
  }

  Future<void> editSubtask(
    String taskId,
    String subtaskId, {
    required String title,
  }) async {
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    final normalized = normalizeTitle(title);
    await _repository.saveTask(
      task.copyWith(
        subtasks: [
          for (final subtask in task.subtasks)
            subtask.id == subtaskId
                ? subtask.copyWith(title: normalized)
                : subtask,
        ],
        updatedAt: _now(),
      ),
    );
  }

  Future<void> toggleSubtaskCompletion(
    String taskId,
    String subtaskId,
  ) async {
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    await _repository.saveTask(
      task.copyWith(
        subtasks: [
          for (final subtask in task.subtasks)
            subtask.id == subtaskId
                ? subtask.copyWith(isCompleted: !subtask.isCompleted)
                : subtask,
        ],
        updatedAt: _now(),
      ),
    );
  }

  /// RF-07/CA-05: remoção individual exclui o registro; não vai para a
  /// lixeira nem afeta as demais subtarefas.
  Future<void> removeSubtask(String taskId, String subtaskId) async {
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    final remaining =
        task.subtasks.where((s) => s.id != subtaskId).toList();
    if (remaining.length == task.subtasks.length) return;
    await _repository.deleteSubtask(subtaskId);
    await _repository.saveTask(
      task.copyWith(
        subtasks: [
          for (var i = 0; i < remaining.length; i++)
            remaining[i].copyWith(position: i),
        ],
        updatedAt: _now(),
      ),
    );
  }

  Future<void> moveSubtask(
    String taskId,
    int oldIndex,
    int newIndex,
  ) async {
    final task = await _requireTask(taskId);
    _ensureNotInTrash(task);
    final reordered = reorderSubtasks(task.subtasks, oldIndex, newIndex);
    await _repository.saveTask(
      task.copyWith(subtasks: reordered, updatedAt: _now()),
    );
  }

  Future<Task> _requireTask(String id) async {
    final task = await _repository.getTask(id);
    if (task == null) {
      throw StateError('Task not found: $id');
    }
    return task;
  }

  void _ensureEditable(Task task) {
    if (task.isDeleted) {
      throw StateError('Tasks in the trash cannot be edited.');
    }
  }

  void _ensureNotInTrash(Task task) {
    if (task.isDeleted) {
      throw StateError('Tasks in the trash are read-only.');
    }
  }

  String? _normalizeNotes(String? notes) {
    final trimmed = notes?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
