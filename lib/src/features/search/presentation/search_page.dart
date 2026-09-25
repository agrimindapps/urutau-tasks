import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../../tasks/presentation/task_errors.dart';
import '../../tasks/presentation/task_tile.dart';
import '../../recurrence/domain/recurrence.dart';
import '../domain/task_query.dart';
import 'filter_sheet.dart';

/// Busca global com filtros combinados (spec 05, RF-01 a RF-19).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  String _text = '';
  TaskFilter _filter = const TaskFilter();

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Debounce enquanto digita (spec 05, RF-06).
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _text = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(tasksProvider);
    final organization = ref.watch(organizationProvider);
    final series = ref.watch(allSeriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search-field'),
          controller: _queryController,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          IconButton(
            tooltip: l10n.filtersTooltip,
            key: const Key('filters-button'),
            icon: const Icon(Icons.tune),
            onPressed: () => _openFilters(context),
          ),
        ],
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          final snapshot = organization.asData?.value;
          final listGroupId = {
            if (snapshot != null)
              for (final list in snapshot.lists) list.id: list.groupId,
          };
          final seriesCancelled = {
            for (final s in series.asData?.value ?? const <RecurringSeries>[]) s.id: s.cancelled,
          };
          final matches = searchTasks(
            all,
            text: _text,
            filter: _filter,
            context: QueryContext(
              listGroupId: listGroupId,
              seriesCancelled: seriesCancelled,
            ),
            today: ref.read(myDayServiceProvider).todayKey,
          );
          if (matches.isEmpty) {
            return Center(child: Text(l10n.noResults));
          }
          return ListView(
            children: [
              for (final match in matches)
                _resultTile(context, match),
            ],
          );
        },
      ),
    );
  }

  Widget _resultTile(BuildContext context, TaskMatch match) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (match.field) {
      MatchField.title => l10n.matchTitle,
      MatchField.notes => l10n.matchNotes,
      MatchField.subtask => l10n.matchSubtask,
    };
    return TaskTile(
      task: match.task,
      matchLabel: label,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailPage(taskId: match.task.id),
        ),
      ),
      onToggle: (checked) => runTaskAction(context, () async {
        final service = ref.read(tasksServiceProvider);
        if (checked ?? false) {
          await service.completeTask(match.task.id);
        } else {
          await service.reopenTask(match.task.id);
        }
      }),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final snapshot = await ref.read(organizationServiceProvider).fetchSnapshot();
    if (!context.mounted) return;
    final result = await FilterSheet.show(
      context,
      initial: _filter,
      lists: [for (final l in snapshot.lists) (l.id, l.name)],
      groups: [for (final g in snapshot.groups) (g.id, g.name)],
      categories: [for (final c in snapshot.categories) (c.id, c.name)],
      tags: [for (final t in snapshot.tags) (t.id, t.name)],
    );
    if (result == null || !context.mounted) return;
    setState(() => _filter = result);
  }
}
