import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'data_snapshot.dart';

/// Contêiner criptografado do backup lógico (spec 07, RF-05/RF-06;
/// parâmetros do ADR-0003).
///
/// Layout: magic "UTBK" (4) | versão (1) | salt (16) | nonce (12) |
/// ciphertext || tag (GCM, 16 bytes finais).
const List<int> _magic = [0x55, 0x54, 0x42, 0x4B]; // UTBK
const int _containerVersion = 1;
const int _saltLength = 16;
const int _nonceLength = 12;
const int _headerLength = 4 + 1 + _saltLength + _nonceLength; // magic + versão

/// PBKDF2-HMAC-SHA-256 com 210k iterações (ADR-0003).
const int _pbkdf2Iterations = 210000;

final AesGcm _cipher = AesGcm.with256bits();
final Pbkdf2 _kdf = Pbkdf2.hmacSha256(iterations: _pbkdf2Iterations, bits: 256);

/// Criptografa o retrato lógico com a senha do usuário (spec 07, RF-06/CA-04).
Future<Uint8List> encryptBackup({
  required String documentJson,
  required String password,
}) async {
  final random = Random.secure();
  final salt = Uint8List.fromList(
      [for (var i = 0; i < _saltLength; i++) random.nextInt(256)]);
  final nonce = Uint8List.fromList(
      [for (var i = 0; i < _nonceLength; i++) random.nextInt(256)]);

  final key = await _kdf.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
  final box = await _cipher.encrypt(
    utf8.encode(documentJson),
    secretKey: key,
    nonce: nonce,
  );

  return Uint8List.fromList([
    ..._magic,
    _containerVersion,
    ...salt,
    ...nonce,
    ...box.cipherText,
    ...box.mac.bytes,
  ]);
}

/// Descriptografa o contêiner. Senha incorreta ou bytes corrompidos
/// falham na autenticação GCM (spec 07, RF-17/CA-11).
Future<String> decryptBackup({
  required Uint8List bytes,
  required String password,
}) async {
  if (bytes.length < _headerLength + _cipher.macAlgorithm.macLength) {
    throw const SnapshotException(SnapshotError.corruptContainer);
  }
  for (var i = 0; i < _magic.length; i++) {
    if (bytes[i] != _magic[i]) {
      throw const SnapshotException(SnapshotError.corruptContainer);
    }
  }
  if (bytes[4] != _containerVersion) {
    throw SnapshotException(
        SnapshotError.unsupportedVersion, '${bytes[4]}');
  }

  final salt = Uint8List.sublistView(bytes, 5, 5 + _saltLength);
  final nonce =
      Uint8List.sublistView(bytes, 5 + _saltLength, _headerLength);
  final payload = Uint8List.sublistView(bytes, _headerLength);
  final macLength = _cipher.macAlgorithm.macLength;
  if (payload.length < macLength) {
    throw const SnapshotException(SnapshotError.corruptContainer);
  }
  final cipherText =
      Uint8List.sublistView(payload, 0, payload.length - macLength);
  final mac = Mac(Uint8List.sublistView(payload, payload.length - macLength));

  final key = await _kdf.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
  final box = SecretBox(cipherText, nonce: nonce, mac: mac);

  try {
    final clearText = await _cipher.decrypt(box, secretKey: key);
    return utf8.decode(clearText);
  } on SecretBoxAuthenticationError {
    throw const SnapshotException(SnapshotError.invalidPassword);
  } on Exception {
    throw const SnapshotException(SnapshotError.corruptContainer);
  }
}
