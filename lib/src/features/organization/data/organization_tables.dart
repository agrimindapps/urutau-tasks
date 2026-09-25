import 'package:drift/drift.dart';

import '../../tasks/data/task_tables.dart';

/// Tabelas de organização (esquema v2; spec 02; spec 06, RF-07/RF-08).
@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskListRow')
class TaskLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Grupo opcional; lista em no máximo 1 grupo (spec 02, RF-04).
  TextColumn get groupId => text().nullable().references(Groups, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();

  /// Nome exibido (após trim).
  TextColumn get name => text()();

  /// Identidade de comparação (trim + minúsculas; spec 02, RF-09).
  TextColumn get normalizedName => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskTagRow')
class TaskTags extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {taskId, tagId};
}
