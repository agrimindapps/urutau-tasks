// Resolução de locale da interface (spec 09, RF-01 a RF-03).
import 'package:flutter/widgets.dart';

/// Modo da preferência de idioma (spec 09, RF-03).
const String localeModeSystem = 'system';

/// Valores persistidos: [localeModeSystem], `pt-BR`, `en` ou `es`.
const Set<String> localePreferenceValues = {
  localeModeSystem,
  'pt-BR',
  'en',
  'es',
};

/// Locale aplicado para um valor persistido; `null` = automático.
Locale? manualLocaleFor(String preference) {
  if (preference == localeModeSystem || preference.isEmpty) return null;
  return preference == 'pt-BR' ? const Locale('pt', 'BR') : Locale(preference);
}

/// Resolve o locale da interface (spec 09, RF-01 a RF-03).
///
/// - [manualLocale] definido ⇒ substituição manual (RF-03/CA-04): casa o
///   idioma-base com o suportado mais próximo.
/// - Modo automático (RF-02): percorre a lista de preferidos do sistema e
///   usa o primeiro idioma-base com tradução; português de qualquer
///   região casa com `pt-BR` (RF-01/CA-02).
/// - Sem correspondência ⇒ primeiro suportado (`pt-BR`, CA-03).
Locale resolveAppLocale({
  required List<Locale> preferred,
  required Iterable<Locale> supported,
  Locale? manualLocale,
}) {
  final supportedList = supported.toList();
  String baseOf(String languageCode) {
    // Aceita tanto `pt-BR` quanto `pt_BR` como idioma-base (ex.: um
    // Locale construído com a tag completa em uma única string).
    return languageCode.split(RegExp(r'[-_]')).first.toLowerCase();
  }

  final candidates = manualLocale != null ? [manualLocale] : preferred;
  for (final candidate in candidates) {
    final base = baseOf(candidate.languageCode);
    for (final locale in supportedList) {
      if (baseOf(locale.languageCode) == base) return locale;
    }
  }
  // Fallback explícito para pt-BR (spec 09, CA-03), independente da
  // ordem de [supported].
  for (final locale in supportedList) {
    if (baseOf(locale.languageCode) == 'pt') return locale;
  }
  return supportedList.first;
}
