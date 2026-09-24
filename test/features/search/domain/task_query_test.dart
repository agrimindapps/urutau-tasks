import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/organization/domain/organization.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/search/domain/task_query.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/task_fixtures.dart';

void main() {
  final today = DateTime(2026, 9, 24);
  final lists = [
    TaskList(id: 'l1', name: 'Trabalho', groupId: 'g1'),
    TaskList(id: 'l2', name: 'Casa'),
  ];
  final context = TaskSearchContext(
    today: today,
    lists: lists,
    seriesById: {
      's-active': RecurrenceSeries(
        id: 's-active',
        frequency: RecurrenceFrequency.daily,
        anchorDate: '2026-10-01',
      ),
      's-canceled': RecurrenceSeries(
        id: 's-canceled',
        frequency: RecurrenceFrequency.weekly,
        anchorDate: '2026-10-01',
        active: false,
      ),
    },
  );

  Task task({
    String id = 't',
    String title = 'Tarefa',
    String? notes,
    List<Subtask> subtasks = const [],
    TaskStatus status = TaskStatus.active,
    DateTime? deletedAt,
    int position = 0,
    String? listId,
    String? categoryId,
    List<Tag> tags = const [],
    Priority priority = Priority.medium,
    DateTime? dueDate,
    DateTime? reminder,
    String? seriesId,
  }) {
    return buildTestTask(
      id: id,
      title: title,
      notes: notes,
      subtasks: subtasks,
      status: status,
      deletedAt: deletedAt,
      position: position,
      listId: listId,
      categoryId: categoryId,
      tags: tags,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      seriesId: seriesId,
    );
  }

  List<Task> search(Iterable<Task> tasks, TaskFilters filters) => searchTasks(
        tasks: tasks,
        filters: filters,
        context: context,
      );

  group('busca textual (CA-01 a CA-05, CA-17, CA-18)', () {
    test('CA-01 encontra por título globalmente', () {
      final results = search(
        [
          task(id: 'a', title: 'Comprar pão', listId: 'l1'),
          task(id: 'b', title: 'Ligar para o dentista', listId: 'l2'),
        ],
        const TaskFilters(query: 'pão'),
      );
      expect(results.map((t) => t.id), ['a']);
    });

    test('CA-02 encontra por notas', () {
      final results = search(
        [task(id: 'a', title: 'Sem o termo', notes: 'detalhes da reunião')],
        const TaskFilters(query: 'reunião'),
      );
      expect(results.single.id, 'a');
    });

    test('CA-03 encontra por subtarefa e retorna a principal', () {
      final results = search(
        [
          task(
            id: 'a',
            title: 'Principal',
            subtasks: [
              buildTestSubtask(
                id: 's1',
                taskId: 'a',
                title: 'Comprar passagem',
              ),
            ],
          ),
        ],
        const TaskFilters(query: 'passagem'),
      );
      expect(results.single.id, 'a');
    });

    test('CA-04 ignora maiúsculas e acentos', () {
      final results = search(
        [task(id: 'a', title: 'Reunião do time')],
        const TaskFilters(query: 'reuniao'),
      );
      expect(results.single.id, 'a');

      final upper = search(
        [task(id: 'a', title: 'Reunião do time')],
        const TaskFilters(query: 'REUNIÃO'),
      );
      expect(upper.single.id, 'a');
    });

    test('CA-05 correspondência parcial', () {
      final results = search(
        [task(id: 'a', title: 'Protocolar documento')],
        const TaskFilters(query: 'otoc'),
      );
      expect(results.single.id, 'a');
    });

    test('CA-17 relevância: título antes de notas antes de subtarefa', () {
      final results = search(
        [
          task(id: 'sub', title: 'Outra', position: 0, subtasks: [
            buildTestSubtask(id: 's1', taskId: 'sub', title: 'orçamento aqui'),
          ]),
          task(id: 'notes', title: 'Sem', notes: 'orçamento final', position: 1),
          task(id: 'title', title: 'Fechar orçamento', position: 2),
        ],
        const TaskFilters(query: 'orçamento'),
      );
      expect(results.map((t) => t.id), ['title', 'notes', 'sub']);
    });

    test('CA-18 tarefa com várias subtarefas correspondentes aparece uma vez',
        () {
      final results = search(
        [
          task(id: 'a', title: 'Projeto', subtasks: [
            buildTestSubtask(id: 's1', taskId: 'a', title: 'relatório parcial'),
            buildTestSubtask(id: 's2', taskId: 'a', title: 'revisão do relatório'),
          ]),
        ],
        const TaskFilters(query: 'relatório'),
      );
      expect(results, hasLength(1));
    });

    test('CA-08 tarefa na lixeira nunca aparece', () {
      final results = search(
        [
          task(id: 'a', title: 'Oculta na lixeira', deletedAt: today),
          task(id: 'b', title: 'Oculta também', deletedAt: today,
              status: TaskStatus.completed),
        ],
        const TaskFilters(query: 'oculta'),
      );
      expect(results, isEmpty);
    });
  });

  group('filtros (CA-06, CA-09 a CA-16, CA-20)', () {
    test('CA-06 filtros sem texto', () {
      final results = search(
        [
          task(id: 'high', priority: Priority.high),
          task(id: 'low', priority: Priority.low),
        ],
        const TaskFilters(priorities: {Priority.high}),
      );
      expect(results.map((t) => t.id), ['high']);
    });

    test('CA-09 status', () {
      final results = search(
        [
          task(id: 'active', status: TaskStatus.active),
          task(id: 'done', status: TaskStatus.completed),
        ],
        const TaskFilters(statuses: {TaskStatus.completed}),
      );
      expect(results.map((t) => t.id), ['done']);

      final both = search(
        [
          task(id: 'active', status: TaskStatus.active),
          task(id: 'done', status: TaskStatus.completed),
        ],
        const TaskFilters(),
      );
      expect(both, hasLength(2)); // RF-02: sem filtro, ativas e concluídas
    });

    test('CA-10 listas, grupos, categorias, tags e prioridades', () {
      final tasks = [
        task(id: 'a', listId: 'l1', categoryId: 'c1',
            tags: [Tag(id: 't1', name: 'urgente')],
            priority: Priority.urgent),
        task(id: 'b', listId: 'l2', categoryId: 'c2',
            tags: [Tag(id: 't2', name: 'casa')],
            priority: Priority.low),
      ];

      // Lista + prioridade: AND entre categorias, OR dentro.
      expect(
        search(
          tasks,
          const TaskFilters(
            listIds: {'l1', 'l2'},
            priorities: {Priority.urgent},
          ),
        ).map((t) => t.id),
        ['a'],
      );

      // Grupo: l1 pertence a g1; tarefa sem lista fica fora (RF-10).
      expect(
        search(tasks, const TaskFilters(groupIds: {'g1'}))
            .map((t) => t.id),
        ['a'],
      );

      // Tags OR.
      expect(
        search(
          tasks,
          const TaskFilters(tagIds: {'t1', 't2'}),
        ),
        hasLength(2),
      );

      // Sem categoria.
      final withoutCategory = task(id: 'c');
      expect(
        search(
          [...tasks, withoutCategory],
          const TaskFilters(categoryIds: {null}),
        ).map((t) => t.id),
        ['c'],
      );
    });

    test('CA-11 filtro Sem lista', () {
      final results = search(
        [
          task(id: 'inbox'),
          task(id: 'listed', listId: 'l1'),
        ],
        const TaskFilters(listIds: {null}),
      );
      expect(results.map((t) => t.id), ['inbox']);
    });

    test('CA-12 combina categorias com AND e opções com OR', () {
      final tasks = [
        task(id: 'match', listId: 'l1', priority: Priority.urgent),
        task(id: 'wrongPriority', listId: 'l1', priority: Priority.low),
        task(id: 'wrongList', listId: 'l2', priority: Priority.urgent),
      ];
      final results = search(
        tasks,
        const TaskFilters(
          listIds: {'l1'},
          priorities: {Priority.urgent, Priority.high},
        ),
      );
      expect(results.map((t) => t.id), ['match']);
    });

    test('CA-13 categorias de prazo relativas ao calendário local', () {
      final tasks = [
        task(id: 'none'),
        task(id: 'overdue', dueDate: DateTime(2026, 9, 20)),
        task(id: 'today', dueDate: DateTime(2026, 9, 24)),
        task(id: 'tomorrow', dueDate: DateTime(2026, 9, 25)),
        task(id: 'in7', dueDate: DateTime(2026, 10, 1)), // today+7
        task(id: 'far', dueDate: DateTime(2026, 10, 5)),
      ];

      expect(
        search(tasks, const TaskFilters(due: DueFilter.none))
            .map((t) => t.id),
        ['none'],
      );
      expect(
        search(tasks, const TaskFilters(due: DueFilter.overdue))
            .map((t) => t.id),
        ['overdue'],
      );
      expect(
        search(tasks, const TaskFilters(due: DueFilter.today))
            .map((t) => t.id),
        ['today'],
      );
      expect(
        search(tasks, const TaskFilters(due: DueFilter.next7Days))
            .map((t) => t.id),
        ['tomorrow', 'in7'],
      );
    });

    test('CA-14 intervalo personalizado inclusivo nos limites', () {
      final results = search(
        [
          task(id: 'before', dueDate: DateTime(2026, 9, 20)),
          task(id: 'start', dueDate: DateTime(2026, 9, 22)),
          task(id: 'middle', dueDate: DateTime(2026, 9, 25)),
          task(id: 'end', dueDate: DateTime(2026, 9, 30)),
          task(id: 'after', dueDate: DateTime(2026, 10, 2)),
        ],
        const TaskFilters(
          due: DueFilter.customRange,
          customDueStart: null,
        ).copyWith(
          customDueStart: DateTime(2026, 9, 22),
          customDueEnd: DateTime(2026, 9, 30),
        ),
      );
      expect(results.map((t) => t.id), ['start', 'middle', 'end']);
    });

    test('CA-15 filtro de lembrete', () {
      final tasks = [
        task(id: 'with', reminder: DateTime.utc(2026, 10, 1, 12)),
        task(id: 'without'),
      ];
      expect(
        search(tasks, const TaskFilters(reminder: ReminderFilter.withReminder))
            .map((t) => t.id),
        ['with'],
      );
      expect(
        search(tasks, const TaskFilters(reminder: ReminderFilter.withoutReminder))
            .map((t) => t.id),
        ['without'],
      );
    });

    test('CA-16 filtro de recorrência distingue os três estados', () {
      final tasks = [
        task(id: 'recurring', seriesId: 's-active'),
        task(id: 'plain'),
        task(id: 'canceled', seriesId: 's-canceled'),
      ];
      expect(
        search(tasks, const TaskFilters(recurrence: RecurrenceFilter.active))
            .map((t) => t.id),
        ['recurring'],
      );
      expect(
        search(tasks, const TaskFilters(recurrence: RecurrenceFilter.none))
            .map((t) => t.id),
        ['plain'],
      );
      expect(
        search(tasks, const TaskFilters(recurrence: RecurrenceFilter.canceled))
            .map((t) => t.id),
        ['canceled'],
      );
    });

    test('CA-20 concluída com prazo passado não é atrasada', () {
      final results = search(
        [
          task(
            id: 'done',
            status: TaskStatus.completed,
            dueDate: DateTime(2026, 9, 1),
          ),
          task(id: 'late', dueDate: DateTime(2026, 9, 1)),
        ],
        const TaskFilters(due: DueFilter.overdue),
      );
      expect(results.map((t) => t.id), ['late']);
    });

    test('CA-19 a consulta não modifica as tarefas (projeção pura)', () {
      final original = task(
        id: 'a',
        title: 'Original',
        notes: 'nota',
        subtasks: [
          buildTestSubtask(id: 's1', taskId: 'a', title: 'etapa'),
        ],
      );
      final before = original;

      search([original], const TaskFilters(query: 'orig'));
      search([original], const TaskFilters(priorities: {Priority.low}));
      search([original], const TaskFilters(due: DueFilter.overdue));

      expect(original, before);
      expect(original.subtasks.single.title, 'etapa');
    });
  });

  group('normalização (RF-05)', () {
    test('remove acentos e caixa sem alterar o original', () {
      expect(normalizeForSearch('Reunião Àcida Ç'), 'reuniao acida c');
      expect(normalizeForSearch('ÉGG'), 'egg');
    });

    test('busca vazia com filtros usa apenas os filtros (RF-07)', () {
      final results = search(
        [task(id: 'a', title: 'Qualquer')],
        const TaskFilters(query: '   ', priorities: {Priority.medium}),
      );
      expect(results.single.id, 'a');
    });
  });
}
