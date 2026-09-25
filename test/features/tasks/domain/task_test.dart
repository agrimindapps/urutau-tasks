import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/task_fixtures.dart';

void main() {
  group('Criação e validação de título (RF-01, CA-01, CA-02)', () {
    test('cria tarefa ativa com título válido', () {
      final task = Task.create(
        id: 't1',
        title: '  Comprar café  ',
        createdAt: kTestNow,
      );
      expect(task.title, 'Comprar café');
      expect(task.status, TaskStatus.active);
      expect(task.subtasks, isEmpty);
      expect(task.progress, isNull);
    });

    test('rejeita título vazio ou só espaços', () {
      for (final invalid in ['', '   ', '\t\n']) {
        expect(
          () => Task.create(id: 't1', title: invalid, createdAt: kTestNow),
          throwsA(isA<TaskException>().having(
            (e) => e.failure,
            'failure',
            TaskFailure.emptyTitle,
          )),
          reason: 'título "$invalid" deveria ser rejeitado',
        );
      }
    });

    test('rejeita título vazio na edição', () {
      final task = buildTask(id: 't1', title: 'Válida');
      expect(
        () => task.rename(title: '  ', at: kTestNow),
        throwsA(isA<TaskException>().having(
          (e) => e.failure,
          'failure',
          TaskFailure.emptyTitle,
        )),
      );
    });

    test('edição preserva identidade e subtarefas (RF-03)', () {
      final task = buildTask(id: 't1', title: 'Antes').addSubtask(
        id: 's1',
        description: 'Etapa',
      );
      final edited = task.rename(
        title: 'Depois',
        notes: 'Observações',
        at: kTestNow.add(const Duration(minutes: 5)),
      );
      expect(edited.id, 't1');
      expect(edited.title, 'Depois');
      expect(edited.notes, 'Observações');
      expect(edited.subtasks, task.subtasks);
    });
  });

  group('Transições de estado (RF-02)', () {
    test('concluir e reabrir preservam estados das subtarefas (CA-08)', () {
      var task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Feita')
          .addSubtask(id: 's2', description: 'Pendente');
      task = task.updateSubtask(task.subtasks.first.complete());

      final completed = task.complete(at: kTestNow);
      expect(completed.status, TaskStatus.completed);
      expect(completed.completedAt, kTestNow);
      expect(completed.subtasks.map((s) => s.isCompleted), [true, false]);

      final reopened = completed.reopen(at: kTestNow);
      expect(reopened.status, TaskStatus.active);
      expect(reopened.completedAt, isNull);
      expect(reopened.subtasks.map((s) => s.isCompleted), [true, false]);
    });

    test('concluir não altera subtarefas (RF-04)', () {
      final task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Etapa');
      final completed = task.complete(at: kTestNow);
      expect(completed.subtasks.first.isCompleted, isFalse);
    });

    test('concluir com subtarefas pendentes é permitido (CA-07)', () {
      final task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Pendente');
      expect(() => task.complete(at: kTestNow), returnsNormally);
    });

    test('transições inválidas são rejeitadas', () {
      final active = buildTask(id: 't1', title: 'T');
      expect(() => active.reopen(at: kTestNow), throwsA(isA<TaskException>()));

      final completed = active.complete(at: kTestNow);
      expect(
        () => completed.complete(at: kTestNow),
        throwsA(isA<TaskException>()),
      );

      final trashed = active.moveToTrash(at: kTestNow);
      expect(
        () => trashed.complete(at: kTestNow),
        throwsA(isA<TaskException>()),
      );
      expect(
        () => trashed.moveToTrash(at: kTestNow),
        throwsA(isA<TaskException>()),
      );
    });
  });

  group('Subtarefas (RF-05 a RF-08)', () {
    test('adiciona etapa no final da ordem (CA-03)', () {
      final task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Primeira')
          .addSubtask(id: 's2', description: 'Segunda');
      expect(task.subtasks.map((s) => s.position), [0, 1]);
      expect(task.subtaskCount, 2);
    });

    test('rejeita etapa com título vazio', () {
      final task = buildTask(id: 't1', title: 'T');
      expect(
        () => task.addSubtask(id: 's1', description: '   '),
        throwsA(isA<TaskException>().having(
          (e) => e.failure,
          'failure',
          TaskFailure.emptyTitle,
        )),
      );
    });

    test('reordena preservando estados e títulos (CA-04)', () {
      var task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Uma')
          .addSubtask(id: 's2', description: 'Duas')
          .addSubtask(id: 's3', description: 'Três');
      task = task.updateSubtask(task.subtasks.first.complete());

      final reordered = task.reorderSubtasks(['s3', 's1', 's2']);
      expect(reordered.subtasks.map((s) => s.id), ['s3', 's1', 's2']);
      expect(reordered.subtasks.map((s) => s.position), [0, 1, 2]);
      expect(reordered.subtasks.map((s) => s.isCompleted), [false, true, false]);
      expect(reordered.subtasks.map((s) => s.description), ['Três', 'Uma', 'Duas']);
    });

    test('remoção individual é definitiva e sai do progresso (CA-05)', () {
      var task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Fica')
          .addSubtask(id: 's2', description: 'Sai');
      task = task.updateSubtask(task.subtasks.first.complete());

      final after = task.removeSubtask('s2');
      expect(after.subtasks.map((s) => s.id), ['s1']);
      expect(after.progress, 1.0);
    });

    test('progresso é concluídas/total (CA-06)', () {
      var task = buildTask(id: 't1', title: 'T');
      for (var i = 0; i < 5; i++) {
        task = task.addSubtask(id: 's$i', description: 'Etapa $i');
      }
      for (var i = 0; i < 2; i++) {
        task = task.updateSubtask(task.subtasks[i].complete());
      }
      expect(task.completedSubtaskCount, 2);
      expect(task.subtaskCount, 5);
      expect(task.progress, 0.4);
    });

    test('sem subtarefas não há progresso artificial (RF-08)', () {
      expect(buildTask(title: 'T').progress, isNull);
    });

    test('rejeita reorder com conjunto de ids inválido', () {
      final task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Uma')
          .addSubtask(id: 's2', description: 'Duas');
      expect(
        () => task.reorderSubtasks(['s1']),
        throwsA(isA<TaskException>()),
      );
      expect(
        () => task.reorderSubtasks(['s1', 's9']),
        throwsA(isA<TaskException>()),
      );
    });
  });

  group('Lixeira e restauração (RF-09, RF-10, CA-09, CA-10)', () {
    test('mover para lixeira preserva hierarquia e dados', () {
      var task = buildTask(id: 't1', title: 'T', notes: 'N')
          .addSubtask(id: 's1', description: 'Uma')
          .addSubtask(id: 's2', description: 'Duas');
      task = task.updateSubtask(task.subtasks.last.complete());

      final trashed = task.moveToTrash(at: kTestNow);
      expect(trashed.status, TaskStatus.trash);
      expect(trashed.statusBeforeTrash, TaskStatus.active);
      expect(trashed.notes, 'N');
      expect(trashed.subtasks.map((s) => s.id), ['s1', 's2']);
      expect(trashed.subtasks.map((s) => s.isCompleted), [false, true]);
      expect(trashed.subtasks.map((s) => s.position), [0, 1]);
    });

    test('restaura ativa com estados anteriores', () {
      var task = buildTask(id: 't1', title: 'T')
          .addSubtask(id: 's1', description: 'Uma');
      task = task.updateSubtask(task.subtasks.first.complete());
      final trashed = task.moveToTrash(at: kTestNow);
      final restored = trashed.restore(at: kTestNow);
      expect(restored.status, TaskStatus.active);
      expect(restored.statusBeforeTrash, isNull);
      expect(restored.subtasks.first.isCompleted, isTrue);
    });

    test('restaura concluída para concluída', () {
      final completed = buildTask(id: 't1', title: 'T').complete(at: kTestNow);
      final trashed = completed.moveToTrash(at: kTestNow);
      final restored = trashed.restore(at: kTestNow);
      expect(restored.status, TaskStatus.completed);
      expect(restored.completedAt, completed.completedAt);
    });

    test('não edita tarefa na lixeira (RF-01)', () {
      final trashed =
          buildTask(id: 't1', title: 'T').moveToTrash(at: kTestNow);
      expect(
        () => trashed.rename(title: 'Nova', at: kTestNow),
        throwsA(isA<TaskException>().having(
          (e) => e.failure,
          'failure',
          TaskFailure.editInTrash,
        )),
      );
      expect(
        () => trashed.addSubtask(id: 's1', description: 'Etapa'),
        throwsA(isA<TaskException>().having(
          (e) => e.failure,
          'failure',
          TaskFailure.editInTrash,
        )),
      );
    });

    test('restaurar fora da lixeira é transição inválida', () {
      expect(
        () => buildTask(title: 'T').restore(at: kTestNow),
        throwsA(isA<TaskException>()),
      );
    });
  });
}
