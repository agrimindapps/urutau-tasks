# Registro 0001: Fatia 01 — Ciclo básico de tarefas e subtarefas

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificações:** [Tarefas e subtarefas](../specs/01-tarefas-e-subtarefas.md),
  [Persistência Drift e migrações](../specs/06-persistencia-drift-e-migracoes.md),
  trechos da [internacionalização](../specs/09-internacionalizacao.md) e da
  [validação multiplataforma](../specs/10-validacao-multiplataforma.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** aprovação do desenvolvedor para iniciar o desenvolvimento
  contínuo pela primeira fatia funcional, em branch nova por causa do benchmark
  de capacidade de entrega entre modelos (trabalho anterior em `Mimo-2.6-Flash`
  preservado como referência)

## 1. Resultado obtido

Primeira fatia funcional do MVP entregue:

- domínio de tarefas e subtarefas conforme spec 01 (título obrigatório não vazio
  após trim, estados Ativa/Concluída/Lixeira com tabela de transições,
  conclusão/reabertura sem alterar subtarefas, progresso `concluídas/total` sem
  progresso artificial, reordenação, remoção física individual de etapa,
  lixeira com preservação de hierarquia e restauração fiel do estado anterior);
- persistência Drift com esquema v1 (`tasks`, `subtasks`), UUIDs estáveis
  gerados no domínio, transações para escritas compostas, FK com
  `PRAGMA foreign_keys = ON`, separação domínio/persistência via porta
  `TaskRepository` (spec 06);
- camada de aplicação `TasksService` com as transições da spec 01 e relógio
  injetável para testes determinísticos;
- interface Material 3 adaptativa (NavigationBar/NavigationRail): lista com
  ativas e concluídas, criação/edição com validação de título, detalhe com
  etapas (adicionar, concluir, renomear, remover, reordenar) e progresso,
  lixeira com restauração, confirmação de exclusão;
- i18n com `gen_l10n` em `pt-BR`, `en` e `es`, resolução por idioma-base,
  fallback `pt-BR` e preferidos do sistema (RF-01/RF-02 da spec 09);
- dependências mínimas justificadas: `drift`, `drift_flutter`,
  `flutter_riverpod`, `uuid` (+ `intl`/`flutter_localizations` para i18n);
- `web/sqlite3.wasm` (release oficial `drift-2.35.0`) e `web/drift_worker.js`
  (compilado da fonte do pacote com `dart compile js -O4`) versionados para o
  Drift na Web;
- smoke Web automatizado via `integration_test` + chromedriver
  (`integration_test/app_smoke_test.dart`, `test_driver/integration_test.dart`
  e script `tool/web-smoke.sh`), cobrindo spec 10 RF-01 a RF-04.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 46 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 37 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate:

| Item | Valor |
| --- | --- |
| Data | 2026-09-25 |
| Sistema | macOS, arm64 |
| Flutter | 3.47.0 stable, revisão `4cf2416426` |
| Dart | 3.13.0 |
| Chrome Stable | 153.0.8010.53 |
| ChromeDriver | 153.0.8010.52 (chrome-for-testing, `~/.local/bin/chromedriver`) |
| Evidência | smoke `integration_test/app_smoke_test.dart` aprovado: iniciar, navegar Tarefas/Lixeira, criar, editar, concluir, reabrir, etapas com progresso e persistir após reinício da árvore, sem conta ou rede |

Observação: os testes do repositório Drift usam `NativeDatabase.memory()`
(`dart:ffi`) e são marcados com `@TestOn('!browser')`; na Chrome a cobertura é
de domínio, aplicação, apresentação e resolução de locale, com o acesso real ao
banco exercitado pelo smoke Web.

## 3. Cobertura dos critérios de aceitação (spec 01)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 criar tarefa válida | coberto | `task_test.dart`, `tasks_service_test.dart`, `tasks_flow_test.dart`, smoke |
| CA-02 rejeitar título inválido | coberto | `task_test.dart`, `tasks_flow_test.dart` (erro exibido no formulário) |
| CA-03 gerenciar subtarefas | coberto | `task_test.dart`, `tasks_service_test.dart`, `tasks_flow_test.dart` (adicionar, renomear, concluir, remover) |
| CA-04 reordenar subtarefas | coberto | `task_test.dart`, `tasks_service_test.dart` |
| CA-05 remover subtarefa | coberto | `task_test.dart`, `drift_task_repository_test.dart`, `tasks_flow_test.dart` |
| CA-06 progresso `2/5` | coberto | `task_test.dart` (2 de 5), `tasks_flow_test.dart` (0 de 2 / 1 de 2) |
| CA-07 concluir com pendências | coberto | `task_test.dart` |
| CA-08 preservar estados ao reabrir | coberto | `task_test.dart` |
| CA-09 mover hierarquia à lixeira | coberto | `task_test.dart`, `drift_task_repository_test.dart`, `tasks_flow_test.dart` |
| CA-10 restaurar hierarquia | coberto | `task_test.dart`, `drift_task_repository_test.dart`, `tasks_flow_test.dart` |
| CA-11/CA-12 ocorrência recorrente | fora do escopo da fatia | depende da spec 04 (fatia 04) |

## 4. Decisões técnicas

- **Porta de persistência única `saveTask`:** upsert atômico da tarefa e do
  conjunto de subtarefas; cobre criação, edição, lixeira, restauração e
  reordenação em uma transação (spec 06, RF-04/RF-21).
- **Nomes `TaskRow`/`SubtaskRow` via `@DataClassName`:** evita colisão com os
  modelos de domínio `Task`/`Subtask` (spec 06, RF-20).
- **Worker do drift compilado da fonte** (`web/drift_worker.dart` +
  `dart compile js -O4`) em vez de artefato pré-compilado, mantendo o
  pareamento com a versão fixada em `pubspec.lock`; `sqlite3.wasm` obtido do
  release oficial `drift-2.35.0` (documentação do drift, seção Web).
- **Chaves estáveis em campos de formulário** (`task-title-field`,
  `task-notes-field`, `subtask-field`, `subtask-title-field`): os testes de
  widget e de smoke identificam campos com segurança mesmo com múltiplos
  `TextField` na árvore.
- **Diálogos como `StatefulWidget`:** o `TextEditingController` pertence ao
  ciclo de vida do diálogo; uma versão anterior que criava o controller fora
  do widget o dispunha antes do fim da animação de saída, causando
  "A TextEditingController was used after being disposed".

## 5. Limitações e desvios

- Testes de repositório Drift executados apenas na VM (marcados com
  `@TestOn('!browser')`, pois `NativeDatabase.memory` depende de `dart:ffi`);
  o smoke Web cobre o caminho real do banco na Web (IndexedDB/OPFS do drift).
- Recorrência (RF-11 da spec 01) só será entregue com a spec 04; a spec 01
  a define como dependência posterior.
