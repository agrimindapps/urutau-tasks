import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../../../data/providers.dart';
import '../../../app/presentation/settings_dialog.dart';
import '../../data_transfer/presentation/data_transfer_section.dart';
import '../domain/organization.dart';
import 'name_dialog.dart';

/// Gestão de listas, grupos, categorias e tags (spec 02).
class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(listsProvider).value ?? const <TaskList>[];
    final groups = ref.watch(groupsProvider).value ?? const <Group>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final service = ref.read(organizationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listsTab),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsDialog(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _SectionHeader(
            title: l10n.listsSection,
            actionIcon: Icons.add,
            actionTooltip: l10n.newList,
            onAction: () async {
              final name = await showNameDialog(context, title: l10n.newList);
              if (name == null || !context.mounted) return;
              try {
                await service.createList(name);
              } catch (error) {
                if (context.mounted) showDomainError(context, error);
              }
            },
          ),
          if (lists.isEmpty)
            _Empty(text: l10n.emptyLists)
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: (oldIndex, newIndex) =>
                  service.reorderLists(oldIndex, newIndex),
              children: [
                for (final index in lists.indexed)
                  Card(
                    key: ValueKey(index.$2.id),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(index.$2.name),
                      subtitle: Text(
                        _groupName(groups, index.$2.groupId) ?? l10n.noGroup,
                      ),
                      trailing: _Menu(
                        items: [
                          _MenuItem(l10n.rename, Icons.edit_outlined, () async {
                            final name = await showNameDialog(
                              context,
                              title: l10n.rename,
                              initial: index.$2.name,
                            );
                            if (name == null || !context.mounted) return;
                            try {
                              await service.renameList(index.$2.id, name);
                            } catch (error) {
                              if (context.mounted) {
                                showDomainError(context, error);
                              }
                            }
                          }),
                          _MenuItem(l10n.moveToGroup, Icons.group_outlined,
                              () async {
                            final groupId = await _pickGroup(
                              context,
                              groups: groups,
                              current: index.$2.groupId,
                            );
                            if (groupId == null ||
                                groupId == _cancelMarker ||
                                !context.mounted) {
                              return;
                            }
                            await service.moveListToGroup(
                              index.$2.id,
                              groupId.isEmpty ? null : groupId,
                            );
                          }),
                          _MenuItem(l10n.delete, Icons.delete_outline,
                              () async {
                            await _deleteList(
                              context,
                              ref,
                              list: index.$2,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          _SectionHeader(
            title: l10n.groupsSection,
            actionIcon: Icons.add,
            actionTooltip: l10n.newGroup,
            onAction: () async {
              final name = await showNameDialog(context, title: l10n.newGroup);
              if (name == null || !context.mounted) return;
              try {
                await service.createGroup(name);
              } catch (error) {
                if (context.mounted) showDomainError(context, error);
              }
            },
          ),
          if (groups.isEmpty)
            _Empty(text: l10n.emptyGroups)
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: (oldIndex, newIndex) =>
                  service.reorderGroups(oldIndex, newIndex),
              children: [
                for (final group in groups)
                  Card(
                    key: ValueKey(group.id),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(group.name),
                      trailing: _Menu(
                        items: [
                          _MenuItem(l10n.rename, Icons.edit_outlined, () async {
                            final name = await showNameDialog(
                              context,
                              title: l10n.rename,
                              initial: group.name,
                            );
                            if (name == null || !context.mounted) return;
                            try {
                              await service.renameGroup(group.id, name);
                            } catch (error) {
                              if (context.mounted) {
                                showDomainError(context, error);
                              }
                            }
                          }),
                          _MenuItem(l10n.delete, Icons.delete_outline, () async {
                            final confirmed = await _confirm(
                              context,
                              title: l10n.deleteGroupTitle,
                              notice: l10n.deleteGroupNotice,
                            );
                            if (confirmed != true || !context.mounted) return;
                            await service.deleteGroup(group.id);
                          }),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          _SectionHeader(
            title: l10n.categoriesSection,
            actionIcon: Icons.add,
            actionTooltip: l10n.newCategory,
            onAction: () async {
              final name =
                  await showNameDialog(context, title: l10n.newCategory);
              if (name == null || !context.mounted) return;
              try {
                await service.createCategory(name);
              } catch (error) {
                if (context.mounted) showDomainError(context, error);
              }
            },
          ),
          if (categories.isEmpty)
            _Empty(text: l10n.emptyCategories)
          else
            for (final category in categories)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(category.name),
                  trailing: _Menu(
                    items: [
                      _MenuItem(l10n.rename, Icons.edit_outlined, () async {
                        final name = await showNameDialog(
                          context,
                          title: l10n.rename,
                          initial: category.name,
                        );
                        if (name == null || !context.mounted) return;
                        try {
                          await service.renameCategory(category.id, name);
                        } catch (error) {
                          if (context.mounted) {
                            showDomainError(context, error);
                          }
                        }
                      }),
                      _MenuItem(l10n.delete, Icons.delete_outline, () async {
                        final confirmed = await _confirm(
                          context,
                          title: l10n.deleteCategoryTitle,
                          notice: l10n.deleteCategoryNotice,
                        );
                        if (confirmed != true || !context.mounted) return;
                        await service.deleteCategory(category.id);
                      }),
                    ],
                  ),
                ),
              ),
          _SectionHeader(
            title: l10n.tagsSection,
            actionIcon: Icons.add,
            actionTooltip: l10n.newTag,
            onAction: () async {
              final name = await showNameDialog(context, title: l10n.newTag);
              if (name == null || !context.mounted) return;
              try {
                await service.createTag(name);
              } catch (error) {
                if (context.mounted) showDomainError(context, error);
              }
            },
          ),
          if (tags.isEmpty)
            _Empty(text: l10n.emptyTags)
          else
            for (final tag in tags)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(tag.name),
                  trailing: _Menu(
                    items: [
                      _MenuItem(l10n.rename, Icons.edit_outlined, () async {
                        final name = await showNameDialog(
                          context,
                          title: l10n.rename,
                          initial: tag.name,
                        );
                        if (name == null || !context.mounted) return;
                        try {
                          await service.renameTag(tag.id, name);
                        } catch (error) {
                          if (context.mounted) {
                            showDomainError(context, error);
                          }
                        }
                      }),
                      _MenuItem(l10n.delete, Icons.delete_outline, () async {
                        final confirmed = await _confirm(
                          context,
                          title: l10n.deleteTagTitle,
                          notice: l10n.deleteTagNotice,
                        );
                        if (confirmed != true || !context.mounted) return;
                        await service.deleteTag(tag.id);
                      }),
                    ],
                  ),
                ),
              ),
          const DataTransferSection(),
        ],
      ),
    );
  }

  String? _groupName(List<Group> groups, String? groupId) {
    if (groupId == null) return null;
    for (final group in groups) {
      if (group.id == groupId) return group.name;
    }
    return null;
  }

  Future<void> _deleteList(
    BuildContext context,
    WidgetRef ref, {
    required TaskList list,
  }) async {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(organizationServiceProvider);
    final lists = ref.read(listsProvider).value ?? const <TaskList>[];
    final others = lists.where((l) => l.id != list.id).toList();

    try {
      final taskCount = await service.countTasksInList(list.id);
      if (!context.mounted) return;
      if (taskCount == 0) {
        final confirmed = await _confirm(
          context,
          title: l10n.deleteListTitle,
          notice: null,
        );
        if (confirmed != true || !context.mounted) return;
        await service.deleteList(list.id);
        return;
      }

      if (others.isEmpty) {
        // RF-06: bloqueado sem outra lista disponível.
        await service.deleteList(list.id);
        return;
      }

      // CA-07: excluir lista com tarefas exige destino escolhido.
      final destinationId = await _pickDestination(context, others: others);
      if (destinationId == null || !context.mounted) return;
      await service.deleteList(list.id, destinationId: destinationId);
    } catch (error) {
      if (context.mounted) showDomainError(context, error);
    }
  }

  Future<String?> _pickDestination(
    BuildContext context, {
    required List<TaskList> others,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteListTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.tasksMoveNotice),
            const SizedBox(height: 16),
            Text(l10n.destinationLabel,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final list in others)
              ListTile(
                leading: const Icon(Icons.radio_button_unchecked),
                title: Text(list.name),
                onTap: () => Navigator.of(context).pop(list.id),
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

  static const _cancelMarker = '__cancel__';

  Future<String?> _pickGroup(
    BuildContext context, {
    required List<Group> groups,
    required String? current,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.moveToGroup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                (current ?? '').isEmpty
                    ? Icons.check
                    : Icons.radio_button_unchecked,
              ),
              title: Text(l10n.noGroup),
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final group in groups)
              ListTile(
                leading: Icon(
                  current == group.id
                      ? Icons.check
                      : Icons.radio_button_unchecked,
                ),
                title: Text(group.name),
                onTap: () => Navigator.of(context).pop(group.id),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_cancelMarker),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String? notice,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(notice ?? l10n.delete),
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
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
  });

  final String title;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            tooltip: actionTooltip,
            icon: Icon(actionIcon),
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.icon, this.onPressed);

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _Menu extends StatelessWidget {
  const _Menu({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuItem>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (item) => item.onPressed(),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(item.icon, size: 20),
                const SizedBox(width: 12),
                Text(item.label),
              ],
            ),
          ),
      ],
    );
  }
}
