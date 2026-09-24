import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('debug', (tester) async {
    await urutauWidgetTest(tester, () async {
      final ctx = tester.element(find.byType(Scaffold).first);
      debugPrint('LOCALE: ${Localizations.localeOf(ctx)}');
      debugPrint('WIDGETS-BINDING.locales: ${WidgetsBinding.instance.platformDispatcher.locales}');
      final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
      debugPrint('TEXTS: $texts');
    });
  });
}
