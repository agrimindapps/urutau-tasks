import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../data_transfer/domain/data_snapshot.dart';
import '../../data_transfer/domain/snapshot_codec.dart';
import '../../data_transfer/domain/snapshot_repository.dart';

/// Implementação Drift do retrato lógico (spec 07).
class DriftSnapshotRepository implements SnapshotRepository {
  DriftSnapshotRepository(this._db);

  final AppDatabase _db;

  static String _iso(DateTime moment) => moment.toUtc().toIso8601String();

  @override
  Future<DataSnapshot> loadSnapshot() async {
    final taskRows = await _db.select(_db.tasks).get();
    final subtaskRows = await _db.select(_db.subtasks).get();
    final listRows = await _db.select(_db.taskLists).get();
    final groupRows = await _db.select(_db.groups).get();
    final categoryRows = await _db.select(_db.categories).get();
    final tagRows = await _db.select(_db.tags).get();
    final taskTagRows = await _db.select(_db.taskTags).get();
    final seriesRows = await _db.select(_db.series).get();
    final myDayRows = await _db.select(_db.myDayEntries).get();

    return DataSnapshot(
      formatVersion: snapshotFormatVersion,
      exportedAt: _iso(DateTime.now()),
      tasks: [
        for (final row in taskRows)
          TaskData(
            id: row.id,
            title: row.title,
            notes: row.notes,
            status: row.status,
            priority: row.priority,
            dueDate: row.dueDate,
            reminder: row.reminder == null ? null : _iso(row.reminder!),
            listId: row.listId,
            categoryId: row.categoryId,
            seriesId: row.seriesId,
            position: row.position,
            createdAt: _iso(row.createdAt),
            updatedAt: row.updatedAt == null ? null : _iso(row.updatedAt!),
            completedAt:
                row.completedAt == null ? null : _iso(row.completedAt!),
            deletedAt: row.deletedAt == null ? null : _iso(row.deletedAt!),
          ),
      ],
      subtasks: [
        for (final row in subtaskRows)
          SubtaskData(
            id: row.id,
            taskId: row.taskId,
            title: row.title,
            isCompleted: row.isCompleted,
            position: row.position,
          ),
      ],
      lists: [
        for (final row in listRows)
          ListData(
            id: row.id,
            name: row.name,
            position: row.position,
            groupId: row.groupId,
          ),
      ],
      groups: [
        for (final row in groupRows)
          GroupData(id: row.id, name: row.name, position: row.position),
      ],
      categories: [
        for (final row in categoryRows)
          CategoryData(id: row.id, name: row.name),
      ],
      tags: [for (final row in tagRows) TagData(id: row.id, name: row.name)],
      taskTags: [
        for (final row in taskTagRows)
          TaskTagData(taskId: row.taskId, tagId: row.tagId),
      ],
      series: [
        for (final row in seriesRows)
          SeriesData(
            id: row.id,
            frequency: row.frequency,
            anchorDate: row.anchorDate,
            active: row.active,
          ),
      ],
      myDayEntries: [
        for (final row in myDayRows)
          MyDayEntryData(
            id: row.id,
            taskId: row.taskId,
            date: row.date,
            position: row.position,
          ),
      ],
    );
  }

  @override
  Future<void> replaceAll(DataSnapshot snapshot) {
    return _db.transaction(() async {
      // Remoção na ordem inversa das referências (spec 06, RF-17).
      await _db.delete(_db.taskTags).go();
      await _db.delete(_db.myDayEntries).go();
      await _db.delete(_db.subtasks).go();
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.taskLists).go();
      await _db.delete(_db.groups).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.tags).go();
      await _db.delete(_db.series).go();

      await _db.batch((batch) {
        batch.insertAll(_db.groups, [
          for (final g in snapshot.groups)
            GroupsCompanion.insert(
              id: g.id,
              name: g.name,
              position: Value(g.position),
            ),
        ]);
        batch.insertAll(_db.taskLists, [
          for (final l in snapshot.lists)
            TaskListsCompanion.insert(
              id: l.id,
              name: l.name,
              position: Value(l.position),
              groupId: Value(l.groupId),
            ),
        ]);
        batch.insertAll(_db.categories, [
          for (final c in snapshot.categories)
            CategoriesCompanion.insert(id: c.id, name: c.name),
        ]);
        batch.insertAll(_db.tags, [
          for (final t in snapshot.tags)
            TagsCompanion.insert(id: t.id, name: t.name),
        ]);
        batch.insertAll(_db.series, [
          for (final s in snapshot.series)
            SeriesCompanion.insert(
              id: s.id,
              frequency: s.frequency,
              anchorDate: s.anchorDate,
              active: Value(s.active),
            ),
        ]);
        batch.insertAll(_db.tasks, [
          for (final t in snapshot.tasks)
            TasksCompanion.insert(
              id: t.id,
              title: t.title,
              notes: Value(t.notes),
              status: Value(t.status),
              priority: Value(t.priority),
              dueDate: Value(t.dueDate),
              reminder: Value(t.reminder == null
                  ? null
                  : DateTime.parse(t.reminder!).toLocal()),
              createdAt: DateTime.parse(t.createdAt).toLocal(),
              updatedAt: Value(t.updatedAt == null
                  ? null
                  : DateTime.parse(t.updatedAt!).toLocal()),
              completedAt: Value(t.completedAt == null
                  ? null
                  : DateTime.parse(t.completedAt!).toLocal()),
              deletedAt: Value(t.deletedAt == null
                  ? null
                  : DateTime.parse(t.deletedAt!).toLocal()),
              position: Value(t.position),
              listId: Value(t.listId),
              categoryId: Value(t.categoryId),
              seriesId: Value(t.seriesId),
            ),
        ]);
        batch.insertAll(_db.subtasks, [
          for (final s in snapshot.subtasks)
            SubtasksCompanion.insert(
              id: s.id,
              taskId: s.taskId,
              title: s.title,
              isCompleted: Value(s.isCompleted),
              position: Value(s.position),
            ),
        ]);
        batch.insertAll(_db.taskTags, [
          for (final tt in snapshot.taskTags)
            TaskTagsCompanion.insert(taskId: tt.taskId, tagId: tt.tagId),
        ]);
        batch.insertAll(_db.myDayEntries, [
          for (final e in snapshot.myDayEntries)
            MyDayEntriesCompanion.insert(
              id: e.id,
              taskId: e.taskId,
              date: e.date,
              position: Value(e.position),
            ),
        ]);
      });
    });
  }
}
