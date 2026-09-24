import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../../../data/providers.dart';

import '../../my_day/presentation/my_day_page.dart';
import '../../organization/presentation/lists_page.dart';
import 'tasks_list_page.dart';
import 'trash_page.dart';

/// Navegação raiz: My Day, Tarefas, Listas e Lixeira.
///
/// Também dispara o rollover do My Day na abertura e à meia-noite local
/// (spec 03, RF-10), além de ao voltar ao primeiro plano.
class TasksShell extends ConsumerStatefulWidget {
  const TasksShell({super.key});

  @override
  ConsumerState<TasksShell> createState() => _TasksShellState();
}

class _TasksShellState extends ConsumerState<TasksShell>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _midnightTimer;

  static const _breakpoint = 800.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runRollover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runRollover();
    }
  }

  void _runRollover() {
    unawaited(ref.read(myDayServiceProvider).rollover());
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _midnightTimer = Timer(nextMidnight.difference(now), _runRollover);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = const [
      MyDayPage(),
      TasksListPage(),
      ListsPage(),
      TrashPage(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= _breakpoint;

    final destinations = [
      (
        icon: const Icon(Icons.wb_sunny_outlined),
        selected: const Icon(Icons.wb_sunny),
        label: l10n.myDayTab,
      ),
      (
        icon: const Icon(Icons.check_box_outlined),
        selected: const Icon(Icons.check_box),
        label: l10n.tasksTab,
      ),
      (
        icon: const Icon(Icons.list_alt_outlined),
        selected: const Icon(Icons.list_alt),
        label: l10n.listsTab,
      ),
      (
        icon: const Icon(Icons.delete_outline),
        selected: const Icon(Icons.delete),
        label: l10n.trashTab,
      ),
    ];

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selected,
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: destination.icon,
              selectedIcon: destination.selected,
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
