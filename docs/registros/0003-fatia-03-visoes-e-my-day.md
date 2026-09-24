# Registro 0003: Fatia 03 — Visões inteligentes e My Day

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Visões inteligentes e My Day](../specs/03-visoes-inteligentes-e-my-day.md),
  complementos da [persistência](../specs/06-persistencia-drift-e-migracoes.md)
  e campos de dados de [prioridade/prazo/lembrete](../04-escopo-do-mvp.md)
  (recorrência e notificações permanecem na spec 04)
- **Branch:** `Mimo-2.6-Flash`
- **Depende de:** Registros [0001](0001-fatia-01-ciclo-de-tarefas.md) e
  [0002](0002-fatia-02-listas-grupos-categorias-tags.md)

## 1. Resultado obtido

Terceira fatia funcional do MVP entregue:

- visões derivadas **Todas**, **Importante**, **Planejado** e **Concluídas**
  como projeções sem cópia (RF-01 a RF-05, CA-01 a CA-08);
- ordenação padrão por atraso → hoje → futuro → prioridade → origem
  (RF-11) e ordem própria de Concluídas (mais recentes primeiro);
- campos de dados mínimos das visões: prioridade (`low/medium/high/urgent`,
  escopo MVP 3.3), prazo como data `yyyy-MM-dd` (spec 06, RF-11) e lembrete
  como instante UTC (spec 06, RF-12) — sem recorrência nem agendamento de
  notificações, que ficam para a spec 04;
- **My Day**: entradas por data local com unicidade tarefa+data (índice
  único), adicionar/remover/reordenar (RF-06 a RF-08), conclusão e lixeira
  removem o foco (RF-05/RF-09), rollover idempotente na abertura, ao voltar
  ao primeiro plano e à meia-noite local (RF-10, CA-14/CA-15);
- esquema v3: tabela `my_day_entries` + colunas `priority`, `due_date`,
  `reminder` (migração não destrutiva);
- interface: shell com My Day, Tarefas, Listas e Lixeira; seletor de visões
  por chips na aba Tarefas; página do My Day com reordenação e adição de
  tarefas existentes; edição de tarefa com prioridade, prazo e lembrete;
- i18n: novas chaves em `pt-BR`, `en` e `es`.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 88 testes |
| `flutter test --platform chrome` (domínio/aplicação) | aprovado, 55 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `./tool/web-smoke.sh` → `All tests passed` |

Ambiente do gate: idêntico ao
[Registro 0001](0001-fatia-01-ciclo-de-tarefas.md) — macOS 26.6.2 arm64,
Flutter 3.47.0 (`4cf2416426`), Chrome Stable 153.0.8010.53,
ChromeDriver 153.0.8010.52.

## 3. Cobertura dos critérios de aceitação

- CA-01, CA-02: visão Todas com tarefas sem lista (domínio + widget).
- CA-03: Importante apenas alta/urgente ativas.
- CA-04, CA-05: Planejado com prazo OU lembrete, uma única vez, incluindo
  atrasadas.
- CA-06: mesma instância de tarefa referenciada por várias visões.
- CA-07, CA-08: concluídas e lixeira fora das visões de trabalho.
- CA-09, CA-10: My Day sem alterar dados de origem (prazo preservado).
- CA-11: reordenação manual persistida.
- CA-12: remoção do My Day mantém a origem.
- CA-13: conclusão no My Day sai do foco e preserva subtarefas.
- CA-14, CA-15: rollover idempotente; inbox sem lista automática
  (coberto por serviço + Drift; o disparo na meia-noite cobre sessões
  ativas, e a abertura do app cobre sessões frias).
- CA-16: apenas tarefas principais nas listas de visão (subtarefas ficam
  no detalhe).

## 4. Limitações, desvios e aprendizados

- Prioridade, prazo e lembrete entraram como **campos de dados** para
  atender RF-02/RF-03/RF-11; a UI básica de edição foi incluída, mas
  comportamentos avançados (recorrência, notificações, regras de prazo) seguem
  a spec 04.
- A coluna `priority` usava `customConstraint`, que no Drift substitui
  `NOT NULL/DEFAULT` no DDL e quebrava a migração (linhas antigas ficavam com
  NULL); corrigido para `withDefault` padrão.
- `customConstraint` deve ser usado só quando se quer substituir toda a
  cláusula de restrição da coluna.
- A shell passou a abrir no My Day (foco do dia, promessa do MVP); testes de
  fluxo agora navegam para Tarefas no início.
- Ícone adaptativo do menu do tile varia por plataforma (`more_vert` no
  alvo de teste VM, `more_horiz` no macOS/Web); testes localizam por tipo.
- `tester.pageBack()` continua inutilizável com locale `pt-BR` (tooltip fixo
  em inglês), já registrado no Registro 0002.

## 5. Intervenções humanas

- Instrução para prosseguir com a spec 03 após a entrega da fatia 02.
