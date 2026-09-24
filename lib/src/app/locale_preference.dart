// Preferência local de idioma (spec 09, RF-03).
//
// É dado de apresentação da instalação: fica fora do banco e, portanto,
// fora de backup, exportação e importação (RF-02/CA-09).

import 'package:shared_preferences/shared_preferences.dart';

import 'locale_resolution.dart';

/// Armazenamento da preferência de idioma.
abstract interface class LocalePreferenceStore {
  /// Retorna o valor persistido ou [localeModeSystem] quando ausente.
  Future<String> read();

  Future<void> write(String value);
}

/// Implementação com `shared_preferences` — dados do sistema operacional,
/// nunca incluídos no retrato lógico do aplicativo.
class SharedPrefsLocalePreferenceStore implements LocalePreferenceStore {
  static const _key = 'urutau_ui_language';

  @override
  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? localeModeSystem;
  }

  @override
  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}
