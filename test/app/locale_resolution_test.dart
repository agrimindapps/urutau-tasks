import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/app/app.dart';

void main() {
  const supported = [Locale('en'), Locale('es'), Locale('pt')];

  test('usa o idioma do sistema quando suportado (CA-01)', () {
    expect(resolveLocale([const Locale('en', 'US')], supported), Locale('en'));
    expect(resolveLocale([const Locale('pt', 'BR')], supported), Locale('pt'));
    expect(resolveLocale([const Locale('es')], supported), Locale('es'));
  });

  test('variantes regionais caem no idioma-base (CA-02)', () {
    expect(resolveLocale([const Locale('en', 'GB')], supported), Locale('en'));
    expect(resolveLocale([const Locale('es', 'MX')], supported), Locale('es'));
    expect(resolveLocale([const Locale('pt', 'PT')], supported), Locale('pt'));
  });

  test('fallback é pt-BR para idiomas sem tradução (CA-03)', () {
    expect(resolveLocale([const Locale('fr')], supported), Locale('pt'));
    expect(resolveLocale(null, supported), Locale('pt'));
    expect(resolveLocale(const [], supported), Locale('pt'));
  });

  test('percorre a lista de preferidos do sistema (RF-02)', () {
    expect(
      resolveLocale(const [Locale('fr'), Locale('de'), Locale('es', 'AR')], supported),
      Locale('es'),
    );
  });
}
