# ADR-0003: Implementação de backup e portabilidade

- **Status:** aceito
- **Data:** 2026-09-24
- **Especificações relacionadas:** [Backup, restauração e formato aberto](../specs/07-backup-restauracao-formato-aberto.md), [Persistência Drift e migrações](../specs/06-persistencia-drift-e-migracoes.md)

## Contexto

O MVP precisa exportar e importar o retrato lógico completo em seis plataformas,
oferecendo JSON legível e backup protegido por senha. O fluxo precisa manter a
mesma implementação de formatos no Android, iOS, Web, Linux, macOS e Windows,
sem armazenar a senha nem copiar fisicamente o arquivo SQLite.

O ADR-0001 já definiu os dois formatos e a substituição integral. Esta decisão
fecha a escolha técnica que a especificação 07 exige antes de implementar a
criptografia e o acesso a arquivos.

## Decisão

- Usar `cryptography` para criptografia e derivação de chave em todas as
  plataformas. A versão adotada na implementação inicial será `^2.9.0`; a
  atualização futura exige manter compatibilidade com o envelope versionado.
- Gerar a chave AES de 256 bits com Argon2id usando salt aleatório de 16 bytes,
  memória de 19.456 blocos de 1 KiB, duas iterações, paralelismo 1 e saída de
  32 bytes. Esses parâmetros atendem ao patamar mínimo indicado pela OWASP.
- Criptografar o retrato lógico com AES-256-GCM, nonce aleatório de 12 bytes e
  tag de autenticação de 16 bytes. Algoritmo, parâmetros e versão do envelope
  serão autenticados como dados associados; qualquer alteração deverá fazer a
  autenticação falhar.
- Usar um envelope JSON UTF-8 com `container_version`, parâmetros do KDF,
  salt, nonce, ciphertext e tag codificados em Base64. O texto descriptografado
  continuará usando seu próprio `format_version` lógico, independente da
  versão do envelope e do esquema Drift.
- Usar a mesma representação lógica versionada dentro do backup e no JSON
  aberto. O backup criptografa essa representação; a exportação aberta grava
  diretamente o JSON UTF-8 legível.
- Usar `file_picker` para escolher arquivos de importação e destinos de
  exportação. O plugin oferece seleção e gravação de bytes nas seis
  plataformas e será incluído como `^13.1.0` na implementação inicial.
- Excluir a tabela `app_settings` e quaisquer tabelas futuras de estado de
  notificações dos arquivos de portabilidade. Preferências de idioma e IDs do
  sistema operacional não pertencem ao retrato lógico.
- Não incluir `cryptography_flutter` inicialmente. A implementação comum será
  mantida em Dart/WebCrypto; aceleração nativa poderá ser considerada depois
  de medições em dispositivos representativos, sem alterar o formato do
  arquivo.

## Alternativas consideradas

### Cifrar o banco SQLite diretamente

Rejeitada porque acoplaria arquivos de usuário ao esquema físico e dificultaria
validar UUIDs, referências e versões antes de substituir os dados locais.

### Usar criptografia sem autenticação

Rejeitada porque um arquivo alterado poderia produzir conteúdo adulterado sem
detecção confiável. AES-GCM valida os dados ao mesmo tempo em que os protege.

### Usar o seletor oficial `file_selector` e um pacote separado para salvar

Rejeitada para o primeiro corte porque o MVP precisa escolher arquivos e
escrever bytes nos seis alvos. `file_picker` oferece essas operações no mesmo
contrato multiplataforma e suporta compilação WebAssembly.

### Guardar a senha ou derivar a chave uma vez para reutilizar

Rejeitada. A senha será solicitada em cada operação, usada apenas em memória
durante o fluxo e descartada ao terminar. O arquivo carrega salt e parâmetros
necessários para derivar a mesma chave na restauração.

## Consequências

- Senha incorreta, arquivo corrompido e metadados alterados serão detectados
  pela autenticação antes da validação/importação.
- A camada lógica ainda terá de validar versão, estrutura, unicidade de UUIDs e
  referências antes de qualquer gravação.
- A troca dos registros seguirá em uma transação Drift e excluirá/substituirá
  somente tabelas do retrato lógico, preservando `app_settings` e as tabelas
  locais de infraestrutura.
- O envelope deverá armazenar seus parâmetros para que mudanças futuras possam
  derivar chaves antigas sem adivinhar valores.
- O custo de Argon2id varia por hardware. A implementação deverá executar a
  derivação fora da interação de digitação e apresentar estado de progresso.

## Referências técnicas

- [`cryptography` e Argon2id](https://pub.dev/documentation/cryptography/latest/cryptography/Argon2id-class.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [`file_picker`](https://pub.dev/packages/file_picker)
- [AES-GCM na API `cryptography`](https://pub.dev/documentation/cryptography/latest/cryptography/AesGcm-class.html)
