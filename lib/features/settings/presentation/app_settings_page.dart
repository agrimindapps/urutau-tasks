import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences_repository.dart';
import '../../backup/presentation/data_portability_page.dart';
import '../../tasks/application/task_providers.dart';
import '../../../l10n/generated/app_localizations.dart';

class AppSettingsPage extends ConsumerStatefulWidget {
  const AppSettingsPage({super.key});

  @override
  ConsumerState<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends ConsumerState<AppSettingsPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preference =
        ref.watch(languagePreferenceProvider).asData?.value ??
        AppLanguagePreference.system;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.languagePreferenceHelp),
              const SizedBox(height: 20),
              DropdownButtonFormField<AppLanguagePreference>(
                initialValue: preference,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.language,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: AppLanguagePreference.system,
                    child: Text(l10n.automaticSystem),
                  ),
                  DropdownMenuItem(
                    value: AppLanguagePreference.portugueseBrazil,
                    child: Text(l10n.languagePortuguese),
                  ),
                  DropdownMenuItem(
                    value: AppLanguagePreference.english,
                    child: Text(l10n.languageEnglish),
                  ),
                  DropdownMenuItem(
                    value: AppLanguagePreference.spanish,
                    child: Text(l10n.languageSpanish),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null && value != preference) {
                          _savePreference(value);
                        }
                      },
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l10n.backupAndPortability),
                  subtitle: Text(l10n.backupAndPortabilityDescription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const DataPortabilityPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePreference(AppLanguagePreference preference) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(appPreferencesRepositoryProvider)
          .setLanguagePreference(preference);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
