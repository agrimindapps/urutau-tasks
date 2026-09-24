# Registro 0006: Fatia 06 — Backup, restauração e formato aberto

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Backup, restauração e formato aberto](../specs/07-backup-restauracao-formato-aberto.md)
  e o [ADR-0003 de criptografia](../decisoes/0003-criptografia-backup.md)
- **Branch:** `Mimo-2.6-Flash`
- **Depende de:** Registros 0001–0005 e ADR-0001

## 1. Resultado obtido

Sexta fatia funcional do MVP entregue:

- **retrato lógico** (`DataSnapshot`) com as nove coleções do formato 1 —
  tarefas (3 estados), subtarefas, listas, grupos, categorias, tags,
  associações tarefa-tag, séries e entradas do My Day (RF-01);
- **formato aberto JSON v1** UTF-8 legível com `format_version`,
  `exported_at` e `data` (RF-09/RF-10), validação estrita antes de tocar
  no banco: versão, tipos, UUIDs únicos, integridade de referências e
  rejeição de campos desconhecidos (RF-13/CA-12/CA-13);
- **backup criptografado** conforme ADR-0003: contêiner `UTBK` v1 +
  PBKDF2-HMAC-SHA-256 (210k, salt de 16 bytes) + AES-256-GCM com a
  biblioteca `cryptography` (Dart puro, Web e seis plataformas);
  senha errada/corrompido rejeitada pelo tag GCM (RF-06/CA-04/CA-11);
- **semântica temporal** preservada: prazo e datas My Day como
  `YYYY-MM-DD`, lembretes como instantes UTC ISO 8601 (RF-04/CA-03);
- **substituição integral e atômica**: `replaceAll` em transação única,
  remoção e inserção na ordem das referências; falha no meio reverte
  integralmente (RF-16/CA-09/CA-10);
- **fluxo com resumo e confirmação**: contagem por tipo e estado + aviso
  de substituição antes de aplicar; cancelar não altera nada
  (RF-14/RF-15/CA-07/CA-08);
- **UI na aba Listas → seção Dados**: exportar JSON (com aviso de dados
  pessoais), importar JSON, criar backup (senha + confirmação + aviso de
  perda) e restaurar backup, com seletores de arquivo `file_selector`
  (save/open funcionam na Web e nas plataformas);
- **ADR-0003** registrado antes da implementação, conforme exigido pelo
  RF-06;
- i18n: novas chaves em `pt-BR`, `en` e `es`.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 166 testes |
| `flutter test --platform chrome` (domínio/aplicação) | aprovado, 103 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `./tool/web-smoke.sh` → `All tests passed` |

Ambiente do gate: idêntico ao
[Registro 0001](0001-fatia-01-ciclo-de-tarefas.md) — macOS 26.6.2 arm64,
Flutter 3.47.0 (`4cf2416426`), Chrome Stable 153.0.8010.53,
ChromeDriver 153.0.8010.52.

## 3. Cobertura dos critérios de aceitação

- CA-01/CA-02: roundtrip completo JSON e backup com UUIDs, relações,
  estados, posições e histórico (teste de serviço com banco populado:
  listas+grupos+categoria+tag+prazo+lembrete+recorrência com ocorrência
  gerada+My Day+lixeira).
- CA-03: prazo/My Day `YYYY-MM-DD` e lembrete UTC idênticos no roundtrip.
- CA-04/CA-05: backup com senha (roundtrip) e JSON v1 legível com aviso.
- CA-06: o mesmo retrato lógico restaura em um banco novo (mesmos UUIDs).
- CA-07/CA-08: resumo com contagens e cancelamento sem alteração
  (serviço + widget do diálogo de exportação).
- CA-09/CA-10: `replaceAll` atômico — teste com referência inexistente
  prova rollback sem dados parciais.
- CA-11: senha incorreta e bytes adulterados rejeitados sem alterar dados.
- CA-12: JSON malformado, UUID duplicado, referência inconsistente e
  campo desconhecido rejeitados.
- CA-13: `format_version` futura rejeitada sem alterar o conjunto local.
- CA-14: registro de conversores (`supportedFormatVersions` com conversão
  explícita por versão) — hoje só existe a v1; o mecanismo fica testado
  pela rejeição de versões não suportadas.

## 4. Limitações, desvios e aprendizados

- A falha no meio da substituição é simulada por violação de chave
  estrangeira (snapshot com série inexistente); a transação do Drift faz o
  rollback exigido pelo CA-10.
- `exported_at` muda a cada carga do retrato; comparações de roundtrip
  ignoram esse campo (helper `contentOf`).
- Preferência de idioma continua fora do arquivo (spec 09 RF-02) — o
  snapshot não a inclui por construção.
- Agendamento de notificações após restauração depende da spec 08
  (RF-16第二段); os dados de lembrete já são restaurados.
- `file_selector` foi escolhido por cobrir as seis plataformas e a Web
  com um único código de save/open.
- O teste de crypto com PBKDF2 200k+ iterações torna a suíte ~8 s mais
  lenta; aceitável para o gate atual.
- Padrão recorrente: comparações que incluem `exported_at` quebram entre
  duas cargas do mesmo banco — sempre comparar o conteúdo lógico.

## 5. Intervenções humanas

- Instrução para prosseguir com a spec 07 após a entrega da fatia 05.
