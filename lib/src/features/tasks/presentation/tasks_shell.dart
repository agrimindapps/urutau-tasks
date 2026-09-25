import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../data/providers.dart';
import '../../my_day/presentation/my_day_page.dart';
import '../../organization/presentation/lists_page.dart';
import '../../search/presentation/search_page.dart';
import 'tasks_list_page.dart';
import 'trash_page.dart';

/// Navegação adaptativa entre as áreas do MVP (docs/03, princípio 6).
class TasksShell extends ConsumerStatefulWidget {
  const TasksShell({super.key});

  @override
  ConsumerState<TasksShell> createState() => _TasksShellState();
}

class _TasksShellState extends ConsumerState<TasksShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Garante a reconciliação desde a inicialização (spec 08, RF-05) e o
    // roteamento ao tocar no aviso (CA-06).
    Future.microtask(() {
      ref.read(reminderOpenRoutingProvider);
      ref.read(reminderCoordinatorProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Aviso de primeiro plano no disparo do lembrete (spec 08, §8, CA-05).
    ref.listen(reminderNoticesProvider, (previous, next) {
      final task = next.asData?.value;
      if (task == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.reminderNoticeTitle}: ${task.title}'),
        ),
      );
    });
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
