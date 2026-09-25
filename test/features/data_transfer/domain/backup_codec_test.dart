import 'package:flutter_test/flutter_test.dart';
import 'package:urutau_tasks/src/features/data_transfer/domain/backup_codec.dart';

void main() {
  late BackupCodec codec;

  setUp(() {
    codec = BackupCodec();
  });

  test('roundtrip preserva o conteúdo (CA-04)', () async {
    const plaintext = '{"format_version": 1, "data": {}}';
    final envelope = await codec.encrypt(
      plaintext: plaintext,
      password: 'segredo',
    );
    final clear = await codec.decrypt(envelope: envelope, password: 'segredo');
    expect(clear, plaintext);
  });

  test('senha errada falha sem revelar o conteúdo (CA-11)', () async {
    final envelope = await codec.encrypt(
      plaintext: 'conteúdo sensível',
      password: 'certa',
    );
    expect(
      () => codec.decrypt(envelope: envelope, password: 'errada'),
      throwsA(isA<BackupException>().having(
        (e) => e.failure,
        'failure',
        BackupFailure.authenticationFailed,
      )),
    );
  });

  test('adulteração do arquivo é detectada pela autenticação (CA-11)', () async {
    final envelope = await codec.encrypt(
      plaintext: 'conteúdo sensível',
      password: 'certa',
    );
    final tampered = envelope.replaceFirst('"data":"', '"data":"QQ');
    expect(
      () => codec.decrypt(envelope: tampered, password: 'certa'),
      throwsA(isA<BackupException>()),
    );
  });

  test('envelope malformado é rejeitado', () async {
    expect(
      () => codec.decrypt(envelope: 'não é json', password: 'x'),
      throwsA(isA<BackupException>()),
    );
    expect(
      () => codec.decrypt(envelope: '{"kind":"outro"}', password: 'x'),
      throwsA(isA<BackupException>().having(
        (e) => e.failure,
        'failure',
        BackupFailure.wrongEnvelope,
      )),
    );
  });

  test('arquivos iguais com senhas diferentes não coincidem (salt por arquivo)',
      () async {
    const plaintext = 'mesmo conteúdo';
    final a = await codec.encrypt(plaintext: plaintext, password: 'p1');
    final b = await codec.encrypt(plaintext: plaintext, password: 'p1');
    expect(a, isNot(b));
  });
}
