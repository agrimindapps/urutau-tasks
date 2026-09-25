import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/search/domain/task_query.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/task_fixtures.dart';

void main() {
  const today = '2026-09-25';

  Task task(
    String id, {
    String title = 'Título',
    String notes = '',
    TaskStatus status = TaskStatus.active,
    TaskPriority? priority,
    String? dueDate,
    DateTime? reminder,
    String? listId,
    String? categoryId,
    List<String> tagIds = const [],
    String? seriesId,
    int position = 0,
    List<String> subtaskDescriptions = const [],
  }) {
    // Monta ativa e aplica as transições por último (lixeira bloqueia
    // edições — spec 01, RF-01).
    var result = buildTask(
      id: id,
      title: title,
      notes: notes,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      position: position,
    );
    result = result.assignList(listId);
    result = result.assignCategory(categoryId);
    for (final tag in tagIds) {
      result = result.addTagId(tag);
    }
    for (final description in subtaskDescriptions) {
      result =
          result.addSubtask(id: '$id-$description', description: description);
    }
    if (seriesId != null) {
      result = result.setSeries(seriesId);
    }
    if (status == TaskStatus.completed) {
      result = result.complete(at: kTestNow);
    } else if (status == TaskStatus.trash) {
      result = result.moveToTrash(at: kTestNow);
    }
    return result;
  }

  group('Busca textual (RF-01 a RF-05)', () {
    test('encontra por título, notas e subtarefa (CA-01/CA-02/CA-03)', () {
      final tasks = [
        task('t1', title: 'Comprar café'),
        task('t2', title: 'Outra', notes: 'detalhe do café'),
        task('t3', title: 'Outra', subtaskDescriptions: ['moer o café']),
      ];
      final result = searchTasks(tasks, text: 'café', today: today);
      expect(result.map((m) => m.task.id), ['t1', 't2', 't3']);
      expect(result.map((m) => m.field),
          [MatchField.title, MatchField.notes, MatchField.subtask]);
    });

    test('ignora maiúsculas e acentos (CA-04)', () {
      final tasks = [task('t1', title: 'Reunião de equipe')];
      expect(searchTasks(tasks, text: 'reuniao', today: today), hasLength(1));
      expect(searchTasks(tasks, text: 'REUNIÃO', today: today), hasLength(1));
      expect(searchTasks(tasks, text: 'equipe', today: today), hasLength(1));
    });

    test('correspondência parcial (CA-05)', () {
      final tasks = [task('t1', title: 'Relatório mensal')];
      expect(searchTasks(tasks, text: 'relat', today: today), hasLength(1));
      expect(searchTasks(tasks, text: 'mensal', today: today), hasLength(1));
    });

    test('resultado é sempre a tarefa principal (CA-18)', () {
      final tasks = [
        task('t1', title: 'Principal',
            subtaskDescriptions: ['etapa com termo especial']),
      ];
      final result = searchTasks(tasks, text: 'especial', today: today);
      expect(result.single.task.id, 't1');
    });

    test('lixeira nunca participa (CA-08)', () {
      final tasks = [
        task('t1', title: 'Na lixeira', status: TaskStatus.trash),
        task('t2', title: 'Na lixeira também'),
      ];
      final result = searchTasks(tasks, text: 'lixeira', today: today);
      expect(result, hasLength(1));
      expect(result.single.task.id, 't2');
    });

    test('busca vazia usa só os filtros (CA-06/RF-07)', () {
      final tasks = [task('t1'), task('t2', title: 'Outra')];
      final result = searchTasks(tasks, text: '', today: today);
      expect(result.map((m) => m.task.id), ['t1', 't2']);
    });
  });

  group('Filtros (RF-08 a RF-15)', () {
    test('status: ativas e concluídas (CA-09)', () {
      final tasks = [
        task('a', status: TaskStatus.active),
        task('c', status: TaskStatus.completed),
      ];
      final active = searchTasks(tasks,
          filter: const TaskFilter(statuses: {TaskStatus.active}),
          today: today);
      expect(active.map((m) => m.task.id), ['a']);

      final completed = searchTasks(tasks,
          filter: const TaskFilter(statuses: {TaskStatus.completed}),
          today: today);
      expect(completed.map((m) => m.task.id), ['c']);
    });

    test('categorias diferentes são AND, opções iguais são OR (CA-12)', () {
      final tasks = [
        task('t1', listId: 'l1', categoryId: 'c1'),
        task('t2', listId: 'l1', categoryId: 'c2'),
        task('t3', listId: 'l2', categoryId: 'c1'),
      ];
      // OR dentro de listas.
      final orResult = searchTasks(tasks,
          filter: const TaskFilter(listIds: {'l1', 'l2'}), today: today);
      expect(orResult, hasLength(3));

      // AND entre lista e categoria.
      final andResult = searchTasks(tasks,
          filter: const TaskFilter(listIds: {'l1'}, categoryIds: {'c1'}),
          today: today);
      expect(andResult.map((m) => m.task.id), ['t1']);
    });

    test('opção Sem lista (CA-11)', () {
      final tasks = [task('t1'), task('t2', listId: 'l1')];
      final result = searchTasks(tasks,
          filter: const TaskFilter(listIds: {kNoList}), today: today);
      expect(result.map((m) => m.task.id), ['t1']);
    });

    test('grupo considera suas listas; sem lista nunca entra (RF-10)', () {
      final tasks = [
        task('t1', listId: 'l1'),
        task('t2', listId: 'l2'),
        task('t3'),
      ];
      const context = QueryContext(
        listGroupId: {'l1': 'g1', 'l2': 'g2'},
      );
      final result = searchTasks(tasks,
          filter: const TaskFilter(groupIds: {'g1'}),
          context: context,
          today: today);
      expect(result.map((m) => m.task.id), ['t1']);
    });

    test('categoria e tags com opções sem (RF-11)', () {
      final tasks = [
        task('t1', categoryId: 'c1', tagIds: ['x']),
        task('t2'),
      ];
      final noCategory = searchTasks(tasks,
          filter: const TaskFilter(categoryIds: {kNoCategory}), today: today);
      expect(noCategory.map((m) => m.task.id), ['t2']);

      final noTags = searchTasks(tasks,
          filter: const TaskFilter(tagIds: {kNoTags}), today: today);
      expect(noTags.map((m) => m.task.id), ['t2']);

      final withTag = searchTasks(tasks,
          filter: const TaskFilter(tagIds: {'x'}), today: today);
      expect(withTag.map((m) => m.task.id), ['t1']);
    });

    test('prioridades em OR (CA-10)', () {
      final tasks = [
        task('t1', priority: TaskPriority.high),
        task('t2', priority: TaskPriority.low),
        task('t3', priority: TaskPriority.urgent),
      ];
      final result = searchTasks(tasks,
          filter: const TaskFilter(
              priorities: {TaskPriority.high, TaskPriority.urgent}),
          today: today);
      expect(result.map((m) => m.task.id).toSet(), {'t1', 't3'});
    });

    test('prazos relativos (CA-13)', () {
      final tasks = [
        task('late', dueDate: '2026-09-01'),
        task('today', dueDate: '2026-09-25'),
        task('soon', dueDate: '2026-09-28'),
        task('far', dueDate: '2026-11-01'),
        task('none'),
      ];
      List<String> ids(DueDateKind kind) => searchTasks(tasks,
              filter: TaskFilter(dueDateKind: kind), today: today)
          .map((m) => m.task.id)
          .toList();

      expect(ids(DueDateKind.none), ['none']);
      expect(ids(DueDateKind.overdue), ['late']);
      expect(ids(DueDateKind.today), ['today']);
      // Amanhã (26) até +7 (02/10), inclusivo.
      expect(ids(DueDateKind.next7Days), ['soon']);
      // Intervalo sem limites = todas as com prazo (limites inclusivos).
      expect(ids(DueDateKind.range), ['late', 'today', 'soon', 'far']);
    });

    test('intervalo personalizado com limites inclusivos (CA-14)', () {
      final tasks = [
        task('t1', dueDate: '2026-09-20'),
        task('t2', dueDate: '2026-09-25'),
        task('t3', dueDate: '2026-09-30'),
        task('t4', dueDate: '2026-10-05'),
      ];
      final result = searchTasks(
        tasks,
        filter: const TaskFilter(
          dueDateKind: DueDateKind.range,
          dueDateFrom: '2026-09-25',
          dueDateTo: '2026-09-30',
        ),
        today: today,
      );
      expect(result.map((m) => m.task.id), ['t2', 't3']);
    });

    test('concluída com prazo passado não é atrasada (CA-20)', () {
      final tasks = [
        task('t1', status: TaskStatus.completed, dueDate: '2026-09-01'),
      ];
      final result = searchTasks(tasks,
          filter: const TaskFilter(dueDateKind: DueDateKind.overdue),
          today: today);
      expect(result, isEmpty);
    });

    test('lembrete: com e sem (CA-15)', () {
      final tasks = [
        task('t1', reminder: DateTime.utc(2026, 9, 26)),
        task('t2'),
      ];
      final withReminder = searchTasks(tasks,
          filter: const TaskFilter(reminderFilter: ReminderFilter.withReminder),
          today: today);
      expect(withReminder.map((m) => m.task.id), ['t1']);

      final without = searchTasks(tasks,
          filter:
              const TaskFilter(reminderFilter: ReminderFilter.withoutReminder),
          today: today);
      expect(without.map((m) => m.task.id), ['t2']);
    });

    test('recorrência: ativa, cancelada e nenhuma (CA-16)', () {
      final tasks = [
        task('t1', seriesId: 's1'),
        task('t2', seriesId: 's2'),
        task('t3'),
      ];
      const context = QueryContext(seriesCancelled: {'s1': false, 's2': true});

      final active = searchTasks(tasks,
          filter: const TaskFilter(recurrenceFilter: RecurrenceFilter.active),
          context: context,
          today: today);
      expect(active.map((m) => m.task.id), ['t1']);

      final cancelled = searchTasks(tasks,
          filter:
              const TaskFilter(recurrenceFilter: RecurrenceFilter.cancelled),
          context: context,
          today: today);
      expect(cancelled.map((m) => m.task.id), ['t2']);

      final none = searchTasks(tasks,
          filter: const TaskFilter(recurrenceFilter: RecurrenceFilter.none),
          context: context,
          today: today);
      expect(none.map((m) => m.task.id), ['t3']);
    });
  });

  group('Relevância e dados (RF-16 a RF-19)', () {
    test('título > notas > subtarefas, ordem de origem no desempate (CA-17)',
        () {
      final tasks = [
        task('sub', title: 'A', subtaskDescriptions: ['termo'], position: 0),
        task('notes', title: 'B', notes: 'termo', position: 1),
        task('title2', title: 'termo dois', position: 2),
        task('title1', title: 'um termo', position: 3),
      ];
      final result = searchTasks(tasks, text: 'termo', today: today);
      expect(result.map((m) => m.task.id),
          ['title2', 'title1', 'notes', 'sub']);
    });

    test('sem texto, ordem de origem (RF-16)', () {
      final tasks = [
        task('b', position: 1),
        task('a', position: 0),
      ];
      final result = searchTasks(tasks, today: today);
      expect(result.map((m) => m.task.id), ['a', 'b']);
    });

    test('buscar não altera os dados (CA-19)', () {
      final original = task('t1', title: 'Reunião', notes: 'pauta');
      final before = original.hashCode;
      searchTasks([original], text: 'reuniao', today: today);
      expect(original.hashCode, before);
      expect(original.title, 'Reunião');
      expect(original.notes, 'pauta');
    });
  });
}
