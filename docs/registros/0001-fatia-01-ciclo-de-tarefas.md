# Registro 0001: Fatia 01 — Ciclo básico de tarefas e subtarefas

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Tarefas e subtarefas](../specs/01-tarefas-e-subtarefas.md),
  [Persistência Drift e migrações](../specs/06-persistencia-drift-e-migracoes.md),
  trechos da [internacionalização](../specs/09-internacionalizacao.md) e da
  [validação multiplataforma](../specs/10-validacao-multiplataforma.md)
- **Branch:** `Mimo-2.6-Flash`
- **Decisão humana:** aprovação do desenvolvedor para iniciar o desenvolvimento
  contínuo pela primeira fatia funcional

## 1. Resultado obtido

Primeira fatia funcional do MVP entregue:

- domínio de tarefas e subtarefas conforme spec 01 (título obrigatório, estados,
  conclusão/reabertura sem alterar subtarefas, progresso `concluídas/total`,
  reordenação, lixeira com preservação de hierarquia e restauração);
- persistência Drift com esquema v1 (`tasks`, `subtasks`), UUIDs estáveis,
  transações, FK com `PRAGMA foreign_keys = ON`, repositório com separação
  domínio/persistência (spec 06);
- camada de aplicação `TasksService` com as transições da spec 01;
- interface Material 3: lista de tarefas, criação/edição, conclusão,
  detalhe com subtarefas e progresso, lixeira com restauração, navegação
  adaptativa (NavigationBar/NavigationRail);
- i18n com `gen_l10n` em `pt-BR`, `en` e `es`, resolução por idioma-base e
  fallback `pt-BR` (RF-02 da spec 09);
- dependências: `drift`, `drift_flutter`, `flutter_riverpod`, `uuid`;
- `web/sqlite3.wasm` e `web/drift_worker.js` versionados para a execução do
  Drift na Web;
- smoke Web automatizado via `integration_test` + chromedriver
  (`integration_test/app_smoke_test.dart`, `test_driver/integration_test.dart`
  e script `tool/web-smoke.sh`).

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 43 testes |
| `flutter test --platform chrome` (domínio e aplicação) | aprovado, 23 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate:

| Item | Valor |
| --- | --- |
| Data | 2026-09-24 |
| Sistema | macOS 26.6.2, arm64 |
| Flutter | 3.47.0 stable, revisão `4cf2416426` |
| Dart | 3.13.0 |
| Chrome Stable | 153.0.8010.53 |
| ChromeDriver | 153.0.8010.52 (chrome-for-testing, `~/.local/bin/chromedriver`) |
| Evidência | smoke `integration_test/app_smoke_test.dart` aprovado: iniciar, navegar Tarefas/Lixeira, criar, editar, concluir, reabrir e persistir após reinício da árvore, sem conta ou rede |

## 3. Cobertura dos critérios de aceitação

- Spec 01: CA-01 a CA-10 cobertos por testes de domínio, serviço, persistência
  e fluxo de widget. CA-11 e CA-12 (recorrência) fora desta fatia, conforme
  [spec de prazos e recorrência](../specs/04-prazos-lembretes-e-recorrencia.md).
- Spec 06: CA-01 a CA-05, CA-13, CA-14, CA-18, CA-23 e CA-24 cobertos.
  CAs de listas, categorias, tags, My Day, prazo, lembrete e recorrência
  dependem das especificações seguintes.
- Spec 09: RF-02 e CA-01 a CA-03 cobertos na resolução automática de idioma.
  RF-03 (substituição manual persistida) fica para a fatia de preferências.
- Spec 10: gate Web completo executado (análise, testes automatizados, build
  Web e smoke automatizado no Chrome Stable cobrindo RF-01 a RF-04). A matriz
  manual das cinco plataformas não foi executada nesta rodada (não bloqueante).

## 4. Limitações, desvios e aprendizados

- Android, iOS, Linux, macOS e Windows não foram verificados nesta rodada
  (não bloqueantes); a matriz da spec 10 permanece não executada.
- Correção relevante: `Task.operator==` precisava incluir as subtarefas, sem o
  que o Riverpod ignorava atualizações de progresso no detalhe.
- Correção relevante: `Locale('pt-BR')` tem `languageCode == 'pt-BR'`; a
  resolução de locale deve usar `Locale('pt', 'BR')` ou separar por `-`/`_`.
- O import `package:drift/native.dart` é incompatível com Web; o banco em
  memória foi movido para suporte de teste.
- No Web, `driftDatabase` exige os parâmetros `web:` (`sqlite3.wasm` e
  `drift_worker.js` em `web/`), senão lança `ArgumentError` — causa de uma
  falha inicial do smoke.
- `flutter drive -d chrome` trava no fluxo atual das ferramentas; o caminho
  funcional é `-d web-server` com chromedriver na porta 4444.
- Locks órfãos de `.dart_tool/hooks_runner` de execuções interrompidas
  bloqueiam o `flutter drive`; limpar o diretório resolve.
- `PopupMenuButton` usa `Icons.adaptive.more` (`more_horiz` no macOS); o smoke
  localiza o botão por tipo, não por ícone.
- Os timers internos do Drift exigem desmontar a árvore e drenar o relógio
  ao final de cada teste de widget (orientação do próprio Drift).
- Testes de widget na Web exigem espera real (`tester.runAsync`) entre frames
  porque `pumpAndSettle` não aguarda I/O assíncrono do banco.

## 5. Intervenções humanas

- Aprovação para iniciar o desenvolvimento contínuo na branch `Mimo-2.6-Flash`.
