import 'package:flutter/material.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trashAsync = ref.watch(trashProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trashTab)),
      body: trashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Text(l10n.emptyTrash, textAlign: TextAlign.center),
            );
          }
          return ListView(
            children: [
              for (final task in tasks)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(task.title),
                    trailing: TextButton.icon(
                      onPressed: () => ref
                          .read(tasksServiceProvider)
                          .restoreFromTrash(task.id),
                      icon: const Icon(Icons.restore),
                      label: Text(l10n.restore),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
