import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../my_day/presentation/my_day_page.dart';
import '../../organization/presentation/lists_page.dart';
import '../../search/presentation/search_page.dart';
import 'tasks_list_page.dart';
import 'trash_page.dart';

/// Navegação adaptativa entre as áreas do MVP (docs/03, princípio 6).
class TasksShell extends StatefulWidget {
  const TasksShell({super.key});

  @override
  State<TasksShell> createState() => _TasksShellState();
}

class _TasksShellState extends State<TasksShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final destinations = [
      (Icons.wb_sunny_outlined, l10n.navMyDay),
      (Icons.checklist_outlined, l10n.navTasks),
      (Icons.search, l10n.navSearch),
      (Icons.list_alt_outlined, l10n.navLists),
      (Icons.delete_outline, l10n.navTrash),
    ];

    final body = switch (_index) {
      0 => const MyDayPage(),
      1 => const TasksListPage(),
      2 => const SearchPage(),
      3 => const ListsPage(),
      _ => const TrashPage(),
    };

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final (icon, label) in destinations)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
