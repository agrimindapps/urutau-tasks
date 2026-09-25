@TestOn('!browser')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urutau_tasks/src/app/locale_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Preferência de idioma (RF-03)', () {
    test('padrão é Automático; persiste e sobrevive a reinícios (CA-04)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsLocalePreferenceStore();
      expect(await store.read(), kLocaleSystem);

      await store.write('es');
      // Nova instância simula reinício do app.
      expect(await SharedPrefsLocalePreferenceStore().read(), 'es');
    });

    test('Automático remove a substituição (CA-04)', () async {
      SharedPreferences.setMockInitialValues({'locale_preference': 'en'});
      final store = SharedPrefsLocalePreferenceStore();
      expect(await store.read(), 'en');

      await store.write(kLocaleSystem);
      expect(await store.read(), kLocaleSystem);
    });
  });

  group('Cobertura de traduções (CA-08/RF-05)', () {
    test('todas as chaves existem nos três idiomas', () {
      final pt = _arbKeys('lib/l10n/app_pt.arb');
      final en = _arbKeys('lib/l10n/app_en.arb');
      final es = _arbKeys('lib/l10n/app_es.arb');

      final missingEn = pt.difference(en);
      final missingEs = pt.difference(es);
      final extraEn = en.difference(pt);
      final extraEs = es.difference(pt);

      expect(missingEn, isEmpty,
          reason: 'chaves ausentes em app_en.arb: $missingEn');
      expect(missingEs, isEmpty,
          reason: 'chaves ausentes em app_es.arb: $missingEs');
      expect(extraEn, isEmpty, reason: 'chaves extras em app_en.arb: $extraEn');
      expect(extraEs, isEmpty, reason: 'chaves extras em app_es.arb: $extraEs');
    });

    test('nenhum valor vazio nos idiomas suportados', () {
      for (final path in [
        'lib/l10n/app_pt.arb',
        'lib/l10n/app_en.arb',
        'lib/l10n/app_es.arb',
      ]) {
        final data = _arbData(path);
        for (final entry in data.entries) {
          if (entry.key.startsWith('@')) continue;
          expect(entry.value, isNotEmpty,
              reason: 'valor vazio para ${entry.key} em $path');
        }
      }
    });

    test('placeholders coincidem entre idiomas', () {
      final pt = _arbData('lib/l10n/app_pt.arb');
      final en = _arbData('lib/l10n/app_en.arb');
      final es = _arbData('lib/l10n/app_es.arb');
      for (final entry in pt.entries) {
        if (!entry.key.startsWith('@') || entry.key.startsWith('@@')) {
          continue;
        }
        final name = entry.key.substring(1);
        for (final other in {'en': en, 'es': es}.entries) {
          final meta = other.value[entry.key] as Map<String, Object?>?;
          if (meta == null) continue;
          final ptPlaceholders = (entry.value as Map<String, Object?>)['placeholders'] as Map<String, Object?>?;
          final otherPlaceholders = meta['placeholders'] as Map<String, Object?>?;
          expect(otherPlaceholders?.keys.toSet(), ptPlaceholders?.keys.toSet(),
              reason: 'placeholders divergentes em $name (${other.key})');
        }
      }
    });
  });
}

Map<String, Object?> _arbData(String path) {
  final content = File(path).readAsStringSync();
  return jsonDecode(content) as Map<String, Object?>;
}

Set<String> _arbKeys(String path) {
  return _arbData(path).keys.where((k) => !k.startsWith('@')).toSet();
}
