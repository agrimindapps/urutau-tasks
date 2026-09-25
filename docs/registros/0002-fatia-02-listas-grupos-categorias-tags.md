# Registro 0002: Fatia 02 — Listas, grupos, categorias e tags

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificações:** [Listas, grupos, categorias e tags](../specs/02-listas-grupos-categorias-tags.md),
  [Persistência Drift e migrações](../specs/06-persistencia-drift-e-migracoes.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** continuidade do desenvolvimento contínuo após o gate da
  fatia 01 aprovado

## 1. Resultado obtido

- domínio de organização conforme spec 02: nomes não vazios após trim e
  únicos por tipo (RF-01), listas personalizadas com grupo opcional
  (RF-02/RF-04), inbox implícita por `listId` nulo (RF-03), grupos simples
  sem aninhamento (RF-04), exclusão de grupo preservando listas (RF-05),
  exclusão de lista com migração de destino (RF-06), tags com identidade
  normalizada trim + minúsculas (RF-09), ordenação manual (RF-10);
- agregado `Task` estendido com `listId`, `categoryId` única e `tagIds`
  sem duplicatas; atribuições preservam identidade, subtarefas, estados,
  ordem e notas (RF-07);
- migração Drift **v1 → v2** não destrutiva: `groups`, `task_lists`,
  `categories`, `tags`, `task_tags` + colunas `list_id`/`category_id`,
  com índices únicos por tipo e FKs (spec 06, RF-17/RF-22/RF-23);
- `DriftOrganizationRepository` com transações: remoção de categoria/tag
  desvincula sem apagar tarefas (RF-08/RF-09), exclusão de grupo limpa só a
  referência (RF-05) e `removeListMigratingTasks` migra a hierarquia e exclui
  a lista em uma única transação (RF-06; spec 06, RF-04);
- `OrganizationService` com unicidade, regras de destino de exclusão
  (destino obrigatório, distinto da origem, bloqueio sem alternativa),
  `ensureTag` idempotente para nomes equivalentes e atribuições validadas;
- interface: página "Listas" (grupos expansíveis, listas, categorias, tags),
  menus de renomear/mover/excluir, diálogo de destino na exclusão, seção de
  organização no detalhe da tarefa (seletores de lista e categoria + chips
  de tag).

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 85 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 68 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate: igual ao registro 0001 (macOS arm64, Flutter 3.47.0,
Dart 3.13.0, Chrome 153.0.8010.53, ChromeDriver 153.0.8010.52).

## 3. Cobertura dos critérios de aceitação (spec 02)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 criar lista | coberto | `organization_service_test.dart`, `lists_flow_test.dart` |
| CA-02 rejeitar nome duplicado | coberto | `organization_service_test.dart`, `lists_flow_test.dart` |
| CA-03 criar tarefa sem lista | coberto | `organization_service_test.dart` (inbox implícita) |
| CA-04 atribuir à lista | coberto | `organization_service_test.dart` |
| CA-05 mover hierarquia preservando dados | coberto | `organization_service_test.dart` (subtarefa e notas preservadas) |
| CA-06 excluir lista vazia | coberto | `organization_service_test.dart`, `lists_flow_test.dart` |
| CA-07 exigir lista destino | coberto | `organization_service_test.dart`, `lists_flow_test.dart` |
| CA-08 excluir com destino | coberto | `organization_service_test.dart`, `lists_flow_test.dart` (migração na UI) |
| CA-09 excluir grupo | coberto | `organization_service_test.dart`, `lists_flow_test.dart`, `drift_organization_repository_test.dart` |
| CA-10 criar/aplicar categoria | coberto | `organization_service_test.dart`, `lists_flow_test.dart` |
| CA-11 remover categoria | coberto | `organization_service_test.dart` (desvincula), `drift_organization_repository_test.dart` |
| CA-12 normalizar tags | coberto | `organization_test.dart`, `organization_service_test.dart`, `lists_flow_test.dart` (`' trabalho '` → `trabalho`) |
| CA-13 remover tag | coberto | `organization_service_test.dart`, `lists_flow_test.dart` |
| CA-14 preservar ordenação | coberto | `organization_service_test.dart` (posições renuméricas) |

## 4. Decisões técnicas

- **Contagem de tarefas por lista** usa a tabela `tasks` (qualquer estado,
  inclusive lixeira): a migração move tudo o que referencia a lista,
  preservando a lixeira e suas metadados.
- **Índices únicos nativos** (`ux_lists_name`, `ux_groups_name`,
  `ux_categories_name`, `ux_tags_normalized_name`) reforçam a unicidade da
  spec no próprio banco; o serviço valida antes e o banco é a garantia final.
- **Fakes de teste compartilham o armazenamento de tarefas**
  (`InMemoryOrganizationRepository` recebe o `InMemoryTaskRepository`),
  espelhando o compartilhamento de banco entre repositórios Drift.
- **Teste de migração v1 → v2** cria o esquema v1 com SQL direto em arquivo
  temporário (`PRAGMA user_version = 1`) e reabre com `AppDatabase`,
  verificando preservação de dados e operação das tabelas novas.

## 5. Limitações e desvios

- Reordenação por menu (Subir/Descer) em vez de arrastar; o requisito de
  ordem manual preservada (RF-10) está coberto, o gesto de arrastar pode
  ser adicionado sem mudar domínio.
- Subtarefas nunca recebem lista/categoria/tags (regra de consistência da
  spec 02) — garantido pela estrutura do agregado e coberto por testes de
  domínio da fatia 01.
- Busca e filtros por lista/grupo/categoria/tags (spec 05) chegam na fatia 05.
