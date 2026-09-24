import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/preferences/app_preferences_repository.dart';
import '../features/tasks/presentation/task_home_page.dart';
import '../features/tasks/presentation/task_detail_page.dart';
import '../features/notifications/application/notification_providers.dart';
import '../features/tasks/application/task_providers.dart';
import '../l10n/generated/app_localizations.dart';

class UrutauApp extends ConsumerStatefulWidget {
  const UrutauApp({super.key});

  @override
  ConsumerState<UrutauApp> createState() => _UrutauAppState();
}

class _UrutauAppState extends ConsumerState<UrutauApp>
    with WidgetsBindingObserver {
  // The device locale supplies the regional first weekday even when the
  // selected interface language has no date-symbol variant for that region.
  static final _dateSymbolsByLocale = dateTimeSymbolMap();

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(localNotificationServiceProvider)
            .ensureStarted(
              onOpenTask: _openTask,
              onForegroundReminder: _showForegroundReminder,
            ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      ref.read(localNotificationServiceProvider).onLifecycleChanged(state),
    );
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (!mounted) return;
    setState(() {});
    unawaited(ref.read(localNotificationServiceProvider).refreshLocalization());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(languagePreferenceProvider, (_, _) {
      unawaited(
        ref.read(localNotificationServiceProvider).refreshLocalization(),
      );
    });
    final preference =
        ref.watch(languagePreferenceProvider).asData?.value ??
        AppLanguagePreference.system;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      locale: _localeFor(
        preference,
        WidgetsBinding.instance.platformDispatcher.locale,
      ),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B62)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        _PortugueseBrazilLocaleDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, _) {
        final deviceLocales = locales ?? const <Locale>[];
        // Finding a translated language later in the preferred list must not
        // replace the region that drives calendar and number formatting.
        final deviceRegionLocale = deviceLocales.firstOrNull;
        if (preference != AppLanguagePreference.system) {
          return _localeFor(preference, deviceRegionLocale);
        }
        for (final locale in deviceLocales) {
          switch (locale.languageCode) {
            case 'pt':
              return _localeForLanguage('pt', deviceRegionLocale);
            case 'en':
              return _localeForLanguage('en', deviceRegionLocale);
            case 'es':
              return _localeForLanguage('es', deviceRegionLocale);
          }
        }
        return _localeForLanguage('pt', deviceRegionLocale);
      },
      home: const TaskHomePage(),
    );
  }

  void _openTask(String taskId) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailPage(taskId: taskId),
      ),
    );
  }

  void _showForegroundReminder(String taskId, String title) {
    final context = _messengerKey.currentContext;
    if (context == null) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: () => _openTask(taskId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  Locale? _localeFor(AppLanguagePreference preference, [Locale? deviceLocale]) {
    final language = switch (preference) {
      AppLanguagePreference.system => null,
      AppLanguagePreference.portugueseBrazil => 'pt',
      AppLanguagePreference.english => 'en',
      AppLanguagePreference.spanish => 'es',
    };
    if (language == null) return null;
    return _localeForLanguage(language, deviceLocale);
  }

  Locale _localeForLanguage(String language, Locale? deviceLocale) {
    final region = deviceLocale?.countryCode?.toUpperCase();
    final exactRegionalName = region == null ? null : '${language}_$region';
    final exactRegionalSymbols = exactRegionalName == null
        ? null
        : _dateSymbolsByLocale[exactRegionalName];
    final regionalFirstDay = _regionalFirstDay(deviceLocale);

    if (exactRegionalName != null &&
        exactRegionalSymbols != null &&
        (regionalFirstDay == null ||
            exactRegionalSymbols.FIRSTDAYOFWEEK == regionalFirstDay)) {
      return Locale(language, region);
    }

    if (regionalFirstDay != null) {
      final matchingLocales =
          _dateSymbolsByLocale.entries
              .where(
                (entry) =>
                    (entry.key == language ||
                        entry.key.startsWith('${language}_')) &&
                    entry.value.FIRSTDAYOFWEEK == regionalFirstDay,
              )
              .toList()
            ..sort((first, second) {
              final firstMatchesRegion =
                  region != null &&
                  first.key.toUpperCase().endsWith('_$region');
              final secondMatchesRegion =
                  region != null &&
                  second.key.toUpperCase().endsWith('_$region');
              if (firstMatchesRegion != secondMatchesRegion) {
                return firstMatchesRegion ? -1 : 1;
              }
              return first.key.compareTo(second.key);
            });
      if (matchingLocales.isNotEmpty) {
        return _localeFromDateLocaleName(matchingLocales.first.key);
      }
    }

    if (region != null) return Locale(language, region);
    return language == 'pt' ? const Locale('pt', 'BR') : Locale(language);
  }

  int? _regionalFirstDay(Locale? deviceLocale) {
    final region = deviceLocale?.countryCode?.toUpperCase();
    if (region == null) return null;
    final exact = _dateSymbolsByLocale[deviceLocale.toString()];
    if (exact != null) return exact.FIRSTDAYOFWEEK;
    final regionalLocales =
        _dateSymbolsByLocale.entries
            .where((entry) => entry.key.toUpperCase().endsWith('_$region'))
            .toList()
          ..sort((first, second) => first.key.compareTo(second.key));
    if (regionalLocales.isEmpty) return null;
    return regionalLocales.first.value.FIRSTDAYOFWEEK;
  }

  Locale _localeFromDateLocaleName(String name) {
    final parts = name.split('_');
    if (parts.length == 1) return Locale(parts.single);
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    return Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
      countryCode: parts[2],
    );
  }
}

class _PortugueseBrazilLocaleDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _PortugueseBrazilLocaleDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.delegate
      .load(locale.languageCode == 'pt' ? const Locale('pt', 'BR') : locale);

  @override
  bool shouldReload(_PortugueseBrazilLocaleDelegate old) => false;
}
