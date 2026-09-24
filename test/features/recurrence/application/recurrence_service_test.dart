import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/recurrence/domain/recurrence.dart';
import 'package:urutau_tasks/src/features/tasks/application/tasks_service.dart';
import 'package:urutau_tasks/src/features/tasks/domain/task.dart';

import '../../../support/in_memory_my_day_repository.dart';
import '../../../support/in_memory_organization_repository.dart';
import '../../../support/in_memory_recurrence_repository.dart';
import '../../../support/in_memory_task_repository.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryRecurrenceRepository recurrence;
  late TasksService service;
  var idCounter = 0;

  // Hoje fixo para cálculos determinísticos.
  final today = DateTime(2026, 9, 24, 15);

  String newId() => 'id-${idCounter++}';

  setUp(() {
    idCounter = 0;
    tasks = InMemoryTaskRepository();
    recurrence = InMemoryRecurrenceRepository();
    service = TasksService(
      tasks,
      organizationRepository: InMemoryOrganizationRepository(tasks),
      myDayRepository: InMemoryMyDayRepository(),
      recurrenceRepository: recurrence,
      now: () => today,
      generateId: newId,
    );
  });

  Future<String> createRecurringTask({
    String title = 'Recorrente',
    DateTime? dueDate,
    DateTime? reminder,
    RecurrenceFrequency frequency = RecurrenceFrequency.daily,
  }) async {
    final id = await service.createTask(
      title: title,
      dueDate: dueDate ?? DateTime(2026, 10, 1),
      reminder: reminder,
    );
    await service.setRecurrence(id, frequency);
    return id;
  }

  group('prazo e lembrete (CA-01 a CA-05)', () {
    test('CA-01/CA-02 prazo editável e atrasado aceito', () async {
      final id = await service.createTask(title: 'T');
      await service.editTask(
        id,
        title: 'T',
        dueDate: DateTime(2026, 9, 1), // passado
      );
      final task = tasks.taskById(id);
      expect(task!.dueDate, DateTime(2026, 9, 1));
      expect(task.dueDate!.isBefore(today), isTrue);
    });

    test('CA-03/CA-04 lembrete independente do prazo', () async {
      final withoutDue = await service.createTask(
        title: 'Só lembrete',
        reminder: today.add(const Duration(hours: 2)),
      );
      expect((tasks.taskById(withoutDue))!.dueDate, isNull);

      final withDue = await service.createTask(
        title: 'Com prazo',
        dueDate: DateTime(2026, 10, 10),
        reminder: today.add(const Duration(days: 1)),
      );
      final task = tasks.taskById(withDue);
      expect(task!.dueDate, DateTime(2026, 10, 10));
      expect(task.reminder, today.add(const Duration(days: 1)));
    });

    test('CA-05 lembrete no passado é rejeitado ao criar', () async {
      await expectLater(
        service.createTask(
          title: 'T',
          reminder: today.subtract(const Duration(hours: 1)),
        ),
        throwsA(isA<ReminderInPastException>()),
      );
      expect(tasks.allTasks, isEmpty);
    });

    test('CA-05 alterar lembrete para o passado é rejeitado', () async {
      final id = await service.createTask(
        title: 'T',
        reminder: today.add(const Duration(hours: 1)),
      );

      await expectLater(
        service.editTask(
          id,
          title: 'T',
          reminder: today.subtract(const Duration(minutes: 5)),
        ),
        throwsA(isA<ReminderInPastException>()),
      );
      expect(
        (tasks.taskById(id))!.reminder,
        today.add(const Duration(hours: 1)),
      );
    });

    test('CA-08 lembrete vencido inalterado não bloqueia outras edições',
        () async {
      final expired = today.subtract(const Duration(days: 1));
      final id = await service.createTask(
        title: 'T',
        reminder: today.add(const Duration(hours: 1)),
      );
      // Simula lembrete vencido registrado (ex.: herdado e não notificado).
      tasks.updateTask(
        (tasks.taskById(id))!.copyWith(reminder: expired),
      );

      await service.editTask(id, title: 'T editada', reminder: expired);

      final task = tasks.taskById(id);
      expect(task!.title, 'T editada');
      expect(task.reminder, expired);
    });
  });

  group('recorrência (CA-09, CA-11 a CA-18)', () {
    test('CA-18 ativar sem prazo é rejeitado', () async {
      final id = await service.createTask(title: 'Sem prazo');
      await expectLater(
        service.setRecurrence(id, RecurrenceFrequency.daily),
        throwsA(isA<RecurrenceRequiresDueDateException>()),
      );
      expect((tasks.taskById(id))!.seriesId, isNull);
    });

    test('CA-09 ativar recorrência cria a série', () async {
      final id = await createRecurringTask();
      final task = tasks.taskById(id);
      expect(task!.seriesId, isNotNull);
      final series = await recurrence.getSeries(task.seriesId!);
      expect(series!.frequency, RecurrenceFrequency.daily);
      expect(series.anchorDate, '2026-10-01');
      expect(series.active, isTrue);
    });

    test('CA-11/CA-14 concluir gera só a próxima e preserva o histórico',
        () async {
      final id = await createRecurringTask(dueDate: DateTime(2026, 9, 20));
      await service.addSubtask(id, title: 'Etapa');

      await service.toggleCompletion(id);

      final all = tasks.allTasks.toList();
      expect(all, hasLength(2));

      final old = tasks.taskById(id);
      expect(old!.status, TaskStatus.completed);
      expect(old.dueDate, DateTime(2026, 9, 20));
      expect(old.subtasks.single.title, 'Etapa'); // histórico intacto
      expect(old.seriesId, isNotNull);

      final next = all.firstWhere((t) => t.id != id);
      expect(next.id, isNot(id));
      expect(next.status, TaskStatus.active);
      expect(next.seriesId, old.seriesId);
      // Avança até hoje (09-24), sem retroativas em lote (CA-15).
      expect(next.dueDate, DateTime(2026, 9, 24));
      expect(all.where((t) => t.status == TaskStatus.completed), hasLength(1));
    });

    test('CA-12 nova ocorrência não copia subtarefas', () async {
      final id = await createRecurringTask(dueDate: DateTime(2026, 9, 20));
      await service.addSubtask(id, title: 'Etapa');

      await service.toggleCompletion(id);

      final next = tasks.allTasks.firstWhere((t) => t.id != id);
      expect(next.subtasks, isEmpty);
    });

    test('CA-13 herda lembrete recalculado para o novo prazo', () async {
      final id = await createRecurringTask(
        dueDate: DateTime(2026, 10, 1),
        reminder: DateTime(2026, 10, 1, 9, 30),
      );

      await service.toggleCompletion(id);

      final next = tasks.allTasks.firstWhere((t) => t.id != id);
      expect(next.dueDate, DateTime(2026, 10, 2));
      expect(next.reminder, DateTime(2026, 10, 2, 9, 30));
    });

    test('CA-16 alterar regra vale da ocorrência atual sem tocar histórico',
        () async {
      final id = await createRecurringTask(
        dueDate: DateTime(2026, 9, 20),
        frequency: RecurrenceFrequency.daily,
      );
      await service.toggleCompletion(id);
      final history = tasks.allTasks.firstWhere((t) => t.status ==
          TaskStatus.completed);
      final current = tasks.allTasks.firstWhere((t) => t.id != history.id);

      await service.setRecurrence(current.id, RecurrenceFrequency.weekly);

      final series = await recurrence.getSeries(history.seriesId!);
      expect(series!.frequency, RecurrenceFrequency.weekly);
      // Histórico não é reescrito.
      final historyAfter = tasks.taskById(history.id);
      expect(historyAfter!.dueDate, history.dueDate);
      expect(historyAfter.status, TaskStatus.completed);
      expect(historyAfter.subtasks, history.subtasks);

      // A partir da ocorrência atual (09-24 qui), a semanal avança.
      await service.toggleCompletion(current.id);
      final newest = tasks.allTasks.firstWhere(
        (t) => t.id != history.id && t.id != current.id,
      );
      expect(newest.dueDate!.weekday, DateTime.thursday);
      expect(newest.dueDate!.isAfter(DateTime(2026, 9, 24)), isTrue);
    });

    test('CA-17 cancelar série impede novas ocorrências', () async {
      final id = await createRecurringTask(dueDate: DateTime(2026, 9, 20));
      await service.toggleCompletion(id);
      expect(tasks.allTasks, hasLength(2));

      final current = tasks.allTasks.firstWhere((t) => t.status ==
          TaskStatus.active);
      await service.setRecurrence(current.id, null);

      // O vínculo permanece (spec 05, RF-15) mas a série fica inativa.
      expect((tasks.taskById(current.id))!.seriesId, isNotNull);
      final series =
          await recurrence.getSeries((tasks.taskById(current.id))!.seriesId!);
      expect(series!.active, isFalse);

      final countBefore = tasks.allTasks.length;
      await service.toggleCompletion(current.id);
      expect(tasks.allTasks, hasLength(countBefore)); // sem nova ocorrência
      // Ocorrências anteriores permanecem no histórico.
      expect(
        tasks.allTasks.where((t) => t.status == TaskStatus.completed),
        hasLength(2),
      );
    });

    test('RF-05 lembrete é preservado ao concluir e reabrir', () async {
      final reminder = today.add(const Duration(hours: 3));
      final id = await service.createTask(title: 'T', reminder: reminder);

      await service.toggleCompletion(id);
      expect((tasks.taskById(id))!.reminder, reminder);

      await service.toggleCompletion(id);
      final reopened = tasks.taskById(id);
      expect(reopened!.status, TaskStatus.active);
      expect(reopened.reminder, reminder);
    });
  });
}
