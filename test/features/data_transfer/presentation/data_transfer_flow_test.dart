import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('seção Dados oferece os quatro fluxos de portabilidade',
      (tester) async {
    await urutauWidgetTest(tester, () async {
      await tester.tap(find.text('Listas'));
      await tester.pumpAndSettle();

      expect(find.text('Dados'), findsOneWidget);
      expect(find.text('Exportar JSON'), findsOneWidget);
      expect(find.text('Importar JSON'), findsOneWidget);
      expect(find.text('Criar backup'), findsOneWidget);
      expect(find.text('Restaurar backup'), findsOneWidget);

      // RF-09: aviso de que o JSON é legível antes de exportar.
      await tester.ensureVisible(find.text('Exportar JSON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exportar JSON'));
      await tester.pumpAndSettle();

      expect(find.text('Exportar formato aberto'), findsOneWidget);
      expect(
        find.text(
          'O arquivo JSON não é criptografado e contém dados pessoais, '
          'como notas e lembretes. Deseja continuar?',
        ),
        findsOneWidget,
      );

      // CA-08 (fluxo de exportação): cancelar não prossegue.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Exportar formato aberto'), findsNothing);
    });
  });
}
