import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Falhas do envelope de backup criptografado (spec 07, RF-06/RF-17).
enum BackupFailure {
  /// Senha incorreta ou arquivo corrompido/tamperizado.
  authenticationFailed,

  /// Estrutura do envelope inválida.
  wrongEnvelope,
}

class BackupException implements Exception {
  const BackupException(this.failure);

  final BackupFailure failure;

  @override
  String toString() => 'BackupException(${failure.name})';
}

/// Backup criptografado com senha (ADR-0003).
///
/// AES-256-GCM (proteção autenticada) com chave derivada por
/// PBKDF2-HMAC-SHA256; salt e nonce aleatórios por arquivo. A senha não é
/// armazenada — perdê-la torna o backup inacessível (spec 07, RF-06).
class BackupCodec {
  BackupCodec({AesGcm? cipher, Pbkdf2? kdf})
      : _cipher = cipher ?? AesGcm.with256bits(),
        _kdf = kdf ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: 100000,
              bits: 256,
            );

  final AesGcm _cipher;
  final Pbkdf2 _kdf;

  static const String _kind = 'urutau-tasks-backup';

  /// Gera o arquivo único de backup a partir do conteúdo claro.
  Future<String> encrypt({
    required String plaintext,
    required String password,
  }) async {
    final salt = SecretKeyData.random(length: 16).bytes;
    final secretKey = await _derive(password: password, salt: salt);
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: _cipher.newNonce(),
    );
    return jsonEncode({
      'kind': _kind,
      'cipher': 'aes-256-gcm',
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': _kdf.iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
      'data': base64Encode(secretBox.cipherText),
    });
  }

  /// Recupera o conteúdo claro; senha errada ou adulteração falham sem
  /// vazar dados (spec 07, RF-17).
  Future<String> decrypt({
    required String envelope,
    required String password,
  }) async {
    Object? root;
    try {
      root = jsonDecode(envelope);
    } on FormatException {
      throw const BackupException(BackupFailure.wrongEnvelope);
    }
    if (root is! Map<String, Object?> || root['kind'] != _kind) {
      throw const BackupException(BackupFailure.wrongEnvelope);
    }

    try {
      final salt = base64Decode(root['salt']! as String);
      final nonce = base64Decode(root['nonce']! as String);
      final mac = base64Decode(root['mac']! as String);
      final data = base64Decode(root['data']! as String);

      final secretKey = await _derive(password: password, salt: salt);
      final clear = await _cipher.decrypt(
        SecretBox(data, nonce: nonce, mac: Mac(mac)),
        secretKey: secretKey,
      );
      return utf8.decode(clear);
    } catch (_) {
      // Authenticação do GCM: senha errada, corrupção ou adulteração.
      throw const BackupException(BackupFailure.authenticationFailed);
    }
  }

  Future<SecretKey> _derive({
    required String password,
    required List<int> salt,
  }) {
    return _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }
}
