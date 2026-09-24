# ADR-0003: Criptografia do backup com senha

- **Status:** aceito
- **Data:** 2026-09-24
- **Especificação relacionada:** [Backup, restauração e formato aberto](../specs/07-backup-restauracao-formato-aberto.md) (RF-06)
- **ADR base:** [ADR-0001](0001-backup-e-formato-aberto.md)

## Contexto

O ADR-0001 definiu backup completo em arquivo único protegido por senha,
com criptografia autenticada, biblioteca mantida e sem dependência de
serviços externos, mas adiou a escolha da biblioteca e dos parâmetros para
uma decisão técnica anterior à implementação (RF-06 da spec 07). O gate
Web é bloqueante, portanto a solução precisa funcionar em Dart puro na
Web e nas seis plataformas.

## Decisão

- **Biblioteca:** [`cryptography`](https://pub.dev/packages/cryptography)
  2.9.0 — Dart puro, sem `dart:ffi`, mantida, cobre Web e todas as
  plataformas do MVP com o mesmo código.
- **Encriptação:** AES-GCM de 256 bits (`AesGcm.with256bits()`), proteção
  autenticada (AEAD): o _tag_ de autenticação rejeita senha errada ou
  arquivo corrompido (CA-11).
- **Derivação de chave (KDF):** PBKDF2-HMAC-SHA-256 com 210.000 iterações
  (recomendação atual do OWASP para PBKDF2-SHA256), _salt_ aleatório de
  16 bytes por arquivo, chave de 32 bytes.
- **Nonce:** 12 bytes aleatórios por arquivo (nunca reutilizado com a
  mesma chave).
- **Formato do contêiner:**

  ```
  offset  tamanho  campo
  0       4        magic "UTBK"
  4       1        versão do contêiner (1)
  5       16       salt (PBKDF2)
  21      12       nonce (AES-GCM)
  23      rest     ciphertext || tag (16 bytes finais)
  ```

  O texto claro é o mesmo documento JSON versionado do retrato lógico
  (`format_version`, `exported_at`, `data`).

- A senha não é armazenada nem derivada de dados do dispositivo; a perda
  da senha torna o arquivo inacessível (limitação informada na UI, RF-06).

## Alternativas consideradas

### cryptography_flutter / APIs nativas do sistema

Rejeitada por não cobrir a Web de forma uniforme e por acoplar o formato
a adaptadores por plataforma; a spec exige restauração entre plataformas
(CA-06) com o mesmo arquivo.

### ChaCha20-Poly1305

Rejeitada nesta versão: AES-GCM é amplamente disponível, auditable e
suficiente para o caso; o formato versionado permite trocar o algoritmo
em uma versão futura do contêiner sem quebrar arquivos antigos.

### PointyCastle / encrypt

Rejeitada: `encrypt` expõe modos sem autenticação por padrão (CBC) e tem
manutenção menos ativa; PointyCastle é enorme e orientada a baixo nível,
com superfície de erro maior para um único uso.

### Scrypt/Argon2 como KDF

Adiado: PBKDF2 com 210k iterações atende ao requisito de senha de
arquivo com a biblioteca escolhida; a versão do contêiner permite
migrar para Argon2id em versão futura do formato (os parâmetros ficam
definidos aqui para reavaliação em ADR específico).

## Consequências

- Arquivos de backup antigos continuam legíveis enquanto a versão 1 do
  contêiner for suportada; uma troca de algoritmo exige contêiner v2.
- PBKDF2 é mais lento que Argon2id em CPUs modernas — aceitável para
  operação manual e pontual (RF-05: sem backup automático).
- A validade da senha depende do _tag_ GCM: senha errada e corrupção
  produzem a mesma rejeição segura, sem distinguir causas ao usuário.
