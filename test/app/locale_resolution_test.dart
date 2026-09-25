import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/app/app.dart';

void main() {
  const supported = [Locale('en'), Locale('es'), Locale('pt')];

  test('usa o idioma do sistema quando suportado (CA-01)', () {
    final locale = resolveAppLocale(
      deviceLocales: const [Locale('en', 'US')],
      supported: supported,
    );
    expect(locale.languageCode, 'en');

    expect(
      resolveAppLocale(
        deviceLocales: const [Locale('pt', 'BR')],
        supported: supported,
      ).languageCode,
      'pt',
    );
    expect(
      resolveAppLocale(
        deviceLocales: const [Locale('es')],
        supported: supported,
      ).languageCode,
      'es',
    );
  });

  test('variantes regionais caem no idioma-base (CA-02)', () {
    expect(
      resolveAppLocale(
        deviceLocales: const [Locale('en', 'GB')],
        supported: supported,
      ).languageCode,
      'en',
    );
    expect(
      resolveAppLocale(
        deviceLocales: const [Locale('es', 'MX')],
        supported: supported,
      ).languageCode,
      'es',
    );
  });

  test('fallback é pt-BR para idiomas sem tradução (CA-03)', () {
    // Região do dispositivo preservada (RF-04).
    final locale = resolveAppLocale(
      deviceLocales: const [Locale('fr', 'FR')],
      supported: supported,
    );
    expect(locale.languageCode, 'pt');
    expect(locale.countryCode, 'FR');

    // Sem região conhecida, o fallback é pt-BR completo.
    expect(
      resolveAppLocale(deviceLocales: const [], supported: supported),
      const Locale('pt', 'BR'),
    );
    expect(
      resolveAppLocale(
        deviceLocales: const [Locale('fr')],
        supported: supported,
      ),
      const Locale('pt', 'BR'),
    );
  });

  test('percorre a lista de preferidos do sistema (RF-02)', () {
    final locale = resolveAppLocale(
      deviceLocales: const [Locale('fr'), Locale('de'), Locale('es', 'AR')],
      supported: supported,
    );
    expect(locale.languageCode, 'es');
  });

  test('região segue o dispositivo mesmo com idioma diferente (CA-06/RF-04)',
      () {
    final locale = resolveAppLocale(
      deviceLocales: const [Locale('en', 'GB')],
      override: 'pt-BR',
    );
    expect(locale.languageCode, 'pt');
    expect(locale.countryCode, 'GB');

    final es = resolveAppLocale(
      deviceLocales: const [Locale('en', 'US')],
      override: 'es',
    );
    expect(es.languageCode, 'es');
    expect(es.countryCode, 'US');
  });

  test('substituição manual respeitada e automático volta ao sistema (CA-04)',
      () {
    final manual = resolveAppLocale(
      deviceLocales: const [Locale('en', 'US')],
      override: 'es',
    );
    expect(manual.languageCode, 'es');

    final automatic = resolveAppLocale(
      deviceLocales: const [Locale('en', 'US')],
      override: null,
    );
    expect(automatic.languageCode, 'en');
  });

  test('sem região conhecida o fallback preserva pt-BR (RF-01)', () {
    final locale = resolveAppLocale(
      deviceLocales: const [Locale('fr')],
      supported: supported,
    );
    expect(locale, const Locale('pt', 'BR'));
  });

  test('resolveLocale delega para a mesma resolução (callback do MaterialApp)',
      () {
    expect(resolveLocale([const Locale('pt', 'PT')], supported)?.languageCode,
        'pt');
    expect(resolveLocale(const [], supported), const Locale('pt', 'BR'));
  });
}
