// Regras de organização: listas, grupos, categorias e tags (spec 02).

/// Nome vazio após o trim (spec 02, RF-01).
class InvalidNameException implements Exception {
  const InvalidNameException();

  @override
  String toString() => 'Name must not be empty.';
}

/// Nome já utilizado por outra entidade do mesmo tipo (spec 02, RF-01/CA-02).
class DuplicateNameException implements Exception {
  const DuplicateNameException(this.name);

  final String name;

  @override
  String toString() => 'Name already in use: $name';
}

/// Lista com tarefas precisa de destino para exclusão (spec 02, RF-06/CA-07).
class ListNotEmptyException implements Exception {
  const ListNotEmptyException();

  @override
  String toString() => 'List still contains tasks.';
}

/// Não existe outra lista para receber as tarefas (spec 02, RF-06).
class NoDestinationAvailableException implements Exception {
  const NoDestinationAvailableException();

  @override
  String toString() => 'No other list is available as destination.';
}

/// Remove espaços e rejeita nomes vazios (spec 02, RF-01).
String normalizeName(String raw) {
  final name = raw.trim();
  if (name.isEmpty) throw const InvalidNameException();
  return name;
}

/// Chave canônica para comparação sem diferenciação de maiúsculas
/// (spec 02, RF-01/RF-09; spec 06, RF-08).
String canonicalName(String name) => name.trim().toLowerCase();

/// Grupo de listas (spec 02, RF-04). Não contém tarefas nem outros grupos.
class Group {
  Group({
    required this.id,
    required String name,
    this.position = 0,
  }) : name = normalizeName(name);

  final String id;
  final String name;
  final int position;

  Group copyWith({String? name, int? position}) => Group(
        id: id,
        name: name ?? this.name,
        position: position ?? this.position,
      );

  @override
  bool operator ==(Object other) =>
      other is Group &&
      other.id == id &&
      other.name == name &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, name, position);
}

/// Lista de tarefas (spec 02, RF-02). [groupId] nulo = sem grupo.
class TaskList {
  TaskList({
    required this.id,
    required String name,
    this.position = 0,
    this.groupId,
  }) : name = normalizeName(name);

  final String id;
  final String name;
  final int position;
  final String? groupId;

  TaskList copyWith({String? name, int? position, String? groupId}) {
    return TaskList(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      groupId: groupId,
    );
  }

  /// Permite limpar o grupo ao mover a lista para fora de um grupo.
  TaskList copyWithGroup(String? groupId) => TaskList(
        id: id,
        name: name,
        position: position,
        groupId: groupId,
      );

  @override
  bool operator ==(Object other) =>
      other is TaskList &&
      other.id == id &&
      other.name == name &&
      other.position == position &&
      other.groupId == groupId;

  @override
  int get hashCode => Object.hash(id, name, position, groupId);
}

/// Categoria global, no máximo uma por tarefa (spec 02, RF-08).
class Category {
  Category({required this.id, required String name})
      : name = normalizeName(name);

  final String id;
  final String name;

  Category copyWith({String? name}) =>
      Category(id: id, name: name ?? this.name);

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Tag global, várias por tarefa, sem duplicatas equivalentes
/// (spec 02, RF-09/CA-12).
class Tag {
  Tag({required this.id, required String name})
      : name = normalizeName(name);

  final String id;
  final String name;

  Tag copyWith({String? name}) => Tag(id: id, name: name ?? this.name);

  /// Tags equivalentes: mesmo nome canônico (CA-12).
  bool isEquivalentTo(Tag other) =>
      canonicalName(name) == canonicalName(other.name);

  @override
  bool operator ==(Object other) =>
      other is Tag && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Reordena itens com posição inteira e renumera de forma determinística
/// (spec 02, RF-10; spec 06, RF-18).
List<T> reorderItems<T>(
  List<T> items,
  int oldIndex,
  int newIndex,
  int Function(T item) positionOf,
  T Function(T item, int position) withPosition,
) {
  if (oldIndex < 0 || oldIndex >= items.length) {
    throw RangeError.index(oldIndex, items, 'oldIndex');
  }
  final copy = List<T>.from(items);
  final item = copy.removeAt(oldIndex);
  var insertAt = newIndex;
  if (insertAt < 0) insertAt = 0;
  if (insertAt > copy.length) insertAt = copy.length;
  copy.insert(insertAt, item);
  return [
    for (var i = 0; i < copy.length; i++) withPosition(copy[i], i),
  ];
}
