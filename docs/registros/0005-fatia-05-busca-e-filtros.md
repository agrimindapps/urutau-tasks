# Registro 0005: Fatia 05 — Busca e filtros

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificação:** [Busca e filtros](../specs/05-busca-e-filtros.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** continuidade do desenvolvimento contínuo após o gate da
  fatia 04 aprovado

## 1. Resultado obtido

- motor de consulta `searchTasks` (projeção sem cópias, RF-18/RF-19):
  busca global fora da lixeira (RF-01/RF-02), texto em título, notas e
  descrições de todas as subtarefas com resultado sempre na tarefa
  principal (RF-03/RF-04);
- correspondência parcial, sem maiúsculas e **insensível a acentos**
  (`reuniao` acha `Reunião`; `cafe` acha `café`) por tabela de
  normalização, sem alterar o texto armazenado (RF-05);
- combinação de filtros: categorias diferentes em **AND**, opções da mesma
  categoria em **OR** (RF-08); status (RF-09), listas múltiplas + "Sem
  lista" e grupos (considerando suas listas; sem lista nunca entra;
  cumulativo com lista) (RF-10), categorias/tags com "Sem categoria" e
  "Sem tags" (RF-11), prioridades (RF-12), prazos (sem prazo/atrasadas/
  hoje/próximos 7 dias/intervalo inclusivo) (RF-13), lembrete com/sem
  (RF-14) e recorrência ativa/cancelada/nenhuma (RF-15);
- atrasadas = **ativas** com prazo passado; concluída com prazo passado
  não é atrasada (CA-20);
- relevância textual: título > notas > subtarefas com ordem de origem como
  desempate; sem texto, ordem de origem (RF-16); indicação do campo da
  correspondência no resultado (RF-17);
- interface: página Buscar na navegação global, campo com **debounce de
  300 ms** (RF-06), folha de filtros com ações fixas e chips por categoria.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 162 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 137 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate: igual ao registro 0001 (macOS arm64, Flutter 3.47.0,
Dart 3.13.0, Chrome 153.0.8010.53, ChromeDriver 153.0.8010.52).

## 3. Cobertura dos critérios de aceitação (spec 05)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 busca global por título | coberto | `task_query_test.dart`, `search_flow_test.dart` |
| CA-02 notas | coberto | `task_query_test.dart` |
| CA-03 por subtarefa | coberto | `task_query_test.dart` |
| CA-04 ignorar maiúsculas/acentos | coberto | `task_query_test.dart` (`reuniao`/`REUNIÃO`) |
| CA-05 parcial | coberto | `task_query_test.dart` (`relat`, `mensal`) |
| CA-06 filtros sem texto | coberto | `task_query_test.dart`, `search_flow_test.dart` |
| CA-07 debounce | coberto | `search_flow_test.dart` (resultados mudam após 300 ms) |
| CA-08 excluir lixeira | coberto | `task_query_test.dart` |
| CA-09 status | coberto | `task_query_test.dart` |
| CA-10 organização/prioridade | coberto | `task_query_test.dart`, `search_flow_test.dart` |
| CA-11 Sem lista | coberto | `task_query_test.dart` |
| CA-12 combinar filtros | coberto | `task_query_test.dart` (OR de listas; AND lista×categoria) |
| CA-13 prazos relativos | coberto | `task_query_test.dart` (atrasadas/hoje/+7 dias) |
| CA-14 intervalo personalizado | coberto | `task_query_test.dart` (limites inclusivos) |
| CA-15 lembrete | coberto | `task_query_test.dart` |
| CA-16 recorrência | coberto | `task_query_test.dart` (ativa/cancelada/nenhuma) |
| CA-17 relevância | coberto | `task_query_test.dart`, `search_flow_test.dart` (indicação do campo) |
| CA-18 resultado principal único | coberto | `task_query_test.dart` |
| CA-19 preservar dados | coberto | `task_query_test.dart` (objeto inalterado) |
| CA-20 concluída não é atrasada | coberto | `task_query_test.dart` |

## 4. Decisões técnicas

- **Normalização própria sem dependência**: tabela de equivalências de
  diacríticos latinos (pt/es) para comparação; o texto armazenado permanece
  intacto (RF-05) e docs/03 pede dependências mínimas.
- **Contexto de consulta explícito** (`QueryContext`) com mapa lista→grupo e
  série→cancelada: o motor de busca não depende de repositórios e é testado
  de forma pura.
- **Sentinelas `kNoList`/`kNoCategory`/`kNoTags`** para as opções negativas,
  mantendo a semântica OR dentro da categoria.
- **Ações do filtro fixas** fora da área rolável: o conteúdo da folha excede
  a viewport e os botões ficavam fora do alcance tátil (correção registrada
  após o teste de widget identificar hit test vazio).

## 5. Limitações e desvios

- Faixa personalizada de prazo usa dois seletores de data (início/fim);
  sem seletores de horário — prazos são datas de calendário (spec 04).
- A ordenação por relevância usa ordem de origem como desempate; um score
  por número de ocorrências não é exigido pela spec.
