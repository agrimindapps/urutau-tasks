/// Domínio de listas, grupos, categorias e tags (spec 02).
///
/// Regras puras, sem dependência de widgets, banco ou plataforma.
library;

/// Falhas de validação/estado da organização.
enum OrganizationFailure {
  /// Nome vazio após trim (spec 02, RF-01).
  emptyName,

  /// Nome duplicado dentro do próprio tipo (spec 02, RF-01).
  duplicateName,

  /// Lista/grupo/categoria/tag referenciado não existe.
  unknownList,
  unknownGroup,
  unknownCategory,
  unknownTag,

  /// Exclusão de lista com tarefas sem lista destino válida
  /// (spec 02, RF-06).
  listNotEmpty,

  /// Lista destino não pode ser a própria lista de origem (spec 02, RF-06).
  sameDestination,
}

/// Exceção de domínio com a falha associada.
class OrganizationException implements Exception {
  const OrganizationException(this.failure);

  final OrganizationFailure failure;

  @override
  String toString() => 'OrganizationException(${failure.name})';
}

String validateName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const OrganizationException(OrganizationFailure.emptyName);
  }
  return trimmed;
}

/// Normalização de tags: trim + case-insensitive para comparação
/// (spec 02, RF-09).
String normalizeTagName(String raw) => raw.trim().toLowerCase();

/// Lista personalizada de tarefas (spec 02, RF-02).
class TaskList {
  const TaskList({
    required this.id,
    required this.name,
    required this.position,
    required this.groupId,
  });

  /// Cria lista com nome validado (spec 02, RF-01/RF-02).
  factory TaskList.create({
    required String id,
    required String name,
    int position = 0,
    String? groupId,
  }) {
    return TaskList(
      id: id,
      name: validateName(name),
      position: position,
      groupId: groupId,
    );
  }

  final String id;
  final String name;

  /// Ordem manual preservada entre sessões (spec 02, RF-10).
  final int position;

  /// Grupo opcional; lista em no máximo 1 grupo (spec 02, RF-04).
  final String? groupId;

  TaskList copyWith({String? name, int? position, String? groupId, bool clearGroup = false}) {
    return TaskList(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
    );
  }

  TaskList rename(String name) => copyWith(name: validateName(name));

  TaskList moveToGroup(String? groupId) =>
      groupId == null ? copyWith(clearGroup: true) : copyWith(groupId: groupId);

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

/// Grupo simples de listas (spec 02, RF-04/RF-05).
class TaskGroup {
  const TaskGroup({
    required this.id,
    required this.name,
    required this.position,
  });

  factory TaskGroup.create({
    required String id,
    required String name,
    int position = 0,
  }) {
    return TaskGroup(
      id: id,
      name: validateName(name),
      position: position,
    );
  }

  final String id;
  final String name;
  final int position;

  TaskGroup copyWith({String? name, int? position}) {
    return TaskGroup(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
    );
  }

  TaskGroup rename(String name) => copyWith(name: validateName(name));

  @override
  bool operator ==(Object other) =>
      other is TaskGroup &&
      other.id == id &&
      other.name == name &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, name, position);
}

/// Categoria global (máx. 1 por tarefa; spec 02, RF-08).
class TaskCategory {
  const TaskCategory({required this.id, required this.name});

  factory TaskCategory.create({required String id, required String name}) {
    return TaskCategory(id: id, name: validateName(name));
  }

  final String id;
  final String name;

  TaskCategory rename(String name) =>
      TaskCategory(id: id, name: validateName(name));

  @override
  bool operator ==(Object other) =>
      other is TaskCategory && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Tag global com identidade normalizada (spec 02, RF-09).
class TaskTag {
  const TaskTag({
    required this.id,
    required this.name,
    required this.normalizedName,
  });

  /// Cria tag preservando o nome exibido e a forma normalizada
  /// (trim + minúsculas) usada na comparação.
  factory TaskTag.create({required String id, required String name}) {
    final trimmed = validateName(name);
    return TaskTag(
      id: id,
      name: trimmed,
      normalizedName: normalizeTagName(trimmed),
    );
  }

  final String id;

  /// Nome como digitado (após trim), usado na exibição.
  final String name;

  /// Identidade de comparação (spec 02, RF-09).
  final String normalizedName;

  TaskTag rename(String name) => TaskTag.create(id: id, name: name);

  /// Mesma identidade se a normalização coincide (CA-12).
  bool sameIdentity(String rawName) =>
      normalizeTagName(rawName) == normalizedName;

  @override
  bool operator ==(Object other) =>
      other is TaskTag &&
      other.id == id &&
      other.name == name &&
      other.normalizedName == normalizedName;

  @override
  int get hashCode => Object.hash(id, name, normalizedName);
}
