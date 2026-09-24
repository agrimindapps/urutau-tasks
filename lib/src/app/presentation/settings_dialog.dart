import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urutau_tasks/l10n/gen/app_localizations.dart';

import '../../data/providers.dart';
import '../locale_resolution.dart';

/// Diálogo de configurações de idioma (spec 09, RF-03).
///
/// As opções são **Automático (sistema)**, Português (Brasil), English e
/// Español. A escolha é aplicada imediatamente e persistida localmente,
/// sobrevivendo a reinícios (CA-04).
Future<void> showSettingsDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  static const _options = [
    (localeModeSystem, null),
    ('pt-BR', Locale('pt', 'BR')),
    ('en', Locale('en')),
    ('es', Locale('es')),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current =
        ref.watch(localePreferenceProvider).value ?? localeModeSystem;

    String labelFor(String value) => switch (value) {
          localeModeSystem => l10n.languageSystem,
          'pt-BR' => l10n.languagePt,
          'en' => l10n.languageEn,
          'es' => l10n.languageEs,
          _ => value,
        };

    return AlertDialog(
      title: Text(l10n.settingsTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.languageLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            for (final (value, _) in _options)
              ListTile(
                dense: true,
                leading: Icon(
                  current == value
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(labelFor(value)),
                onTap: () async {
                  await ref
                      .read(localePreferenceStoreProvider)
                      .write(value);
                  ref.invalidate(localePreferenceProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.languageUpdated)),
                      );
                  }
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
