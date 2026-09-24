import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:urutau_tasks/src/app/device_format.dart';
import 'package:urutau_tasks/src/app/locale_resolution.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const supported = [Locale('pt', 'BR'), Locale('en'), Locale('es')];

  group('RF-01/CA-01 — variantes regionais casam com o idioma-base', () {
    test('CA-01 português (qualquer região) → pt-BR', () {
      expect(
        resolveAppLocale(
          preferred: const [Locale('pt', 'PT')],
          supported: supported,
        ),
        const Locale('pt', 'BR'),
      );
      expect(
        resolveAppLocale(
          preferred: const [Locale('pt')],
          supported: supported,
        ),
        const Locale('pt', 'BR'),
      );
    });

    test('CA-01 en-GB → en; es-MX → es', () {
      expect(
        resolveAppLocale(
          preferred: const [Locale('en', 'GB')],
          supported: supported,
        ),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(
          preferred: const [Locale('es', 'MX')],
          supported: supported,
        ),
        const Locale('es'),
      );
    });
  });

  group('RF-02/CA-02 — primeiro preferido do sistema com tradução', () {
    test('CA-02 pula idiomas sem tradução', () {
      expect(
        resolveAppLocale(
          preferred: const [Locale('de', 'DE'), Locale('en', 'US')],
          supported: supported,
        ),
        const Locale('en'),
      );
    });
  });

  group('RF-02/CA-03 — fallback pt-BR', () {
    test('CA-03 nenhum preferido suportado', () {
      expect(
        resolveAppLocale(
          preferred: const [Locale('de'), Locale('fr', 'CA')],
          supported: supported,
        ),
        const Locale('pt', 'BR'),
      );
      expect(
        resolveAppLocale(preferred: const [], supported: supported),
        const Locale('pt', 'BR'),
      );
    });
  });

  group('RF-03/CA-04 — substituição manual', () {
    test('manual prevalece sobre a lista do sistema', () {
      expect(
        resolveAppLocale(
          preferred: const [Locale('pt', 'BR')],
          supported: supported,
          manualLocale: const Locale('en'),
        ),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(
          preferred: const [Locale('en')],
          supported: supported,
          manualLocale: const Locale('pt', 'PT'),
        ),
        const Locale('pt', 'BR'),
      );
    });

    test('manualLocaleFor mapeia os valores persistidos', () {
      expect(manualLocaleFor(localeModeSystem), isNull);
      expect(manualLocaleFor(''), isNull);
      expect(manualLocaleFor('pt-BR'), const Locale('pt', 'BR'));
      expect(manualLocaleFor('en'), const Locale('en'));
      expect(manualLocaleFor('es'), const Locale('es'));
    });
  });

  group('RF-04/CA-06 — formatação pela região do dispositivo', () {
    late DateTime moment;

    setUpAll(() async {
      await initializeDateFormatting();
      moment = DateTime(2026, 9, 24, 15, 30);
    });

    test('CA-06 datas seguem a região do dispositivo', () {
      final dispatcher = TestWidgetsFlutterBinding
          .instance.platformDispatcher;

      dispatcher.localeTestValue = const Locale('en', 'US');
      final english = formatDeviceDate(moment);

      dispatcher.localeTestValue = const Locale('es', 'MX');
      final spanish = formatDeviceDate(moment);

      expect(english, contains('2026'));
      expect(spanish, contains('2026'));
      // Formatos distintos por região: en-US "Sep 24, 2026" vs
      // es-MX "24 sep 2026" (ordem e separadores diferentes).
      expect(english, isNot(equals(spanish)));
      expect(english, contains(', 2026'));
      expect(spanish, startsWith('24 '));

      dispatcher.clearLocaleTestValue();
    });
  });
}
