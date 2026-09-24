# Registro 0002: Fatia 02 — Listas, grupos, categorias e tags

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Listas, grupos, categorias e tags](../specs/02-listas-grupos-categorias-tags.md),
  complementos da [persistência Drift e migrações](../specs/06-persistencia-drift-e-migracoes.md)
- **Branch:** `Mimo-2.6-Flash`
- **Depende de:** [Registro 0001](0001-fatia-01-ciclo-de-tarefas.md)

## 1. Resultado obtido

Segunda fatia funcional do MVP entregue:

- domínio de `TaskList`, `Group`, `Category` e `Tag` com nomes validados,
  unicidade sem diferenciação de maiúsculas e reordenação determinística
  (spec 02, RF-01/RF-10);
- migração do esquema v1 → v2: tabelas `groups`, `task_lists`, `categories`,
  `tags`, `task_tags` e colunas `tasks.list_id`/`tasks.category_id`,
  não destrutiva e atômica (spec 06, RF-22 a RF-24);
- regras de listas: criação, renomeação, movimentação entre grupos, exclusão
  vazia direta e exclusão com tarefas exigindo destino (RF-02/RF-06);
- grupos: CRUD, exclusão preservando listas (RF-04/RF-05);
- categorias: globais, no máximo uma por tarefa, exclusão apenas desvincula
  (RF-08);
- tags: globais, normalização sem distinção de maiúsculas, exclusão apenas
  desvincula (RF-09);
- movimentação de tarefas preservando hierarquia, estados, categoria e tags
  (RF-07);
- inbox implícita: tarefas sem lista com filtro dedicado “Sem lista”
  (RF-03/CA-03/CA-04);
- interface: aba “Listas” com seções de listas, grupos, categorias e tags
  (criar/renomear/reordenar/excluir), edição de tarefa com seleção de lista,
  categoria e tags, nome da lista no tile e chips de filtro na visão de
  tarefas;
- i18n: novas chaves em `pt-BR`, `en` e `es`.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 66 testes |
| `flutter test --platform chrome` (domínio, aplicação) | aprovado, 39 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `./tool/web-smoke.sh` → `All tests passed` |

Ambiente do gate: idêntico ao
[Registro 0001](0001-fatia-01-ciclo-de-tarefas.md) — macOS 26.6.2 arm64,
Flutter 3.47.0 (`4cf2416426`), Chrome Stable 153.0.8010.53,
ChromeDriver 153.0.8010.52.

## 3. Cobertura dos critérios de aceitação

- CA-01, CA-02 (criação/unicidade de listas): domínio, serviço e widget.
- CA-03, CA-04 (inbox e atribuição): serviço e widget com filtro “Sem lista”.
- CA-05 (mover hierarquia): serviço, com preservação de subtarefas, categoria
  e tags.
- CA-06, CA-07, CA-08 (exclusão de lista): serviço, com destino obrigatório e
  bloqueio sem outra lista.
- CA-09 (exclusão de grupo): serviço e Drift.
- CA-10, CA-11 (categorias): serviço e Drift (desvinculação).
- CA-12, CA-13 (tags): serviço e Drift (normalização e desvinculação).
- CA-14 (ordem manual): serviço com renumeração determinística.
- Spec 06 CA-19 (dados preservados na migração) e CA-20 (atomicidade via
  transação de exclusão de lista): teste com esquema v1 gravado por SQL puro
  e `user_version = 1`.

## 4. Limitações, desvios e aprendizados

- A ordenação exibida nas seções de categorias/tags é alfabética; a spec só
  exige ordem manual para listas e grupos (RF-10).
- O Drift não expõe colation na DSL de tabelas; a unicidade NOCASE foi
  aplicada via `customConstraint` no DDL, com validação equivalente no
  serviço (dupla proteção).
- Na migração de teste é preciso gravar `PRAGMA user_version = 1` no
  esquema v1: sem isso o Drift trata a base como criação (`onCreate`) e não
  executa o `onUpgrade`.
- O companion de atualização do repositório de tarefas precisava incluir
  `listId`/`categoryId`; a primeira versão só os gravava na inserção.
- `tester.pageBack()` procura o tooltip `'Back'` fixo em inglês e falha com
  interface em `pt-BR`; o teste usa `find.byType(BackButton)`.
- `DropdownButtonFormField.value` está obsoleto em favor de `initialValue`,
  que também reage a mudanças via `didUpdateWidget`.

## 5. Intervenções humanas

- Instrução para prosseguir com a próxima fatia após a revisão do status.
