# Registro 0003: Fatia 03 — Visões inteligentes e My Day

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificações:** [Visões inteligentes e My Day](../specs/03-visoes-inteligentes-e-my-day.md),
  [Persistência Drift e migrações](../specs/06-persistencia-drift-e-migracoes.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** continuidade do desenvolvimento contínuo após o gate da
  fatia 02 aprovado

## 1. Resultado obtido

- visões inteligentes como projeções sem duplicação (RF-01 a RF-04):
  Todas (somente ativas), Importante (alta/urgente), Planejado (prazo ou
  lembrete, sem duplicar quando tem os dois), Concluídas (mais recentes
  primeiro); lixeira fora de todas (RF-05);
- ordenação das visões (RF-11): atrasadas, vencem hoje, próximos prazos,
  prioridade decrescente, ordem de origem; sem prazo por último;
- My Day (RF-06 a RF-10): entrada por tarefa/data local (`YYYY-MM-DD`),
  ordem manual exclusiva (RF-12), adicionar/criar/remover, conclusão e
  lixeira tiram a tarefa do foco e rollover diário idempotente à meia-noite
  local (`removeBefore` transacional);
- `Task` estendido com `TaskPriority?` (baixa/média/alta/urgente),
  `dueDate` ISO de calendário local e `reminder` UTC (campos para as
  visões Planejado/Importante; semântica completa de lembretes na fatia 04);
- migração Drift **v2 → v3** não destrutiva: `my_day_entries` (com índice
  único tarefa/data) + colunas `priority`, `due_date`, `reminder`;
- `TasksService` remove entradas do My Day ao concluir/excluir
  (spec 03, RF-05/RF-09), coordenando via porta `MyDayRepository`;
- interface: página "Meu dia" (ordem manual com drag, adicionar existente,
  criar no foco, remover), chips de visão na página de tarefas, prioridade e
  prazo no detalhe da tarefa.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 111 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 89 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate: igual ao registro 0001 (macOS arm64, Flutter 3.47.0,
Dart 3.13.0, Chrome 153.0.8010.53, ChromeDriver 153.0.8010.52).

## 3. Cobertura dos critérios de aceitação (spec 03)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 ver todas | coberto | `smart_views_test.dart` |
| CA-02 localizar sem lista | coberto | `smart_views_test.dart` (ativas incluídas sem filtro de lista) |
| CA-03 filtrar importantes | coberto | `smart_views_test.dart` |
| CA-04 planejadas sem duplicação | coberto | `smart_views_test.dart` (prazo+lembrete = 1 ocorrência) |
| CA-05 atrasada em Planejado | coberto | `smart_views_test.dart` |
| CA-06 sem duplicação entre visões | coberto | `smart_views_test.dart` (projeções distintas) |
| CA-07 concluída sai de Importante/Planejado | coberto | `smart_views_test.dart` |
| CA-08 lixeira fora | coberto | `smart_views_test.dart` |
| CA-09 adicionar ao My Day | coberto | `my_day_service_test.dart`, `my_day_flow_test.dart` |
| CA-10 preservar prazo ao adicionar | coberto | `my_day_service_test.dart` (tarefa inalterada) |
| CA-11 reordenar e preservar | coberto | `my_day_service_test.dart`, `drift_my_day_repository_test.dart` |
| CA-12 remover do My Day | coberto | `my_day_service_test.dart`, `my_day_flow_test.dart` |
| CA-13 concluir no My Day | coberto | `my_day_service_test.dart`, `my_day_flow_test.dart` |
| CA-14 rollover | coberto | `my_day_service_test.dart`, `drift_my_day_repository_test.dart`, `my_day_flow_test.dart` (idempotente) |
| CA-15 rollover da inbox | coberto | `my_day_service_test.dart` |
| CA-16 subtarefas internas | coberto | `smart_views_test.dart` (somente tarefas principais) |

## 4. Decisões técnicas

- **Datas do My Day como `YYYY-MM-DD`** comparáveis lexicograficamente,
  sem conversão UTC (spec 06, RF-13); `dueDate` segue a mesma semântica
  (RF-11), permitindo ordenação e detecção de atraso simples e corretos.
- **Rollover no `removeBefore(today)`**: entradas de dias anteriores são
  pendentes por construção (concluir/excluir já remove na origem), então a
  remoção por data é idempotente e não altera mais nada (RF-10).
- **Coordenação via porta**: `TasksService` recebe `MyDayRepository` para
  limpar entradas em conclusão/lixo; sem acoplamento a implementação.
- **`ListView` do detalhe com `ScrollCacheExtent.pixels(1200)`**: seções
  fora da dobra são construídas, mantendo finders e semântica estáveis em
  testes e no smoke.

## 5. Limitações e desvios

- Lembretes: o campo `reminder` existe nas visões (Planejado), mas
  agendamento, validação de horário no passado e herança em recorrência são
  entregues na fatia da spec 04.
- Rollover executado ao abrir o My Day; um relógio contínuo com app aberto
  pode ser adicionado sem mudar o modelo (o `removeBefore` já é idempotente).
- Reordenação do My Day disponível por arrastar na UI (`ReorderableListView`);
  a reordenação determinística está coberta em testes de serviço e
  repositório, não em gesto de arrastar.
