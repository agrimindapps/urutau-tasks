import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../tasks/application/task_providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_title_dialog.dart';
import '../../tasks/presentation/task_list_page.dart';
import '../domain/organization.dart';

class OrganizationPage extends ConsumerStatefulWidget {
  const OrganizationPage({super.key});

  @override
  ConsumerState<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends ConsumerState<OrganizationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(_syncSelectedTab);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_syncSelectedTab)
      ..dispose();
    super.dispose();
  }

  void _syncSelectedTab() {
    if (_selectedTab == _tabController.index) return;
    setState(() => _selectedTab = _tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageOrganization),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.lists),
            Tab(text: l10n.groups),
            Tab(text: l10n.categories),
            Tab(text: l10n.tags),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ListPanel(),
          _GroupPanel(),
          _CategoryPanel(),
          _TagPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSelectedEntity,
        icon: const Icon(Icons.add),
        label: Text(_newEntityLabel(l10n)),
      ),
    );
  }

  String _newEntityLabel(AppLocalizations l10n) => switch (_selectedTab) {
    0 => l10n.newList,
    1 => l10n.newGroup,
    2 => l10n.newCategory,
    _ => l10n.newTag,
  };

  Future<void> _createSelectedEntity() async {
    final l10n = AppLocalizations.of(context);
    final (dialogTitle, fieldLabel) = switch (_selectedTab) {
      0 => (l10n.newList, l10n.listName),
      1 => (l10n.newGroup, l10n.groupName),
      2 => (l10n.newCategory, l10n.categoryName),
      _ => (l10n.newTag, l10n.tagName),
    };
    final name = await showTaskTitleDialog(
      context,
      title: dialogTitle,
      fieldLabel: fieldLabel,
      submitLabel: l10n.add,
    );
    if (name == null || !mounted) return;
    await _performOrganizationAction(context, () async {
      final repository = ref.read(organizationRepositoryProvider);
      switch (_selectedTab) {
        case 0:
          await repository.createList(name);
        case 1:
          await repository.createGroup(name);
        case 2:
          await repository.createCategory(name);
        default:
          await repository.createOrGetTag(name);
      }
    });
  }
}

class _ListPanel extends ConsumerWidget {
  const _ListPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listsValue = ref.watch(taskListsProvider);
    final groupsValue = ref.watch(taskGroupsProvider);
    final tasksValue = ref.watch(tasksProvider);
    if (groupsValue.hasError || tasksValue.hasError) {
      return Center(child: Text(l10n.unableToLoadTasks));
    }
    final groups = groupsValue.asData?.value;
    final tasks = tasksValue.asData?.value;
    if (groups == null || tasks == null) {
      return Center(child: Text(l10n.loading));
    }
    return listsValue.when(
      loading: () => Center(child: Text(l10n.loading)),
      error: (_, _) => Center(child: Text(l10n.unableToLoadTasks)),
      data: (lists) {
        if (lists.isEmpty) return Center(child: Text(l10n.noLists));
        final groupNames = {for (final group in groups) group.id: group.name};
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: lists.length,
          onReorderItem: (oldIndex, newIndex) =>
              _performOrganizationAction(context, () async {
                final reordered = List.of(lists);
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                await ref
                    .read(organizationRepositoryProvider)
                    .reorderLists(reordered.map((list) => list.id).toList());
              }),
          itemBuilder: (context, index) {
            final list = lists[index];
            final taskCount = tasks
                .where((task) => task.listId == list.id)
                .length;
            return Card(
              key: ValueKey(list.id),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => TaskListPage(listId: list.id),
                  ),
                ),
                leading: const Icon(Icons.list_alt),
                title: Text(list.name),
                subtitle: Text(
                  '${groupNames[list.groupId] ?? l10n.noGroup} · $taskCount',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            _renameList(context, ref, list);
                          case 'group':
                            _changeListGroup(context, ref, list, groups);
                          case 'delete':
                            _deleteList(context, ref, list, lists, tasks);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(
                          value: 'group',
                          child: Text(l10n.moveToGroup),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.deleteList),
                        ),
                      ],
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _renameList(
    BuildContext context,
    WidgetRef ref,
    TaskList list,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTaskTitleDialog(
      context,
      title: l10n.editList,
      fieldLabel: l10n.listName,
      submitLabel: l10n.save,
      initialValue: list.name,
    );
    if (name == null || !context.mounted) return;
    await _performOrganizationAction(context, () async {
      await ref.read(organizationRepositoryProvider).renameList(list.id, name);
    });
  }

  Future<void> _changeListGroup(
    BuildContext context,
    WidgetRef ref,
    TaskList list,
    List<TaskGroup> groups,
  ) async {
    final groupId = await showDialog<String>(
      context: context,
      builder: (context) =>
          _ListGroupDialog(currentGroupId: list.groupId, groups: groups),
    );
    if (groupId == null || !context.mounted) return;
    await _performOrganizationAction(context, () async {
      await ref
          .read(organizationRepositoryProvider)
          .setListGroup(list.id, groupId.isEmpty ? null : groupId);
    });
  }

  Future<void> _deleteList(
    BuildContext context,
    WidgetRef ref,
    TaskList list,
    List<TaskList> lists,
    List<Task> tasks,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasTasks = tasks.any((task) => task.listId == list.id);
    if (!hasTasks) {
      final confirmed = await _confirmAction(
        context,
        title: l10n.deleteList,
        message: l10n.deleteListConfirmation,
      );
      if (confirmed != true || !context.mounted) return;
      await _performOrganizationAction(context, () async {
        await ref.read(organizationRepositoryProvider).deleteList(list.id);
      });
      return;
    }

    final destinations = lists
        .where((candidate) => candidate.id != list.id)
        .toList();
    if (destinations.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleteListNeedsDestination)));
      return;
    }
    final destinationId = await showDialog<String>(
      context: context,
      builder: (context) => _DeleteListDialog(destinations: destinations),
    );
    if (destinationId == null || !context.mounted) return;
    await _performOrganizationAction(context, () async {
      await ref
          .read(organizationRepositoryProvider)
          .deleteList(list.id, destinationListId: destinationId);
    });
  }
}

class _GroupPanel extends ConsumerWidget {
  const _GroupPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupsValue = ref.watch(taskGroupsProvider);
    return groupsValue.when(
      loading: () => Center(child: Text(l10n.loading)),
      error: (_, _) => Center(child: Text(l10n.unableToLoadTasks)),
      data: (groups) {
        if (groups.isEmpty) return Center(child: Text(l10n.noGroups));
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: groups.length,
          onReorderItem: (oldIndex, newIndex) =>
              _performOrganizationAction(context, () async {
                final reordered = List.of(groups);
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                await ref
                    .read(organizationRepositoryProvider)
                    .reorderGroups(reordered.map((group) => group.id).toList());
              }),
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              key: ValueKey(group.id),
              child: ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(group.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _renameGroup(context, ref, group);
                        }
                        if (action == 'delete') {
                          _deleteGroup(context, ref, group);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.deleteGroup),
                        ),
                      ],
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _renameGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTaskTitleDialog(
      context,
      title: l10n.editGroup,
      fieldLabel: l10n.groupName,
      submitLabel: l10n.save,
      initialValue: group.name,
    );
    if (name == null || !context.mounted) return;
    await _performOrganizationAction(context, () async {
      await ref
          .read(organizationRepositoryProvider)
          .renameGroup(group.id, name);
    });
  }

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmAction(
      context,
      title: l10n.deleteGroup,
      message: l10n.deleteGroupConfirmation,
    );
    if (confirmed != true || !context.mounted) return;
    await _performOrganizationAction(context, () async {
      await ref.read(organizationRepositoryProvider).deleteGroup(group.id);
    });
  }
}

class _CategoryPanel extends ConsumerWidget {
  const _CategoryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(taskCategoriesProvider)
        .when(
          loading: () => Center(child: Text(l10n.loading)),
          error: (_, _) => Center(child: Text(l10n.unableToLoadTasks)),
          data: (categories) => _NamedItemsPanel(
            items: [
              for (final item in categories) _NamedItem(item.id, item.name),
            ],
            emptyMessage: l10n.noCategories,
            itemTypeTitle: l10n.editCategory,
            deleteTitle: l10n.deleteCategory,
            deleteMessage: l10n.deleteCategoryConfirmation,
            onRename: (item, name) => ref
                .read(organizationRepositoryProvider)
                .renameCategory(item.id, name),
            onDelete: (item) => ref
                .read(organizationRepositoryProvider)
                .deleteCategory(item.id),
            fieldLabel: l10n.categoryName,
          ),
        );
  }
}

class _TagPanel extends ConsumerWidget {
  const _TagPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(taskTagsProvider)
        .when(
          loading: () => Center(child: Text(l10n.loading)),
          error: (_, _) => Center(child: Text(l10n.unableToLoadTasks)),
          data: (tags) => _NamedItemsPanel(
            items: [for (final item in tags) _NamedItem(item.id, item.name)],
            emptyMessage: l10n.noTags,
            itemTypeTitle: l10n.editTag,
            deleteTitle: l10n.deleteTag,
            deleteMessage: l10n.deleteTagConfirmation,
            onRename: (item, name) => ref
                .read(organizationRepositoryProvider)
                .renameTag(item.id, name),
            onDelete: (item) =>
                ref.read(organizationRepositoryProvider).deleteTag(item.id),
            fieldLabel: l10n.tagName,
          ),
        );
  }
}

class _NamedItem {
  const _NamedItem(this.id, this.name);

  final String id;
  final String name;
}

class _NamedItemsPanel extends StatelessWidget {
  const _NamedItemsPanel({
    required this.items,
    required this.emptyMessage,
    required this.itemTypeTitle,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.onRename,
    required this.onDelete,
    required this.fieldLabel,
  });

  final List<_NamedItem> items;
  final String emptyMessage;
  final String itemTypeTitle;
  final String deleteTitle;
  final String deleteMessage;
  final Future<void> Function(_NamedItem item, String name) onRename;
  final Future<void> Function(_NamedItem item) onDelete;
  final String fieldLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) return Center(child: Text(emptyMessage));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.name),
            trailing: PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') {
                  final name = await showTaskTitleDialog(
                    context,
                    title: itemTypeTitle,
                    fieldLabel: fieldLabel,
                    submitLabel: l10n.save,
                    initialValue: item.name,
                  );
                  if (name == null || !context.mounted) return;
                  await _performOrganizationAction(context, () async {
                    await onRename(item, name);
                  });
                } else if (action == 'delete') {
                  final confirmed = await _confirmAction(
                    context,
                    title: deleteTitle,
                    message: deleteMessage,
                  );
                  if (confirmed != true || !context.mounted) return;
                  await _performOrganizationAction(context, () async {
                    await onDelete(item);
                  });
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ListGroupDialog extends StatefulWidget {
  const _ListGroupDialog({required this.currentGroupId, required this.groups});

  final String? currentGroupId;
  final List<TaskGroup> groups;

  @override
  State<_ListGroupDialog> createState() => _ListGroupDialogState();
}

class _ListGroupDialogState extends State<_ListGroupDialog> {
  late String? _selectedGroupId = widget.currentGroupId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.selectGroup),
      content: DropdownButtonFormField<String?>(
        initialValue: _selectedGroupId,
        isExpanded: true,
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(l10n.noGroup)),
          for (final group in widget.groups)
            DropdownMenuItem<String?>(value: group.id, child: Text(group.name)),
        ],
        onChanged: (value) => setState(() => _selectedGroupId = value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedGroupId ?? ''),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _DeleteListDialog extends StatefulWidget {
  const _DeleteListDialog({required this.destinations});

  final List<TaskList> destinations;

  @override
  State<_DeleteListDialog> createState() => _DeleteListDialogState();
}

class _DeleteListDialogState extends State<_DeleteListDialog> {
  String? _destinationId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.selectDestinationList),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.deleteListConfirmation),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _destinationId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.selectDestinationList),
            items: [
              for (final list in widget.destinations)
                DropdownMenuItem(value: list.id, child: Text(list.name)),
            ],
            onChanged: (value) => setState(() => _destinationId = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _destinationId == null
              ? null
              : () => Navigator.of(context).pop(_destinationId),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

Future<bool?> _confirmAction(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<bool>(
  context: context,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.confirm),
        ),
      ],
    );
  },
);

Future<void> _performOrganizationAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = error is DuplicateOrganizationNameException
        ? l10n.duplicateName
        : error is ListHasTasksException
        ? l10n.deleteListNeedsDestination
        : l10n.actionFailed;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
