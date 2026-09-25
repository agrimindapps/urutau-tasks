# Registro 0006: Fatia 06 — Backup, restauração e formato aberto

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificações:** [Backup, restauração e formato aberto](../specs/07-backup-restauracao-formato-aberto.md),
  [ADR-0001](../decisoes/0001-backup-e-formato-aberto.md) e
  [ADR-0003](../decisoes/0003-criptografia-backup.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** continuidade do desenvolvimento contínuo após o gate da
  fatia 05 aprovado

## 1. Resultado obtido

- retrato lógico versionado (`format_version` 1, independente do esquema
  Drift) com todos os estados, inclusive lixeira e histórico: tarefas com
  metadados de restauração, subtarefas, listas, grupos, categorias, tags,
  associações tarefa-tag, séries e entradas do My Day (RF-01); sem visões
  calculadas, IDs de notificação ou preferências (RF-02);
- UUIDs e referências preservados (RF-03); semântica temporal preservada —
  prazos e datas do My Day como `YYYY-MM-DD`, lembretes como instantes UTC
  (RF-04);
- backup manual em arquivo único **criptografado** com senha (PBKDF2-HMAC-
  SHA256 100k iterações + AES-256-GCM, salt/nonce por arquivo — ADR-0003);
  senha não armazenada e aviso explícito de perda definitiva (RF-05/RF-06);
- exportação/importação em JSON UTF-8 legível (RF-09) com a estrutura v1
  da RF-10; exportação sempre completa (RF-11);
- validação antes de qualquer escrita (RF-13): estrutura, tipos, versão
  (mais nova é rejeitada), unicidade de IDs, integridade de referências e
  **campos desconhecidos com dados não são descartados silenciosamente**;
- resumo pré-restauração com tipo, data de exportação e contagens por estado
  (RF-14) + confirmação explícita de substituição integral (RF-15);
  restaurar/importar **substitui tudo** em transação única com rollback
  (RF-12/RF-16); qualquer falha preserva os dados locais (RF-17);
- interface em "Backup e dados" (página de Listas): exportar backup,
  exportar JSON, restaurar backup e importar JSON, com diálogo de senha
  (confirmação na criação) e avisos correspondentes.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 183 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 150 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate: igual ao registro 0001 (macOS arm64, Flutter 3.47.0,
Dart 3.13.0, Chrome 153.0.8010.53, ChromeDriver 153.0.8010.52).

## 3. Cobertura dos critérios de aceitação (spec 07)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 exportar conjunto completo | coberto | `drift_snapshot_repository_test.dart` (3 estados + todas as entidades) |
| CA-02 preservar histórico/estrutura | coberto | `drift_snapshot_repository_test.dart`, `snapshot_codec_test.dart` |
| CA-03 semântica temporal | coberto | `snapshot_codec_test.dart` (datas locais e instantes UTC intactos) |
| CA-04 backup com senha | coberto | `backup_codec_test.dart` (roundtrip) |
| CA-05 JSON legível | coberto | `data_transfer_service_test.dart` |
| CA-06 restaurar entre plataformas | coberto | formato aberto + `drift_snapshot_repository_test.dart` (banco novo) |
| CA-07 resumir antes de substituir | coberto | `data_transfer_service_test.dart` (tipo/data/contagens) |
| CA-08 cancelar sem alterar | coberto | `data_transfer_service_test.dart` |
| CA-09 substituir integralmente | coberto | `data_transfer_service_test.dart` |
| CA-10 reverter falha | coberto | `drift_snapshot_repository_test.dart` (rollback de FK no meio da troca) |
| CA-11 rejeitar senha/corrupção | coberto | `backup_codec_test.dart`, `data_transfer_service_test.dart` (dados locais intactos) |
| CA-12 rejeitar JSON inválido | coberto | `snapshot_codec_test.dart` (malformado, ID duplicado, referência, campo desconhecido) |
| CA-13 rejeitar formato incompatível | coberto | `snapshot_codec_test.dart` (`format_version` 2 rejeitado) |
| CA-14 converter versão antiga | sem efeito | não há versão anterior à v1; a arquitetura admite conversores determinísticos |

## 4. Decisões técnicas

- **Envelope JSON declarativo** (`kind`, algoritmos, iterações, salt, nonce,
  MAC, dados): arquivos interoperáveis e preparados para reforço de KDF
  futuro sem quebrar backups antigos (ADR-0003).
- **Validação estrita com tolerância a campos nulos**: um campo desconhecido
  com `null` não carrega dados e é aceito; qualquer valor real é rejeitado
  (RF-13), preservando alguma compatibilidade futura sem descarte silencioso.
- **`file_selector` em todas as plataformas**: `getSaveLocation` +
  `XFile.saveTo` (na Web, download via navegador) e `openFile` para
  restauração — mecanismo de arquivo da plataforma (RF-05), sem servidor.
- **Contagens de resumo derivadas do retrato**, não do banco: o usuário vê
  exatamente o que será importado antes de confirmar (RF-14).

## 5. Limitações e desvios

- Conversão de versões antigas do formato ficará disponível quando existir
  um `format_version` 2 (a v1 é a primeira; CA-14 sem efeito).
- Após a restauração, os agendamentos de notificação devem ser
  reconstruídos pelos adaptadores (RF-16) — implementação chega com a
  spec 08 (fatia 08); as projeções de dados já são reativamente atualizadas.
- O teste de UI cobre avisos e validação de senha; os fluxos com
  seleção de arquivo dependem do diálogo nativo e são exercitados pelos
  testes de serviço/repositório.
