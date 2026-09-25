import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('aplicativo inicia na aba de tarefas', (tester) async {
    await urutauWidgetTest(tester, () async {
      expect(find.text('Tarefas'), findsWidgets);
    });
  });
}
