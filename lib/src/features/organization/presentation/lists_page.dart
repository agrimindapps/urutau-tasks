import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../domain/organization.dart';
import '../domain/organization_repository.dart';
import '../../../app/presentation/settings_dialog.dart';
import '../../data_transfer/presentation/data_transfer_page.dart';
import '../../tasks/presentation/task_errors.dart';
import 'name_dialog.dart';

enum _ListAction { rename, moveGroup, up, down, delete }

enum _GroupAction { rename, up, down, delete }

enum _WordAction { rename, delete }

/// Gestão de listas, grupos, categorias e tags (spec 02).
class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final organization = ref.watch(organizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listsTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings),
            onPressed: () => SettingsDialog.show(context),
          ),
          IconButton(
            tooltip: l10n.backupTooltip,
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DataTransferPage(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newListTooltip,
        onPressed: () => _showCreateMenu(context, ref),
        child: const Icon(Icons.add),
      ),
      body: organization.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (snapshot) {
          if (snapshot.lists.isEmpty &&
              snapshot.groups.isEmpty &&
              snapshot.categories.isEmpty &&
              snapshot.tags.isEmpty) {
            return Center(child: Text(l10n.emptyLists));
          }
          final groupedIds = {
            for (final list in snapshot.lists)
              if (list.groupId != null) list.id,
          };
          final standalone = snapshot.lists
              .where((l) => !groupedIds.contains(l.id))
              .toList();
          return ListView(
            children: [
              for (final group in snapshot.groups)
                _groupTile(context, ref, snapshot, group),
              for (final list in standalone)
                _listTile(context, ref, snapshot, list),
              const Divider(),
              _sectionHeader(context, l10n.categoriesSection),
              if (snapshot.categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.emptyCategories),
                ),
              for (final category in snapshot.categories)
                _categoryTile(context, ref, category),
              const Divider(),
              _sectionHeader(context, l10n.tagsSection),
              if (snapshot.tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.emptyTags),
                ),
              for (final tag in snapshot.tags) _tagTile(context, ref, tag),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _groupTile(
    BuildContext context,
    WidgetRef ref,
    OrganizationSnapshot snapshot,
    TaskGroup group,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final lists =
        snapshot.lists.where((l) => l.groupId == group.id).toList();
    return ExpansionTile(
      key: ValueKey('group-${group.id}'),
      leading: const Icon(Icons.folder_outlined),
      title: Text(group.name),
      subtitle: Text(l10n.tasksCount(
        lists.fold(0, (sum, l) => sum + snapshot.taskCount(l.id)),
      )),
      trailing: _menuButton<_GroupAction>(
        onSelected: (action) => _groupAction(context, ref, group, action),
        items: [
          (l10n.rename, _GroupAction.rename),
          (l10n.moveUp, _GroupAction.up),
          (l10n.moveDown, _GroupAction.down),
          (l10n.delete, _GroupAction.delete),
        ],
        child: const Icon(Icons.more_vert),
      ),
      children: [
        for (final list in lists) _listTile(context, ref, snapshot, list),
      ],
    );
  }

  Widget _listTile(
    BuildContext context,
    WidgetRef ref,
    OrganizationSnapshot snapshot,
    TaskList list,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: ValueKey('list-${list.id}'),
      leading: const Icon(Icons.list_alt_outlined),
      title: Text(list.name),
      subtitle: Text(l10n.tasksCount(snapshot.taskCount(list.id))),
      trailing: _menuButton<_ListAction>(
        onSelected: (action) => _listAction(context, ref, snapshot, list, action),
        items: [
          (l10n.rename, _ListAction.rename),
          (l10n.moveToGroup, _ListAction.moveGroup),
          (l10n.moveUp, _ListAction.up),
          (l10n.moveDown, _ListAction.down),
          (l10n.delete, _ListAction.delete),
        ],
        child: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _categoryTile(
    BuildContext context,
    WidgetRef ref,
    TaskCategory category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: ValueKey('category-${category.id}'),
      leading: const Icon(Icons.label_outline),
      title: Text(category.name),
      trailing: _menuButton<_WordAction>(
        onSelected: (action) =>
            _categoryAction(context, ref, category, action),
        items: [
          (l10n.rename, _WordAction.rename),
          (l10n.delete, _WordAction.delete),
        ],
        child: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _tagTile(BuildContext context, WidgetRef ref, TaskTag tag) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: ValueKey('tag-${tag.id}'),
      leading: const Icon(Icons.tag),
      title: Text(tag.name),
      trailing: _menuButton<_WordAction>(
        onSelected: (action) => _tagAction(context, ref, tag, action),
        items: [
          (l10n.rename, _WordAction.rename),
          (l10n.delete, _WordAction.delete),
        ],
        child: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _menuButton<T>({
    required void Function(T) onSelected,
    required List<(String, T)> items,
    required Widget child,
  }) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final (label, value) in items)
          PopupMenuItem(value: value, child: Text(label)),
      ],
      child: child,
    );
  }

  // ---------------------------------------------------------------- ações

  Future<void> _showCreateMenu(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(l10n.newListTooltip),
              onTap: () => Navigator.of(context).pop('list'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l10n.newGroupTooltip),
              onTap: () => Navigator.of(context).pop('group'),
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(l10n.newCategoryTooltip),
              onTap: () => Navigator.of(context).pop('category'),
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text(l10n.newTagTooltip),
              onTap: () => Navigator.of(context).pop('tag'),
            ),
          ],
        ),
      ),
    );
    if (option == null || !context.mounted) return;
    final service = ref.read(organizationServiceProvider);
    switch (option) {
      case 'list':
        await _create(context, l10n.newListTooltip, service.createList);
      case 'group':
        await _create(context, l10n.newGroupTooltip, service.createGroup);
      case 'category':
        await _create(context, l10n.newCategoryTooltip, service.createCategory);
      case 'tag':
        await _create(context, l10n.newTagTooltip, service.createTag);
    }
  }

  Future<void> _create(
    BuildContext context,
    String title,
    Future<Object> Function({required String name}) create,
  ) async {
    final name = await NameDialog.show(context, title: title);
    if (name == null || !context.mounted) return;
    await runTaskAction(context, () async => create(name: name));
  }

  Future<void> _listAction(
    BuildContext context,
    WidgetRef ref,
    OrganizationSnapshot snapshot,
    TaskList list,
    _ListAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(organizationServiceProvider);
    switch (action) {
      case _ListAction.rename:
        final name =
            await NameDialog.show(context, title: l10n.rename, initial: list.name);
        if (name == null || !context.mounted) return;
        await runTaskAction(
            context, () => service.renameList(list.id, name: name));
      case _ListAction.moveGroup:
        final picked = await _pickGroup(context, snapshot, list.groupId);
        if (picked == null || !context.mounted) return;
        final groupId = picked.isEmpty ? null : picked;
        await runTaskAction(
            context, () => service.moveListToGroup(list.id, groupId));
      case _ListAction.up:
        await _move(context, service.reorderLists,
            [for (final l in snapshot.lists) l.id], list.id, -1);
      case _ListAction.down:
        await _move(context, service.reorderLists,
            [for (final l in snapshot.lists) l.id], list.id, 1);
      case _ListAction.delete:
        await _deleteList(context, ref, snapshot, list);
    }
  }

  Future<void> _groupAction(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
    _GroupAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(organizationServiceProvider);
    switch (action) {
      case _GroupAction.rename:
        final name =
            await NameDialog.show(context, title: l10n.rename, initial: group.name);
        if (name == null || !context.mounted) return;
        await runTaskAction(
            context, () => service.renameGroup(group.id, name: name));
      case _GroupAction.up:
      case _GroupAction.down:
        final snapshot = await service.fetchSnapshot();
        final delta = action == _GroupAction.up ? -1 : 1;
        if (!context.mounted) return;
        await _move(context, service.reorderGroups,
            [for (final g in snapshot.groups) g.id], group.id, delta);
      case _GroupAction.delete:
        final confirmed = await _confirm(
          context,
          l10n.deleteGroupTitle,
          l10n.deleteGroupMessage,
        );
        if (!confirmed || !context.mounted) return;
        await runTaskAction(context, () => service.deleteGroup(group.id));
    }
  }

  Future<void> _categoryAction(
    BuildContext context,
    WidgetRef ref,
    TaskCategory category,
    _WordAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(organizationServiceProvider);
    switch (action) {
      case _WordAction.rename:
        final name = await NameDialog.show(context,
            title: l10n.rename, initial: category.name);
        if (name == null || !context.mounted) return;
        await runTaskAction(
            context, () => service.renameCategory(category.id, name: name));
      case _WordAction.delete:
        final confirmed = await _confirm(
          context,
          l10n.deleteCategoryTitle,
          l10n.deleteCategoryMessage,
        );
        if (!confirmed || !context.mounted) return;
        await runTaskAction(context, () => service.deleteCategory(category.id));
    }
  }

  Future<void> _tagAction(
    BuildContext context,
    WidgetRef ref,
    TaskTag tag,
    _WordAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(organizationServiceProvider);
    switch (action) {
      case _WordAction.rename:
        final name = await NameDialog.show(context,
            title: l10n.rename, initial: tag.name);
        if (name == null || !context.mounted) return;
        await runTaskAction(context, () => service.renameTag(tag.id, name: name));
      case _WordAction.delete:
        final confirmed = await _confirm(
          context,
          l10n.deleteTagTitle,
          l10n.deleteTagMessage,
        );
        if (!confirmed || !context.mounted) return;
        await runTaskAction(context, () => service.deleteTag(tag.id));
    }
  }

  Future<void> _deleteList(
    BuildContext context,
    WidgetRef ref,
    OrganizationSnapshot snapshot,
    TaskList list,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(organizationServiceProvider);
    final count = snapshot.taskCount(list.id);

    if (count == 0) {
      final confirmed = await _confirm(
        context,
        l10n.deleteListTitle,
        l10n.deleteListEmptyMessage,
      );
      if (!confirmed || !context.mounted) return;
      await runTaskAction(context, () => service.deleteList(list.id));
      return;
    }

    final destinations =
        snapshot.lists.where((l) => l.id != list.id).toList();
    if (destinations.isEmpty) {
      // Sem outra lista disponível, a exclusão fica bloqueada (RF-06).
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorListNotEmpty)),
      );
      return;
    }

    final destinationId = await _pickDestination(context, list, destinations);
    if (destinationId == null || !context.mounted) return;
    await runTaskAction(
      context,
      () => service.deleteList(list.id, destinationListId: destinationId),
    );
  }

  Future<String?> _pickDestination(
    BuildContext context,
    TaskList list,
    List<TaskList> destinations,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteListDestinationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteListDestinationMessage(list.name)),
            const SizedBox(height: 12),
            for (final destination in destinations)
              ListTile(
                title: Text(destination.name),
                onTap: () => Navigator.of(context).pop(destination.id),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// Devolve `null` ao cancelar, `''` para "sem grupo" ou o id do grupo.
  Future<String?> _pickGroup(
    BuildContext context,
    OrganizationSnapshot snapshot,
    String? currentGroupId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupsSection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.semGrupo),
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final group in snapshot.groups)
              ListTile(
                title: Text(group.name),
                selected: group.id == currentGroupId,
                onTap: () => Navigator.of(context).pop(group.id),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _move(
    BuildContext context,
    Future<void> Function(List<String> orderedIds) reorder,
    List<String> ids,
    String id,
    int delta,
  ) async {
    final index = ids.indexOf(id);
    final target = index + delta;
    if (index == -1 || target < 0 || target >= ids.length) return;
    ids.removeAt(index);
    ids.insert(target, id);
    await runTaskAction(context, () => reorder(ids));
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
