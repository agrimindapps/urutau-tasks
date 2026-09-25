import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/gen/app_localizations.dart';
import '../features/tasks/presentation/tasks_shell.dart';

/// Raiz do aplicativo: tema Material 3 e i18n (docs/03, princípios 6-7).
class UrutauApp extends StatelessWidget {
  const UrutauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urutau Tasks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E6B4F)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveLocale,
      home: const TasksShell(),
    );
  }
}

/// Resolução de idioma por idioma-base com fallback `pt-BR`
/// (spec 09, RF-01/RF-02).
Locale? resolveLocale(List<Locale>? locales, Iterable<Locale> supported) {
  if (locales == null || locales.isEmpty) {
    return const Locale('pt');
  }
  for (final preferred in locales) {
    for (final candidate in supported) {
      if (candidate.languageCode == preferred.languageCode) {
        return candidate;
      }
    }
  }
  return const Locale('pt');
}
