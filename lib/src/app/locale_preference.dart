/// Preferência de idioma da instalação (spec 09, RF-03).
///
/// Dado de apresentação local: sobrevive a reinícios e fica **fora** do
/// backup/exportação/importação (CA-09).
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Valor de sistema: segue os idiomas preferidos do dispositivo.
const String kLocaleSystem = 'system';

/// Opções manuais do MVP: `pt-BR`, `en` e `es` (spec 09, RF-01/RF-03).
const List<String> kLocaleOptions = ['pt-BR', 'en', 'es'];

/// Porta de persistência da preferência.
abstract class LocalePreferenceStore {
  Future<String> read();
  Future<void> write(String value);
}

/// Persistência em `shared_preferences` (local ao dispositivo).
class SharedPrefsLocalePreferenceStore implements LocalePreferenceStore {
  static const String _key = 'locale_preference';

  @override
  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? kLocaleSystem;
  }

  @override
  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}

/// Implementação em memória para testes.
class InMemoryLocalePreferenceStore implements LocalePreferenceStore {
  String _value = kLocaleSystem;

  @override
  Future<String> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}
