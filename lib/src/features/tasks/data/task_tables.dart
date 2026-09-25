import 'package:drift/drift.dart';

import '../../organization/data/organization_tables.dart';

/// Tabelas de tarefas e subtarefas (esquema v1; spec 06, RF-05/RF-06).
@DataClassName('TaskRow')
class Tasks extends Table {
  /// UUID estável gerado no domínio (spec 06, RF-03).
  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get notes => text().withDefault(const Constant(''))();

  /// `active` | `completed` | `trash` (spec 01, RF-02).
  TextColumn get status => text()();

  /// Estado anterior à lixeira, para restauração fiel (spec 01, RF-10).
  TextColumn get statusBeforeTrash => text().nullable()();

  /// Instantes UTC de auditoria do ciclo de vida.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Lista personalizada opcional; nula = inbox implícita (spec 02, RF-03).
  TextColumn get listId => text().nullable().references(TaskLists, #id)();

  /// Categoria opcional única (spec 02, RF-08).
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubtaskRow')
class Subtasks extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(Tasks, #id)();

  TextColumn get description => text()();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
