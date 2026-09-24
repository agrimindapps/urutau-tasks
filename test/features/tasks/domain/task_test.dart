import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/task_fixtures.dart';

void main() {
  group('RF-01 / CA-01 / CA-02 — título obrigatório', () {
    test('CA-01 cria tarefa ativa com título válido', () {
      final task = Task(
        id: 't1',
        title: '  Comprar pão  ',
        createdAt: DateTime.utc(2026, 9, 24),
      );

      expect(task.title, 'Comprar pão');
      expect(task.status, TaskStatus.active);
      expect(task.isDeleted, isFalse);
    });

    test('CA-02 rejeita título vazio ou só espaços', () {
      expect(
        () => Task(id: 't1', title: '', createdAt: DateTime.utc(2026)),
        throwsA(isA<InvalidTitleException>()),
      );
      expect(
        () => Task(id: 't1', title: '   ', createdAt: DateTime.utc(2026)),
        throwsA(isA<InvalidTitleException>()),
      );
      expect(() => normalizeTitle(' \t '), throwsA(isA<InvalidTitleException>()));
    });
  });

  group('RF-04 / CA-07 / CA-08 — conclusão e reabertura', () {
    test('CA-07 concluir mantém subtarefas pendentes', () {
      final task = buildTestTask(
        subtasks: [
          buildTestSubtask(id: 's1', taskId: 'task-1', title: 'A'),
          buildTestSubtask(
            id: 's2',
            taskId: 'task-1',
            title: 'B',
            isCompleted: true,
          ),
        ],
      );
      final now = DateTime.utc(2026, 9, 24, 12);
      final completed = toggleTaskCompletion(task, now);

      expect(completed.status, TaskStatus.completed);
      expect(completed.completedAt, now);
      expect(
        completed.subtasks.map((s) => s.isCompleted),
        [false, true],
      );
    });

    test('CA-08 reabrir preserva estados das subtarefas', () {
      final task = buildTestTask(
        status: TaskStatus.completed,
        completedAt: DateTime.utc(2026, 9, 23),
        subtasks: [
          buildTestSubtask(
            id: 's1',
            taskId: 'task-1',
            title: 'A',
            isCompleted: true,
          ),
          buildTestSubtask(id: 's2', taskId: 'task-1', title: 'B'),
        ],
      );
      final reopened = toggleTaskCompletion(task, DateTime.utc(2026, 9, 24));

      expect(reopened.status, TaskStatus.active);
      expect(reopened.completedAt, isNull);
      expect(reopened.subtasks.map((s) => s.isCompleted), [true, false]);
    });

    test('tarefa na lixeira não muda de conclusão', () {
      final task = buildTestTask(deletedAt: DateTime.utc(2026, 9, 24));
      expect(
        () => toggleTaskCompletion(task, DateTime.utc(2026, 9, 24)),
        throwsStateError,
      );
    });
  });

  group('RF-08 / CA-06 — progresso', () {
    test('CA-06 exibe 2/5', () {
      final task = buildTestTask(
        subtasks: [
          for (var i = 0; i < 5; i++)
            buildTestSubtask(
              id: 's$i',
              taskId: 'task-1',
              title: 'Step $i',
              isCompleted: i < 2,
            ),
        ],
      );

      final progress = task.progress!;
      expect(formatProgress(progress), '2/5');
    });

    test('tarefa sem subtarefas não exibe progresso artificial', () {
      expect(buildTestTask().progress, isNull);
    });
  });

  group('RF-06 / CA-04 — reordenação', () {
    test('CA-04 mover subtarefa preserva títulos e estados', () {
      final subtasks = [
        buildTestSubtask(id: 's1', taskId: 'task-1', title: 'A'),
        buildTestSubtask(
          id: 's2',
          taskId: 'task-1',
          title: 'B',
          isCompleted: true,
        ),
        buildTestSubtask(id: 's3', taskId: 'task-1', title: 'C'),
      ];

      final reordered = reorderSubtasks(subtasks, 2, 0);

      expect(reordered.map((s) => s.title), ['C', 'A', 'B']);
      expect(reordered.map((s) => s.position), [0, 1, 2]);
      expect(reordered.map((s) => s.isCompleted), [false, false, true]);
      expect(reordered.map((s) => s.id), ['s3', 's1', 's2']);
    });
  });

  group('RF-09 / RF-10 / CA-09 / CA-10 — lixeira', () {
    test('CA-09 excluir preserva hierarquia e estados', () {
      final task = buildTestTask(
        subtasks: [
          buildTestSubtask(
            id: 's1',
            taskId: 'task-1',
            title: 'A',
            isCompleted: true,
          ),
          buildTestSubtask(id: 's2', taskId: 'task-1', title: 'B'),
        ],
      );
      final now = DateTime.utc(2026, 9, 24);
      final trashed = trashTask(task, now);

      expect(trashed.isDeleted, isTrue);
      expect(trashed.deletedAt, now);
      expect(trashed.status, TaskStatus.active);
      expect(trashed.subtasks, task.subtasks);
      expect(trashed.subtasks.map((s) => s.id), ['s1', 's2']);
      expect(trashed.subtasks.map((s) => s.isCompleted), [true, false]);
    });

    test('CA-10 restaurar recupera estado anterior', () {
      final task = buildTestTask(
        status: TaskStatus.completed,
        completedAt: DateTime.utc(2026, 9, 23),
        deletedAt: DateTime.utc(2026, 9, 24),
        subtasks: [
          buildTestSubtask(
            id: 's1',
            taskId: 'task-1',
            title: 'A',
            isCompleted: true,
          ),
        ],
      );
      final restored = restoreTask(task, DateTime.utc(2026, 9, 25));

      expect(restored.isDeleted, isFalse);
      expect(restored.status, TaskStatus.completed);
      expect(restored.completedAt, DateTime.utc(2026, 9, 23));
      expect(restored.subtasks.single.isCompleted, isTrue);
      expect(restored.id, task.id);
    });
  });
}
