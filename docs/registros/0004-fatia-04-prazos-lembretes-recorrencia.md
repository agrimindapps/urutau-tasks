# Registro 0004: Fatia 04 — Prazos, lembretes e recorrência

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Prazos, lembretes e recorrência](../specs/04-prazos-lembretes-e-recorrencia.md)
  e os CAs pendentes da [spec 01](../specs/01-tarefas-e-subtarefas.md)
  (CA-11/CA-12 de recorrência)
- **Branch:** `Mimo-2.6-Flash`
- **Depende de:** Registros 0001–0003

## 1. Resultado obtido

Quarta fatia funcional do MVP entregue:

- prazo: criação/edição/remoção com datas passadas válidas (atrasadas),
  calendário local sem conversão UTC (RF-01/RF-02, CA-01/CA-02);
- lembrete: configuração independente do prazo, relação antes/depois
  aceita, **rejeição de horário passado** na criação/alteração (RF-03/RF-04,
  CA-03 a CA-05); lembretes vencidos já registrados permanecem e não
  bloqueiam outras edições (CA-08);
- conclusão/reabertura preservam a configuração do lembrete (RF-05);
  cancelamento de notificação e reagendamento dependem da spec 08;
- recorrência: séries com frequências fixas **diária, dias úteis, semanal,
  mensal, anual** (RF-07/RF-08, CA-09), cálculo de calendário com clamp
  mensal e 29/02 → 28/02 (RF-09, CA-10), pré-condição de prazo
  (RF-07, CA-18);
- conclusão de ocorrência: histórico intacto, próxima data futura única
  (sem retroativas em lote — RF-11/CA-11/CA-15), sem cópia de subtarefas
  (CA-12, completa a spec 01 CA-11), herança de lembrete com offset
  recalculado e expiração respeitada (RF-13/CA-13), regra editável a
  partir da ocorrência atual sem reescrever histórico (RF-12/CA-16),
  cancelamento manual (RF-10/CA-17);
- esquema v4: tabela `series` + coluna `tasks.series_id`
  (migração v3→v4 não destrutiva);
- interface: seletor de repetição no diálogo de edição com avisos
  traduzidos (prazo obrigatório, lembrete passado);
- i18n: novas chaves em `pt-BR`, `en` e `es`.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 118 testes |
| `flutter test --platform chrome` (domínio/aplicação) | aprovado, 82 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `./tool/web-smoke.sh` → `All tests passed` |

Ambiente do gate: idêntico ao
[Registro 0001](0001-fatia-01-ciclo-de-tarefas.md) — macOS 26.6.2 arm64,
Flutter 3.47.0 (`4cf2416426`), Chrome Stable 153.0.8010.53,
ChromeDriver 153.0.8010.52.

## 3. Cobertura dos critérios de aceitação

- CA-01, CA-02 (prazo): serviço + widget de edição.
- CA-03, CA-04 (lembrete independente/relacionado): serviço.
- CA-05 (lembrete passado rejeitado): serviço.
- CA-06, CA-07 (cancelar/reagendar notificação): **dependem da spec 08**;
  a preservação da configuração em conclusão/reabertura está coberta
  (teste RF-05).
- CA-08 (lembrete vencido ao reabrir): configuração preservada sem alerta
  imediato (sem notificador existe ainda — spec 08).
- CA-09 a CA-18 (recorrência): domínio, serviço, Drift e widget — todos
  cobertos, incluindo CA-10 (clamp mensal/anual), CA-11 a CA-16 (ciclo de
  ocorrências) e CA-17/CA-18 (cancelamento/prazo obrigatório).
- Spec 01 CA-11 e CA-12 (ocorrência recorrente sem cópia de subtarefas):
  cobertos.

## 4. Limitações, desvios e aprendizados

- Entrega de notificação (agendar/cancelar no sistema) ficou integralmente
  para a spec 08; esta fatia cobre os dados e as regras de negócio.
- Decisão: ao editar prazo/regra, a âncora da série passa a ser o prazo
  atual da ocorrência (“a partir da ocorrência atual”, RF-12); ocorrências
  históricas não são reescritas.
- Decisão: lembrete herdado é um offset de relógio local sobre o novo
  prazo; resultado no passado é mantido como vencido (RF-13).
- RF-04 valida apenas alterações do valor do lembrete — um lembrete já
  vencido não bloqueia edições de outros campos (CA-08).
- `customConstraint` em coluna com `CHECK` substitui `NOT NULL` no DDL do
  Drift; a coluna `frequency` aceita isso porque o serviço só grava valores
  válidos, mas `priority` precisou do `withDefault` (registro 0003).
- Testes de widget precisam de `ensureVisible` nos campos do diálogo de
  edição, que cresceu com prazo, lembrete e repetição.
- O teste de widget de recorrência confirma o comportamento esperado: ao
  concluir, a nova ocorrência ocupa o lugar em Todas imediatamente.

## 5. Intervenções humanas

- Instrução para prosseguir com a spec 04 após a entrega da fatia 03.
