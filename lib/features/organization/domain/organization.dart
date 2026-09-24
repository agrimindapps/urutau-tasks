class TaskGroup {
  const TaskGroup({
    required this.id,
    required this.name,
    required this.position,
  });

  final String id;
  final String name;
  final int position;
}

class TaskList {
  const TaskList({
    required this.id,
    required this.name,
    required this.position,
    this.groupId,
  });

  final String id;
  final String name;
  final int position;
  final String? groupId;
}

class TaskCategory {
  const TaskCategory({required this.id, required this.name});

  final String id;
  final String name;
}

class TaskTag {
  const TaskTag({required this.id, required this.name});

  final String id;
  final String name;
}

class TaskTagAssignment {
  const TaskTagAssignment({required this.taskId, required this.tagId});

  final String taskId;
  final String tagId;
}

class DuplicateOrganizationNameException implements Exception {
  const DuplicateOrganizationNameException();
}

class InvalidOrganizationNameException implements Exception {
  const InvalidOrganizationNameException();
}

class OrganizationItemNotFoundException implements Exception {
  const OrganizationItemNotFoundException();
}

class ListHasTasksException implements Exception {
  const ListHasTasksException();
}

String normalizeOrganizationName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw const InvalidOrganizationNameException();
  }
  return normalized;
}

String normalizeTagName(String value) => normalizeOrganizationName(value);

String canonicalTagName(String value) => normalizeTagName(value).toLowerCase();
