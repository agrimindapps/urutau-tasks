import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../data/providers.dart';
import '../features/tasks/presentation/tasks_shell.dart';
import 'locale_resolution.dart';

/// Raiz do aplicativo com resolução de idioma manual/automática
/// (spec 09, RF-01 a RF-03).
class UrutauApp extends ConsumerWidget {
  const UrutauApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference =
        ref.watch(localePreferenceProvider).value ?? localeModeSystem;
    final manual = manualLocaleFor(preference);

    return MaterialApp(
      title: 'Urutau Tasks',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Substituição manual (RF-03): locale explícito; automático
      // (RF-02): percorre a lista de preferidos do sistema.
      locale: manual,
      localeListResolutionCallback: (locales, supported) =>
          resolveAppLocale(
        preferred: locales ?? <Locale>[],
        supported: supported,
        manualLocale: manual,
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const TasksShell(),
    );
  }
}
