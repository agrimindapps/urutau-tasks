# ADR-0003: Biblioteca e algoritmos do backup criptografado

- **Data:** 2026-09-25
- **Status:** aceito
- **Contexto:** [ADR-0001](0001-backup-e-formato-aberto.md) decidiu que o
  backup é um arquivo único criptografado com senha do usuário, com
  **proteção autenticada**, e deixou biblioteca/algoritmos/parâmetros para
  decisão técnica anterior à implementação (fatia 06). A
  [spec 07](../specs/07-backup-restauracao-formato-aberto.md) exige que a
  senha não seja armazenada, que sua perda torne o backup inacessível e que
  falhas de autenticação preservem os dados locais (RF-06/RF-17).

## Decisão

Usar o pacote Dart **`cryptography`** (mantido, multiplataforma, inclui Web)
com:

- **PBKDF2-HMAC-SHA256**, 100.000 iterações, saída de 256 bits, com **salt
  aleatório de 16 bytes por arquivo**;
- **AES-256-GCM** como cifra autenticada, com **nonce aleatório por arquivo**;
- envelope JSON público com `kind`, algoritmos, salt, nonce, MAC e o texto
  cifrado em base64 — o conteúdo claro é o retrato lógico v1 do ADR-0001.

## Alternativas consideradas

- **`encrypt` + AES-CBC/HMAC manual:** composição manual de autenticação é
  propensa a erros; GCM já entrega sigilo e integridade juntos.
- **ChaCha20-Poly1305 (também no `cryptography`):** igualmente adequada;
  AES-GCM tem suporte nativo mais amplo (WebCrypto) caso o pacote venha a
  usar implementações nativas no futuro.
- **Criptografar o SQLite em disco:** contraria o ADR-0001, que prefere o
  retrato lógico independente do esquema.

## Consequências

- Mesmo algoritmo em todas as plataformas; o modo puro-Dart do pacote
  funciona na Web sem servidor.
- Arquivos são interoperáveis entre instalações e sistemas (o envelope
  declara algoritmos e parâmetros).
- Senha perdida = backup inacessível, como já avisado na interface;
  não há recuperação por conta ou servidor.
- Reforço de senha (número de iterações) pode subir em versões futuras do
  envelope sem quebrar arquivos antigos (o envelope registra as iterações).
