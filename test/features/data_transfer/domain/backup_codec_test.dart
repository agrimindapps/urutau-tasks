import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/backup_codec.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/data_snapshot.dart';

void main() {
  const document = '{"format_version":1,"data":{}}';

  test('CA-04 — roundtrip com senha preserva o documento', () async {
    final bytes =
        await encryptBackup(documentJson: document, password: 'segredo123');
    expect(bytes.sublist(0, 4), [0x55, 0x54, 0x42, 0x4B]); // UTBK

    final clear = await decryptBackup(bytes: bytes, password: 'segredo123');
    expect(clear, document);
  });

  test('CA-04/CA-06 — aleatório por arquivo (salt e nonce únicos)', () async {
    final a = await encryptBackup(documentJson: document, password: 'x');
    final b = await encryptBackup(documentJson: document, password: 'x');
    expect(a, isNot(equals(b)));
    expect(a.sublist(5, 21), isNot(equals(b.sublist(5, 21)))); // salt
  });

  test('CA-11 — senha incorreta é rejeitada', () async {
    final bytes =
        await encryptBackup(documentJson: document, password: 'correta');
    await expectLater(
      decryptBackup(bytes: bytes, password: 'errada'),
      throwsA(isA<SnapshotException>().having(
          (e) => e.error, 'error', SnapshotError.invalidPassword)),
    );
  });

  test('CA-11 — arquivo corrompido é rejeitado', () async {
    final bytes =
        await encryptBackup(documentJson: document, password: 'senha');
    final tampered = Uint8List.fromList(bytes);
    tampered[tampered.length - 1] ^= 0xFF;
    await expectLater(
      decryptBackup(bytes: tampered, password: 'senha'),
      throwsA(isA<SnapshotException>()),
    );
  });

  test('container com magic inválido é rejeitado', () async {
    await expectLater(
      decryptBackup(
        bytes: Uint8List.fromList(List<int>.filled(64, 0)),
        password: 'senha',
      ),
      throwsA(isA<SnapshotException>().having(
          (e) => e.error, 'error', SnapshotError.corruptContainer)),
    );
  });

  test('versão de contêiner desconhecida é rejeitada (RF-08)', () async {
    final bytes =
        await encryptBackup(documentJson: document, password: 'senha');
    final newer = Uint8List.fromList(bytes);
    newer[4] = 9;
    await expectLater(
      decryptBackup(bytes: newer, password: 'senha'),
      throwsA(isA<SnapshotException>().having(
          (e) => e.error, 'error', SnapshotError.unsupportedVersion)),
    );
  });

  test('documento dentro do backup é JSON válido', () async {
    final bytes =
        await encryptBackup(documentJson: document, password: 'p');
    final clear = await decryptBackup(bytes: bytes, password: 'p');
    expect(jsonDecode(clear), isA<Map<String, dynamic>>());
  });
}
