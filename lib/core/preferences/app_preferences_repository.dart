import '../database/app_database.dart';

enum AppLanguagePreference {
  system('system'),
  portugueseBrazil('pt-BR'),
  english('en'),
  spanish('es');

  const AppLanguagePreference(this.storageValue);

  final String storageValue;

  static AppLanguagePreference fromStorageValue(String value) =>
      AppLanguagePreference.values.firstWhere(
        (preference) => preference.storageValue == value,
        orElse: () => AppLanguagePreference.system,
      );
}

class AppPreferencesRepository {
  AppPreferencesRepository(this._database);

  final AppDatabase _database;
  static const _languageKey = 'interface_language';

  Stream<AppLanguagePreference> watchLanguagePreference() =>
      (_database.select(_database.appSettings)
            ..where((setting) => setting.settingKey.equals(_languageKey)))
          .watch()
          .map(
            (rows) => rows.isEmpty
                ? AppLanguagePreference.system
                : AppLanguagePreference.fromStorageValue(rows.first.value),
          );

  Future<void> setLanguagePreference(AppLanguagePreference preference) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            settingKey: _languageKey,
            value: preference.storageValue,
          ),
        );
  }
}
