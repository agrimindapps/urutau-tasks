import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../data/providers.dart';
import '../features/tasks/presentation/tasks_shell.dart';
import 'locale_preference.dart';

/// Chave global usada para navegar ao tocar em uma notificação (CA-06).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Raiz do aplicativo: tema Material 3 e i18n (docs/03, princípios 6-7).
class UrutauApp extends ConsumerWidget {
  const UrutauApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(localePreferenceProvider);
    final deviceLocales = View.of(context).platformDispatcher.locales;

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
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
      locale: resolveAppLocale(
        deviceLocales: deviceLocales,
        override: preference == kLocaleSystem ? null : preference,
      ),
      localeListResolutionCallback: resolveLocale,
      home: const TasksShell(),
    );
  }
}

/// Resolução por idioma-base com fallback `pt-BR` (spec 09, RF-01/RF-02).
Locale? resolveLocale(List<Locale>? locales, Iterable<Locale> supported) {
  return resolveAppLocale(
    deviceLocales: locales ?? const [],
    override: null,
    supported: supported,
  );
}

/// Locale efetivo do aplicativo (spec 09, RF-03/RF-04).
///
/// O **idioma** segue a substituição manual ou os idiomas preferidos do
/// sistema (com fallback `pt-BR`); a **região** sempre segue o dispositivo,
/// mantendo datas, números e início da semana regionais mesmo com a
/// interface em outro idioma.
Locale resolveAppLocale({
  required List<Locale> deviceLocales,
  String? override,
  Iterable<Locale> supported = const [Locale('en'), Locale('es'), Locale('pt')],
}) {
  final region = _deviceRegion(deviceLocales);

  if (override != null) {
    final language = override.split('-').first;
    return Locale(language, region);
  }

  for (final preferred in deviceLocales) {
    for (final candidate in supported) {
      if (candidate.languageCode == preferred.languageCode) {
        return Locale(candidate.languageCode, region);
      }
    }
  }
  return Locale('pt', region ?? 'BR');
}

String? _deviceRegion(List<Locale> deviceLocales) {
  for (final locale in deviceLocales) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return locale.countryCode;
    }
  }
  return null;
}
