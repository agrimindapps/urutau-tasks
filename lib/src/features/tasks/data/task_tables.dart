import 'package:drift/drift.dart';

/// Tabela de tarefas principais (spec 06, RF-05).
@DataClassName('TaskRecord')
class Tasks extends Table {
  TextColumn get id => text()();

  TextColumn get title =>
      text().customConstraint('CHECK(length(trim(title)) > 0)')();

  TextColumn get notes => text().nullable()();

  /// `active` ou `completed`. A lixeira é `deleted_at` preenchido.
  TextColumn get status => text()
      .withDefault(const Constant('active'))
      .customConstraint("CHECK(status IN ('active', 'completed'))")();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  IntColumn get position => integer().withDefault(const Constant(0))();

  /// `low` | `medium` | `high` | `urgent` (escopo MVP 3.3; spec 06, RF-05).
  /// O domínio valida os valores; o DEFAULT é essencial para a migração
  /// preencher linhas existentes (spec 06, RF-23).
  TextColumn get priority =>
      text().withDefault(const Constant('medium'))();

  /// Prazo como data de calendário `yyyy-MM-dd`, sem horário
  /// (spec 06, RF-11).
  TextColumn get dueDate => text().nullable()();

  /// Lembrete como instante UTC (spec 06, RF-12).
  DateTimeColumn get reminder => dateTime().nullable()();

  /// Série recorrente da qual esta tarefa é ocorrência (spec 04, RF-07;
  /// spec 06, RF-09).
  TextColumn get seriesId => text().nullable().references(Series, #id)();

  /// Lista da tarefa; nulo = inbox implícita (spec 02, RF-03; spec 06, RF-05).
  TextColumn get listId => text().nullable().references(TaskLists, #id)();

  /// Categoria principal; no máximo uma (spec 02, RF-08).
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Subtarefas: somente título, estado e posição (spec 06, RF-06).
@DataClassName('SubtaskRecord')
class Subtasks extends Table {
  TextColumn get id => text()();

  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.restrict)();

  TextColumn get title =>
      text().customConstraint('CHECK(length(trim(title)) > 0)')();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Grupos de listas (spec 02, RF-04).
@DataClassName('GroupRecord')
class Groups extends Table {
  TextColumn get id => text()();

  /// Nome único globalmente, sem diferenciação de maiúsculas (RF-01).
  TextColumn get name =>
      text().customConstraint('NOT NULL COLLATE NOCASE UNIQUE')();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Listas de tarefas (spec 02, RF-02).
@DataClassName('TaskListRecord')
class TaskLists extends Table {
  TextColumn get id => text()();

  TextColumn get name =>
      text().customConstraint('NOT NULL COLLATE NOCASE UNIQUE')();

  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Grupo da lista; nulo = sem grupo. Excluir o grupo preserva a lista
  /// (spec 02, RF-05 — vínculo limpo pela camada de aplicação).
  TextColumn get groupId => text().nullable().references(Groups, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categorias globais (spec 02, RF-08).
@DataClassName('CategoryRecord')
class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get name =>
      text().customConstraint('NOT NULL COLLATE NOCASE UNIQUE')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tags globais (spec 02, RF-09).
@DataClassName('TagRecord')
class Tags extends Table {
  TextColumn get id => text()();

  TextColumn get name =>
      text().customConstraint('NOT NULL COLLATE NOCASE UNIQUE')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Associação tarefa-tag, muitos-para-muitos (spec 06, RF-08).
@DataClassName('TaskTagRecord')
class TaskTags extends Table {
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.restrict)();

  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.restrict)();

  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

/// Entradas do My Day: uma por tarefa e por data local (spec 06, RF-10;
/// unicidade protegida por índice único `my_day_task_date`).
@DataClassName('MyDayEntryRecord')
class MyDayEntries extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(Tasks, #id)();

  /// Data local do foco `yyyy-MM-dd` (spec 06, RF-13).
  TextColumn get date => text()();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Série recorrente (spec 04, RF-07 a RF-10).
@DataClassName('SeriesRecord')
class Series extends Table {
  TextColumn get id => text()();

  /// Frequência fixa do MVP (spec 04, RF-08).
  TextColumn get frequency => text().customConstraint(
        "NOT NULL CHECK(frequency IN "
        "('daily', 'weekdays', 'weekly', 'monthly', 'yearly'))",
      )();

  /// Data-base `yyyy-MM-dd` do calendário original (spec 04, RF-07/RF-09).
  TextColumn get anchorDate => text()();

  /// `0` = cancelada manualmente; `1` = ativa (spec 04, RF-10).
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
