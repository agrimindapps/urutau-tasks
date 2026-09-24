import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/recurrence.dart';
import '../domain/task.dart';

abstract interface class TaskRepository {
  Stream<List<Task>> watchTasks();

  Stream<Task?> watchTask(String taskId);

  Stream<List<Subtask>> watchSubtasks(String taskId);

  Stream<List<Subtask>> watchAllSubtasks();

  Stream<List<Task>> watchMyDay(String localDateIso);

  Future<Task> createTask(String title, {String? listId});

  Future<Task> createTaskAndAddToMyDay(String title, String localDateIso);

  Future<void> addTaskToMyDay(String taskId, String localDateIso);

  Future<void> removeTaskFromMyDay(String taskId, String localDateIso);

  Future<void> reorderMyDay(String localDateIso, List<String> orderedTaskIds);

  Future<void> rolloverMyDay(String currentLocalDateIso);

  Future<void> updateTaskTitle(String taskId, String title);

  Future<void> updateTaskNotes(String taskId, String? notes);

  Future<void> updateTaskPriority(String taskId, TaskPriority priority);

  Future<void> updateTaskDueDate(String taskId, String? dueDateIso);

  Future<void> updateTaskReminder(String taskId, DateTime? reminderAtUtc);

  Future<void> updateTaskRecurrence(
    String taskId,
    RecurrenceFrequency? frequency,
  );

  Future<void> setTaskCompleted(String taskId, bool isCompleted);

  Future<void> moveTaskToTrash(String taskId);

  Future<void> restoreTask(String taskId);

  Future<Subtask> addSubtask(String taskId, String title);

  Future<void> updateSubtaskTitle(String subtaskId, String title);

  Future<void> setSubtaskCompleted(String subtaskId, bool isCompleted);

  Future<void> removeSubtask(String subtaskId);

  Future<void> moveSubtask(String taskId, String subtaskId, int newPosition);
}

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<Task>> watchTasks() {
    final tasks = _database.tasks;
    final series = _database.recurrenceSeries;
    final query =
        _database.select(tasks).join([
          leftOuterJoin(series, series.id.equalsExp(tasks.recurringSeriesId)),
        ])..orderBy([
          OrderingTerm.asc(tasks.position),
          OrderingTerm.asc(tasks.createdAtUtc),
          OrderingTerm.asc(tasks.id),
        ]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _taskFromRow(
              row.readTable(tasks),
              recurrenceSeries: row.readTableOrNull(series),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Stream<Task?> watchTask(String taskId) {
    final tasks = _database.tasks;
    final series = _database.recurrenceSeries;
    final query = _database.select(tasks).join([
      leftOuterJoin(series, series.id.equalsExp(tasks.recurringSeriesId)),
    ])..where(tasks.id.equals(taskId));
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      return _taskFromRow(
        rows.first.readTable(tasks),
        recurrenceSeries: rows.first.readTableOrNull(series),
      );
    });
  }

  @override
  Stream<List<Subtask>> watchSubtasks(String taskId) =>
      (_database.select(_database.subtasks)
            ..where((subtask) => subtask.taskId.equals(taskId))
            ..orderBy([
              (subtask) => OrderingTerm.asc(subtask.position),
              (subtask) => OrderingTerm.asc(subtask.id),
            ]))
          .watch()
          .map((rows) => rows.map(_subtaskFromRow).toList(growable: false));

  @override
  Stream<List<Subtask>> watchAllSubtasks() =>
      (_database.select(_database.subtasks)..orderBy([
            (subtask) => OrderingTerm.asc(subtask.taskId),
            (subtask) => OrderingTerm.asc(subtask.position),
            (subtask) => OrderingTerm.asc(subtask.id),
          ]))
          .watch()
          .map((rows) => rows.map(_subtaskFromRow).toList(growable: false));

  @override
  Stream<List<Task>> watchMyDay(String localDateIso) {
    final date = normalizeDateOnly(localDateIso);
    final entries = _database.myDayEntries;
    final tasks = _database.tasks;
    final series = _database.recurrenceSeries;
    final query =
        _database.select(entries).join([
            innerJoin(tasks, tasks.id.equalsExp(entries.taskId)),
            leftOuterJoin(series, series.id.equalsExp(tasks.recurringSeriesId)),
          ])
          ..where(entries.localDateIso.equals(date))
          ..orderBy([OrderingTerm.asc(entries.position)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _taskFromRow(
              row.readTable(tasks),
              recurrenceSeries: row.readTableOrNull(series),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Task> createTask(String title, {String? listId}) async {
    final normalizedTitle = normalizeRequiredTitle(title);
    return _database.transaction(
      () => _createTaskInTransaction(normalizedTitle, listId),
    );
  }

  @override
  Future<Task> createTaskAndAddToMyDay(
    String title,
    String localDateIso,
  ) async {
    final date = normalizeDateOnly(localDateIso);
    return _database.transaction(() async {
      final task = await _createTaskInTransaction(
        normalizeRequiredTitle(title),
        null,
      );
      await _addTaskToMyDayInTransaction(task.id, date);
      return task;
    });
  }

  Future<Task> _createTaskInTransaction(String title, String? listId) async {
    if (listId != null) {
      final list = await (_database.select(
        _database.taskLists,
      )..where((row) => row.id.equals(listId))).getSingleOrNull();
      if (list == null) throw const TaskNotFoundException();
    }
    final query = _database.select(_database.tasks);
    if (listId == null) {
      query.where((task) => task.listId.isNull());
    } else {
      query.where((task) => task.listId.equals(listId));
    }
    final rows = await query.get();
    final position =
        rows.fold<int>(
          -1,
          (maximum, task) => task.position > maximum ? task.position : maximum,
        ) +
        1;
    final now = DateTime.now().toUtc();
    final task = Task(
      id: _uuid.v4(),
      title: title,
      status: TaskStatus.active,
      priority: TaskPriority.none,
      listId: listId,
      createdAtUtc: now,
      updatedAtUtc: now,
      position: position,
    );

    await _database
        .into(_database.tasks)
        .insert(
          TasksCompanion.insert(
            id: task.id,
            title: task.title,
            status: Value(task.status.databaseValue),
            priority: Value(task.priority.databaseValue),
            listId: Value(listId),
            createdAtUtc: now.millisecondsSinceEpoch,
            updatedAtUtc: now.millisecondsSinceEpoch,
            position: Value(position),
          ),
        );
    return task;
  }

  @override
  Future<void> addTaskToMyDay(String taskId, String localDateIso) async {
    final date = normalizeDateOnly(localDateIso);
    await _database.transaction(() async {
      await _addTaskToMyDayInTransaction(taskId, date);
    });
  }

  Future<void> _addTaskToMyDayInTransaction(String taskId, String date) async {
    final task = await _taskRecord(taskId);
    if (task.status != TaskStatus.active.databaseValue) {
      throw const TaskUnavailableException();
    }
    final entries =
        await (_database.select(_database.myDayEntries)
              ..where((entry) => entry.localDateIso.equals(date))
              ..orderBy([(entry) => OrderingTerm.asc(entry.position)]))
            .get();
    if (entries.any((entry) => entry.taskId == taskId)) return;
    final position =
        entries.fold<int>(
          -1,
          (maximum, entry) =>
              entry.position > maximum ? entry.position : maximum,
        ) +
        1;
    await _database
        .into(_database.myDayEntries)
        .insert(
          MyDayEntriesCompanion.insert(
            id: _uuid.v4(),
            taskId: taskId,
            localDateIso: date,
            position: position,
          ),
        );
  }

  @override
  Future<void> removeTaskFromMyDay(String taskId, String localDateIso) async {
    final date = normalizeDateOnly(localDateIso);
    await _database.transaction(() async {
      await (_database.delete(_database.myDayEntries)..where(
            (entry) =>
                entry.taskId.equals(taskId) & entry.localDateIso.equals(date),
          ))
          .go();
      await _renumberMyDay(date);
    });
  }

  @override
  Future<void> reorderMyDay(
    String localDateIso,
    List<String> orderedTaskIds,
  ) async {
    final date = normalizeDateOnly(localDateIso);
    await _database.transaction(() async {
      final entries =
          await (_database.select(_database.myDayEntries)
                ..where((entry) => entry.localDateIso.equals(date))
                ..orderBy([(entry) => OrderingTerm.asc(entry.position)]))
              .get();
      final existing = entries.map((entry) => entry.taskId).toSet();
      if (orderedTaskIds.toSet().length != orderedTaskIds.length ||
          orderedTaskIds.length != existing.length ||
          !orderedTaskIds.toSet().containsAll(existing)) {
        throw const TaskUnavailableException();
      }
      for (var index = 0; index < entries.length; index++) {
        await (_database.update(_database.myDayEntries)
              ..where((entry) => entry.id.equals(entries[index].id)))
            .write(MyDayEntriesCompanion(position: Value(-(index + 1))));
      }
      for (var position = 0; position < orderedTaskIds.length; position++) {
        final taskId = orderedTaskIds[position];
        await (_database.update(_database.myDayEntries)..where(
              (entry) =>
                  entry.taskId.equals(taskId) & entry.localDateIso.equals(date),
            ))
            .write(MyDayEntriesCompanion(position: Value(position)));
      }
    });
  }

  @override
  Future<void> rolloverMyDay(String currentLocalDateIso) async {
    final today = normalizeDateOnly(currentLocalDateIso);
    await _database.transaction(() async {
      await (_database.delete(
        _database.myDayEntries,
      )..where((entry) => entry.localDateIso.isSmallerThanValue(today))).go();
      final entries = _database.myDayEntries;
      final tasks = _database.tasks;
      final inactiveQuery =
          _database.select(entries).join([
            innerJoin(tasks, tasks.id.equalsExp(entries.taskId)),
          ])..where(
            entries.localDateIso.equals(today) &
                tasks.status.isNotValue(TaskStatus.active.databaseValue),
          );
      final inactiveIds = (await inactiveQuery.get())
          .map((row) => row.readTable(entries).id)
          .toList(growable: false);
      for (final entryId in inactiveIds) {
        await (_database.delete(
          entries,
        )..where((entry) => entry.id.equals(entryId))).go();
      }
      await _renumberMyDay(today);
    });
  }

  @override
  Future<void> updateTaskTitle(String taskId, String title) async {
    final normalizedTitle = normalizeRequiredTitle(title);
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      _ensureEditable(row);
      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(
          title: Value(normalizedTitle),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> updateTaskNotes(String taskId, String? notes) async {
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      _ensureEditable(row);
      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(
          notes: Value(notes == null || notes.trim().isEmpty ? null : notes),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      _ensureEditable(row);
      if (row.priority == priority.databaseValue) return;
      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(
          priority: Value(priority.databaseValue),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> updateTaskDueDate(String taskId, String? dueDateIso) async {
    final normalized = dueDateIso == null
        ? null
        : normalizeDateOnly(dueDateIso);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      _ensureEditable(row);
      final series = row.recurringSeriesId == null
          ? null
          : await _seriesRecord(row.recurringSeriesId!);
      final hasLaterOccurrence = series?.isActive == true
          ? await _hasLaterOccurrence(row)
          : false;
      if (series?.isActive == true && normalized == null) {
        throw const TaskRecurrenceRequiresDueDateException();
      }
      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(dueDateIso: Value(normalized), updatedAtUtc: Value(now)),
      );
      // A completed or superseded occurrence is history. Editing its due date
      // may change that task, but only the latest occurrence can move the
      // series anchor used to calculate future dates.
      if (series?.isActive == true &&
          !hasLaterOccurrence &&
          row.status == TaskStatus.active.databaseValue &&
          normalized != null) {
        await (_database.update(
          _database.recurrenceSeries,
        )..where((rule) => rule.id.equals(series!.id))).write(
          RecurrenceSeriesCompanion(
            anchorDueDateIso: Value(normalized),
            updatedAtUtc: Value(now),
          ),
        );
      }
    });
  }

  @override
  Future<void> updateTaskReminder(
    String taskId,
    DateTime? reminderAtUtc,
  ) async {
    final utcReminder = reminderAtUtc?.toUtc();
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      _ensureEditable(row);
      if (utcReminder != null && !utcReminder.isAfter(DateTime.now().toUtc())) {
        throw const ReminderMustBeFutureException();
      }
      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(
          reminderAtUtc: Value(utcReminder?.millisecondsSinceEpoch),
          updatedAtUtc: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> updateTaskRecurrence(
    String taskId,
    RecurrenceFrequency? frequency,
  ) async {
    await _database.transaction(() async {
      final task = await _taskRecord(taskId);
      _ensureEditable(task);
      if (task.status != TaskStatus.active.databaseValue) {
        throw const TaskUnavailableException();
      }
      if (frequency != null && task.dueDateIso == null) {
        throw const TaskRecurrenceRequiresDueDateException();
      }
      if (task.recurringSeriesId != null && await _hasLaterOccurrence(task)) {
        throw const TaskRecurrenceHistoryException();
      }

      final existing = task.recurringSeriesId == null
          ? null
          : await _seriesRecord(task.recurringSeriesId!);
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      if (frequency == null) {
        if (existing?.isActive == true) {
          await (_database.update(
            _database.recurrenceSeries,
          )..where((series) => series.id.equals(existing!.id))).write(
            RecurrenceSeriesCompanion(
              isActive: const Value(false),
              updatedAtUtc: Value(now),
            ),
          );
        }
      } else if (existing?.isActive == true) {
        await (_database.update(
          _database.recurrenceSeries,
        )..where((series) => series.id.equals(existing!.id))).write(
          RecurrenceSeriesCompanion(
            frequency: Value(frequency.databaseValue),
            anchorDueDateIso: Value(task.dueDateIso!),
            updatedAtUtc: Value(now),
          ),
        );
      } else {
        final seriesId = _uuid.v4();
        await _database
            .into(_database.recurrenceSeries)
            .insert(
              RecurrenceSeriesCompanion.insert(
                id: seriesId,
                frequency: frequency.databaseValue,
                anchorDueDateIso: task.dueDateIso!,
                createdAtUtc: now,
                updatedAtUtc: now,
              ),
            );
        await (_database.update(
          _database.tasks,
        )..where((row) => row.id.equals(taskId))).write(
          TasksCompanion(
            recurringSeriesId: Value(seriesId),
            updatedAtUtc: Value(now),
          ),
        );
      }
      await (_database.update(_database.tasks)
            ..where((row) => row.id.equals(taskId)))
          .write(TasksCompanion(updatedAtUtc: Value(now)));
    });
  }

  @override
  Future<void> setTaskCompleted(String taskId, bool isCompleted) async {
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      _ensureEditable(row);
      final nextStatus = isCompleted ? TaskStatus.completed : TaskStatus.active;
      if (row.status == nextStatus.databaseValue) return;

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(nextStatus.databaseValue),
          completedAtUtc: Value(isCompleted ? now : null),
          updatedAtUtc: Value(now),
        ),
      );
      if (isCompleted) {
        await _removeTaskFromMyDay(taskId);
        await _createNextOccurrence(row, now);
      }
    });
  }

  @override
  Future<void> moveTaskToTrash(String taskId) async {
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      if (row.status == TaskStatus.trashed.databaseValue) return;
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(TaskStatus.trashed.databaseValue),
          statusBeforeTrash: Value(row.status),
          deletedAtUtc: Value(now),
          updatedAtUtc: Value(now),
        ),
      );
      await _removeTaskFromMyDay(taskId);
    });
  }

  @override
  Future<void> restoreTask(String taskId) async {
    await _database.transaction(() async {
      final row = await _taskRecord(taskId);
      if (row.status != TaskStatus.trashed.databaseValue) return;

      final previousStatus = TaskStatus.fromDatabaseValue(
        row.statusBeforeTrash ?? TaskStatus.active.databaseValue,
      );
      final restoredStatus = previousStatus == TaskStatus.trashed
          ? TaskStatus.active
          : previousStatus;
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      await (_database.update(
        _database.tasks,
      )..where((task) => task.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(restoredStatus.databaseValue),
          statusBeforeTrash: const Value(null),
          deletedAtUtc: const Value(null),
          updatedAtUtc: Value(now),
        ),
      );
    });
  }

  @override
  Future<Subtask> addSubtask(String taskId, String title) async {
    final normalizedTitle = normalizeRequiredTitle(title);
    return _database.transaction(() async {
      final parent = await _taskRecord(taskId);
      _ensureEditable(parent);
      final lastSubtask =
          await (_database.select(_database.subtasks)
                ..where((subtask) => subtask.taskId.equals(taskId))
                ..orderBy([(subtask) => OrderingTerm.desc(subtask.position)])
                ..limit(1))
              .getSingleOrNull();
      final subtask = Subtask(
        id: _uuid.v4(),
        taskId: taskId,
        title: normalizedTitle,
        isCompleted: false,
        position: (lastSubtask?.position ?? -1) + 1,
      );

      await _database
          .into(_database.subtasks)
          .insert(
            SubtasksCompanion.insert(
              id: subtask.id,
              taskId: subtask.taskId,
              title: subtask.title,
              position: subtask.position,
            ),
          );
      return subtask;
    });
  }

  @override
  Future<void> updateSubtaskTitle(String subtaskId, String title) async {
    final normalizedTitle = normalizeRequiredTitle(title);
    await _database.transaction(() async {
      final row = await _subtaskRecord(subtaskId);
      final parent = await _taskRecord(row.taskId);
      _ensureEditable(parent);
      await (_database.update(_database.subtasks)
            ..where((subtask) => subtask.id.equals(subtaskId)))
          .write(SubtasksCompanion(title: Value(normalizedTitle)));
    });
  }

  @override
  Future<void> setSubtaskCompleted(String subtaskId, bool isCompleted) async {
    await _database.transaction(() async {
      final row = await _subtaskRecord(subtaskId);
      final parent = await _taskRecord(row.taskId);
      _ensureEditable(parent);
      await (_database.update(_database.subtasks)
            ..where((subtask) => subtask.id.equals(subtaskId)))
          .write(SubtasksCompanion(isCompleted: Value(isCompleted)));
    });
  }

  @override
  Future<void> removeSubtask(String subtaskId) async {
    await _database.transaction(() async {
      final row = await _subtaskRecord(subtaskId);
      final parent = await _taskRecord(row.taskId);
      _ensureEditable(parent);
      await (_database.delete(
        _database.subtasks,
      )..where((subtask) => subtask.id.equals(subtaskId))).go();
    });
  }

  @override
  Future<void> moveSubtask(
    String taskId,
    String subtaskId,
    int newPosition,
  ) async {
    await _database.transaction(() async {
      final parent = await _taskRecord(taskId);
      _ensureEditable(parent);
      final rows =
          await (_database.select(_database.subtasks)
                ..where((subtask) => subtask.taskId.equals(taskId))
                ..orderBy([
                  (subtask) => OrderingTerm.asc(subtask.position),
                  (subtask) => OrderingTerm.asc(subtask.id),
                ]))
              .get();
      final currentPosition = rows.indexWhere((row) => row.id == subtaskId);
      if (currentPosition < 0) throw const TaskNotFoundException();

      final reordered = List.of(rows);
      final moved = reordered.removeAt(currentPosition);
      reordered.insert(newPosition.clamp(0, reordered.length).toInt(), moved);
      for (var index = 0; index < rows.length; index++) {
        await (_database.update(_database.subtasks)
              ..where((subtask) => subtask.id.equals(rows[index].id)))
            .write(SubtasksCompanion(position: Value(-(index + 1))));
      }
      for (var index = 0; index < reordered.length; index++) {
        await (_database.update(_database.subtasks)
              ..where((subtask) => subtask.id.equals(reordered[index].id)))
            .write(SubtasksCompanion(position: Value(index)));
      }
    });
  }

  Future<void> _renumberMyDay(String localDateIso) async {
    final entries =
        await (_database.select(_database.myDayEntries)
              ..where((entry) => entry.localDateIso.equals(localDateIso))
              ..orderBy([
                (entry) => OrderingTerm.asc(entry.position),
                (entry) => OrderingTerm.asc(entry.id),
              ]))
            .get();
    for (var position = 0; position < entries.length; position++) {
      await (_database.update(_database.myDayEntries)
            ..where((entry) => entry.id.equals(entries[position].id)))
          .write(MyDayEntriesCompanion(position: Value(position)));
    }
  }

  Future<void> _removeTaskFromMyDay(String taskId) async {
    final entries = await (_database.select(
      _database.myDayEntries,
    )..where((entry) => entry.taskId.equals(taskId))).get();
    await (_database.delete(
      _database.myDayEntries,
    )..where((entry) => entry.taskId.equals(taskId))).go();
    for (final date in entries.map((entry) => entry.localDateIso).toSet()) {
      await _renumberMyDay(date);
    }
  }

  Future<void> _createNextOccurrence(TaskRecord completed, int nowUtc) async {
    final seriesId = completed.recurringSeriesId;
    final dueDateIso = completed.dueDateIso;
    if (seriesId == null || dueDateIso == null) return;

    final series = await _seriesRecord(seriesId);
    if (series == null || !series.isActive) return;
    final frequency = RecurrenceFrequency.fromDatabaseValue(series.frequency);
    final nextDueDateIso = nextOccurrenceDueDate(
      frequency: frequency,
      anchorDueDateIso: series.anchorDueDateIso,
      currentDueDateIso: dueDateIso,
      todayIso: formatDateOnly(DateTime.now()),
    );

    final seriesOccurrences = await (_database.select(
      _database.tasks,
    )..where((task) => task.recurringSeriesId.equals(seriesId))).get();
    final hasLaterOccurrence = seriesOccurrences.any(
      (occurrence) =>
          occurrence.id != completed.id &&
          occurrence.createdAtUtc > completed.createdAtUtc,
    );
    final hasActiveOccurrence = seriesOccurrences.any(
      (occurrence) => occurrence.status == TaskStatus.active.databaseValue,
    );
    if (hasLaterOccurrence || hasActiveOccurrence) return;

    // createdAtUtc is the sequence marker for occurrences and is stored with
    // millisecond precision. Keep it strictly increasing even if the clock
    // moves backwards or two transitions share the same millisecond, so a
    // later occurrence is never mistaken for history during a re-open.
    final latestCreatedAtUtc = seriesOccurrences.fold<int>(
      completed.createdAtUtc,
      (latest, occurrence) =>
          occurrence.createdAtUtc > latest ? occurrence.createdAtUtc : latest,
    );
    final nextCreatedAtUtc = nowUtc > latestCreatedAtUtc
        ? nowUtc
        : latestCreatedAtUtc + 1;

    final sameListTasks = await _tasksInList(completed.listId);
    final position =
        sameListTasks.fold<int>(
          -1,
          (maximum, task) => task.position > maximum ? task.position : maximum,
        ) +
        1;
    final reminderAtUtc = _nextOccurrenceReminder(
      reminderAtUtc: completed.reminderAtUtc,
      currentDueDateIso: dueDateIso,
      nextDueDateIso: nextDueDateIso,
    );
    final nextTaskId = _uuid.v4();
    await _database
        .into(_database.tasks)
        .insert(
          TasksCompanion.insert(
            id: nextTaskId,
            title: completed.title,
            notes: Value(completed.notes),
            status: Value(TaskStatus.active.databaseValue),
            priority: Value(completed.priority),
            listId: Value(completed.listId),
            categoryId: Value(completed.categoryId),
            dueDateIso: Value(nextDueDateIso),
            reminderAtUtc: Value(reminderAtUtc),
            recurringSeriesId: Value(seriesId),
            createdAtUtc: nextCreatedAtUtc,
            updatedAtUtc: nextCreatedAtUtc,
            position: Value(position),
          ),
        );
    final assignments = await (_database.select(
      _database.taskTags,
    )..where((assignment) => assignment.taskId.equals(completed.id))).get();
    for (final assignment in assignments) {
      await _database
          .into(_database.taskTags)
          .insert(
            TaskTagsCompanion.insert(
              taskId: nextTaskId,
              tagId: assignment.tagId,
            ),
          );
    }
  }

  Future<List<TaskRecord>> _tasksInList(String? listId) {
    final query = _database.select(_database.tasks);
    if (listId == null) {
      query.where((task) => task.listId.isNull());
    } else {
      query.where((task) => task.listId.equals(listId));
    }
    return query.get();
  }

  Future<RecurrenceSeriesRecord?> _seriesRecord(String seriesId) =>
      (_database.select(
        _database.recurrenceSeries,
      )..where((series) => series.id.equals(seriesId))).getSingleOrNull();

  Future<bool> _hasLaterOccurrence(TaskRecord task) async {
    final seriesId = task.recurringSeriesId;
    if (seriesId == null) return false;
    final laterOccurrence =
        await (_database.select(_database.tasks)
              ..where(
                (occurrence) =>
                    occurrence.recurringSeriesId.equals(seriesId) &
                    occurrence.createdAtUtc.isBiggerThanValue(
                      task.createdAtUtc,
                    ),
              )
              ..limit(1))
            .getSingleOrNull();
    return laterOccurrence != null;
  }

  int? _nextOccurrenceReminder({
    required int? reminderAtUtc,
    required String currentDueDateIso,
    required String nextDueDateIso,
  }) {
    if (reminderAtUtc == null) return null;
    final reminderLocal = DateTime.fromMillisecondsSinceEpoch(
      reminderAtUtc,
      isUtc: true,
    ).toLocal();
    final currentDue = parseDateOnly(currentDueDateIso);
    final reminderDate = DateTime.utc(
      reminderLocal.year,
      reminderLocal.month,
      reminderLocal.day,
    );
    final dayOffset = reminderDate.difference(currentDue).inDays;
    final nextDue = parseDateOnly(nextDueDateIso)
        .add(Duration(days: dayOffset));
    return DateTime(
      nextDue.year,
      nextDue.month,
      nextDue.day,
      reminderLocal.hour,
      reminderLocal.minute,
      reminderLocal.second,
      reminderLocal.millisecond,
      reminderLocal.microsecond,
    ).toUtc().millisecondsSinceEpoch;
  }

  Future<TaskRecord> _taskRecord(String taskId) async {
    final row = await (_database.select(
      _database.tasks,
    )..where((task) => task.id.equals(taskId))).getSingleOrNull();
    if (row == null) throw const TaskNotFoundException();
    return row;
  }

  Future<SubtaskRecord> _subtaskRecord(String subtaskId) async {
    final row = await (_database.select(
      _database.subtasks,
    )..where((subtask) => subtask.id.equals(subtaskId))).getSingleOrNull();
    if (row == null) throw const TaskNotFoundException();
    return row;
  }

  void _ensureEditable(TaskRecord task) {
    if (task.status == TaskStatus.trashed.databaseValue) {
      throw const TaskUnavailableException();
    }
  }

  Task _taskFromRow(
    TaskRecord row, {
    RecurrenceSeriesRecord? recurrenceSeries,
  }) => Task(
    id: row.id,
    title: row.title,
    notes: row.notes,
    status: TaskStatus.fromDatabaseValue(row.status),
    priority: TaskPriority.fromDatabaseValue(row.priority),
    listId: row.listId,
    categoryId: row.categoryId,
    dueDateIso: row.dueDateIso,
    reminderAtUtc: _dateTimeFromMilliseconds(row.reminderAtUtc),
    recurringSeriesId: row.recurringSeriesId,
    recurrenceFrequency: recurrenceSeries == null
        ? null
        : RecurrenceFrequency.fromDatabaseValue(recurrenceSeries.frequency),
    recurrenceActive: recurrenceSeries?.isActive ?? false,
    createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtc,
      isUtc: true,
    ),
    updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.updatedAtUtc,
      isUtc: true,
    ),
    completedAtUtc: _dateTimeFromMilliseconds(row.completedAtUtc),
    position: row.position,
    statusBeforeTrash: row.statusBeforeTrash == null
        ? null
        : TaskStatus.fromDatabaseValue(row.statusBeforeTrash!),
    deletedAtUtc: _dateTimeFromMilliseconds(row.deletedAtUtc),
  );

  Subtask _subtaskFromRow(SubtaskRecord row) => Subtask(
    id: row.id,
    taskId: row.taskId,
    title: row.title,
    isCompleted: row.isCompleted,
    position: row.position,
  );

  DateTime? _dateTimeFromMilliseconds(int? value) => value == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
}
