import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../domain/task.dart';
import 'task_detail_page.dart';
import 'task_errors.dart';
import 'task_tile.dart';

/// Lixeira: exclusões lógicas restauráveis (spec 01, RF-02/RF-09/RF-10).
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTrash)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          final trashed =
              all.where((t) => t.status == TaskStatus.trash).toList();
          if (trashed.isEmpty) {
            return Center(child: Text(l10n.emptyTrash));
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.trashSubtitle),
              ),
              for (final task in trashed)
                TaskTile(
                  task: task,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskDetailPage(taskId: task.id),
                    ),
                  ),
                  onRestore: () => runTaskAction(context, () async {
                    await ref.read(tasksServiceProvider).restore(task.id);
                  }),
                ),
            ],
          );
        },
      ),
    );
  }
}
