import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/data_snapshot.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/snapshot_codec.dart';

DataSnapshot sampleSnapshot() => DataSnapshot(
      formatVersion: snapshotFormatVersion,
      exportedAt: '2026-09-24T18:30:00.000Z',
      tasks: [
        TaskData(
          id: 'task-1',
          title: 'Reunião',
          notes: 'discutar orçamento',
          status: 'active',
          priority: 'urgent',
          dueDate: '2026-10-01',
          reminder: '2026-09-30T12:00:00.000Z',
          listId: 'list-1',
          categoryId: 'cat-1',
          seriesId: null,
          position: 0,
          createdAt: '2026-09-01T10:00:00.000Z',
          updatedAt: null,
          completedAt: null,
          deletedAt: null,
        ),
        TaskData(
          id: 'task-2',
          title: 'Concluída',
          notes: null,
          status: 'completed',
          priority: 'low',
          dueDate: null,
          reminder: null,
          listId: null,
          categoryId: null,
          seriesId: 'series-1',
          position: 1,
          createdAt: '2026-09-02T10:00:00.000Z',
          updatedAt: '2026-09-03T10:00:00.000Z',
          completedAt: '2026-09-03T10:00:00.000Z',
          deletedAt: null,
        ),
        TaskData(
          id: 'task-3',
          title: 'Na lixeira',
          notes: null,
          status: 'active',
          priority: 'medium',
          dueDate: null,
          reminder: null,
          listId: 'list-1',
          categoryId: null,
          seriesId: null,
          position: 2,
          createdAt: '2026-09-04T10:00:00.000Z',
          updatedAt: null,
          completedAt: null,
          deletedAt: '2026-09-05T10:00:00.000Z',
        ),
      ],
      subtasks: const [
        SubtaskData(
          id: 'sub-1',
          taskId: 'task-1',
          title: 'Preparar pauta',
          isCompleted: true,
          position: 0,
        ),
      ],
      lists: const [
        ListData(id: 'list-1', name: 'Trabalho', position: 0, groupId: 'g-1'),
      ],
      groups: const [
        GroupData(id: 'g-1', name: 'Projetos', position: 0),
      ],
      categories: const [
        CategoryData(id: 'cat-1', name: 'Casa'),
      ],
      tags: const [
        TagData(id: 'tag-1', name: 'urgente'),
      ],
      taskTags: const [
        TaskTagData(taskId: 'task-1', tagId: 'tag-1'),
      ],
      series: const [
        SeriesData(
          id: 'series-1',
          frequency: 'weekly',
          anchorDate: '2026-09-01',
          active: true,
        ),
      ],
      myDayEntries: const [
        MyDayEntryData(
          id: 'md-1',
          taskId: 'task-1',
          date: '2026-09-24',
          position: 0,
        ),
      ],
    );

void main() {
  group('RF-10 — formato aberto versão 1', () {
    test('CA-01/CA-05 — roundtrip preserva conjunto, UUIDs e relações', () {
      final original = sampleSnapshot();
      final decoded = decodeSnapshot(encodeSnapshot(original));

      expect(decoded.formatVersion, 1);
      expect(decoded.exportedAt, original.exportedAt);
      // Reencodar o decodificado deve reproduzir exatamente o documento —
      // prova de preservação de UUIDs, relações e campos (CA-01).
      expect(encodeSnapshot(decoded), encodeSnapshot(original));
    });

    test('CA-03 — semântica temporal preservada como texto lógico', () {
      final decoded = decodeSnapshot(encodeSnapshot(sampleSnapshot()));
      final task = decoded.tasks.firstWhere((t) => t.id == 'task-1');
      expect(task.dueDate, '2026-10-01'); // data local
      expect(task.reminder, '2026-09-30T12:00:00.000Z'); // instante UTC
      expect(decoded.myDayEntries.single.date, '2026-09-24');
      expect(decoded.series.single.anchorDate, '2026-09-01');
    });

    test('estrutura sempre inclui todos os arrays, mesmo vazios', () {
      final empty = DataSnapshot(
        formatVersion: snapshotFormatVersion,
        exportedAt: '2026-09-24T00:00:00.000Z',
        tasks: const [],
        subtasks: const [],
        lists: const [],
        groups: const [],
        categories: const [],
        tags: const [],
        taskTags: const [],
        series: const [],
        myDayEntries: const [],
      );
      final decoded = decodeSnapshot(encodeSnapshot(empty));
      expect(decoded.tasks, isEmpty);
      expect(decoded.myDayEntries, isEmpty);
      expect(summarize(decoded, isBackup: false).activeTasks, 0);
    });

    test('CA-07 — resumo conta tarefas por estado', () {
      final summary = summarize(sampleSnapshot(), isBackup: false);
      expect(summary.activeTasks, 1);
      expect(summary.completedTasks, 1);
      expect(summary.trashedTasks, 1);
      expect(summary.subtasks, 1);
      expect(summary.lists, 1);
      expect(summary.groups, 1);
      expect(summary.categories, 1);
      expect(summary.tags, 1);
      expect(summary.series, 1);
      expect(summary.myDayEntries, 1);
      expect(summary.isBackup, isFalse);
    });
  });

  group('RF-13/RF-17 — validação (CA-12, CA-13)', () {
    test('CA-12 — JSON malformado', () {
      expect(
        () => decodeSnapshot('{not json'),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.malformed)),
      );
    });

    test('CA-13 — versão desconhecida ou mais nova', () {
      final future = encodeSnapshot(sampleSnapshot())
          .replaceFirst('"format_version": 1', '"format_version": 99');
      expect(
        () => decodeSnapshot(future),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.unsupportedVersion)),
      );
    });

    test('CA-12 — UUID duplicado', () {
      final json = encodeSnapshot(sampleSnapshot()).replaceFirst(
        '"id": "task-2"',
        '"id": "task-1"',
      );
      expect(
        () => decodeSnapshot(json),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.duplicateId)),
      );
    });

    test('CA-12 — referência inconsistente', () {
      final json = encodeSnapshot(sampleSnapshot()).replaceFirst(
        '"list_id": "list-1"',
        '"list_id": "missing-list"',
      );
      expect(
        () => decodeSnapshot(json),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.danglingReference)),
      );
    });

    test('campo desconhecido não é descartado silenciosamente', () {
      final json = encodeSnapshot(sampleSnapshot()).replaceFirst(
        '"title": "Reunião"',
        '"title": "Reunião", "mystery": 1',
      );
      expect(
        () => decodeSnapshot(json),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.unknownField)),
      );
    });

    test('tipos inválidos', () {
      final json = encodeSnapshot(sampleSnapshot()).replaceFirst(
        '"position": 0',
        '"position": "zero"',
      );
      expect(
        () => decodeSnapshot(json),
        throwsA(isA<SnapshotException>().having(
            (e) => e.error, 'error', SnapshotError.wrongType)),
      );
    });
  });
}
