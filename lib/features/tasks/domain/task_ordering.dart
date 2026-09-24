import '../../organization/domain/organization.dart';
import 'task.dart';

int compareTaskOrigin(
  Task first,
  Task second, {
  required Map<String, TaskList> listsById,
  required Map<String, TaskGroup> groupsById,
  required Map<String, int> groupOrder,
  required int groupCount,
}) {
  final firstList = first.listId == null ? null : listsById[first.listId];
  final secondList = second.listId == null ? null : listsById[second.listId];
  if (firstList == null || secondList == null) {
    if (firstList == null && secondList != null) return 1;
    if (secondList == null && firstList != null) return -1;
    final created = first.createdAtUtc.compareTo(second.createdAtUtc);
    return created != 0 ? created : first.id.compareTo(second.id);
  }

  final firstGroupRank = firstList.groupId == null
      ? groupCount + firstList.position
      : groupOrder[firstList.groupId] ?? groupCount + firstList.position;
  final secondGroupRank = secondList.groupId == null
      ? groupCount + secondList.position
      : groupOrder[secondList.groupId] ?? groupCount + secondList.position;
  var comparison = firstGroupRank.compareTo(secondGroupRank);
  if (comparison != 0) return comparison;

  if (firstList.groupId != secondList.groupId) {
    comparison = (groupsById[firstList.groupId]?.position ?? groupCount)
        .compareTo(groupsById[secondList.groupId]?.position ?? groupCount);
    if (comparison != 0) return comparison;
    comparison = (firstList.groupId ?? '').compareTo(secondList.groupId ?? '');
    if (comparison != 0) return comparison;
  }

  comparison = firstList.position.compareTo(secondList.position);
  if (comparison != 0) return comparison;
  comparison = firstList.id.compareTo(secondList.id);
  if (comparison != 0) return comparison;
  comparison = first.position.compareTo(second.position);
  if (comparison != 0) return comparison;
  comparison = first.createdAtUtc.compareTo(second.createdAtUtc);
  return comparison != 0 ? comparison : first.id.compareTo(second.id);
}
