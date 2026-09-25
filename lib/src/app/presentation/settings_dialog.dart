import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../locale_preference.dart';

/// Substituição manual de idioma (spec 09, RF-03).
///
/// "Automático" remove a substituição; a escolha é aplicada imediatamente e
/// persiste apenas no dispositivo (fora do backup — CA-09).
class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localePreferenceProvider);

    return AlertDialog(
      title: Text(l10n.settingsTitle),
      content: RadioGroup<String>(
        groupValue: current,
        onChanged: (value) => _select(ref, value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              key: const Key('locale-system'),
              title: Text(l10n.languageSystem),
              value: kLocaleSystem,
            ),
            RadioListTile<String>(
              key: const Key('locale-pt-BR'),
              title: Text(l10n.languagePt),
              value: 'pt-BR',
            ),
            RadioListTile<String>(
              key: const Key('locale-en'),
              title: Text(l10n.languageEn),
              value: 'en',
            ),
            RadioListTile<String>(
              key: const Key('locale-es'),
              title: Text(l10n.languageEs),
              value: 'es',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  void _select(WidgetRef ref, String? value) {
    if (value == null) return;
    ref.read(localePreferenceProvider.notifier).set(value);
  }
}
