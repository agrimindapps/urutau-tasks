# Registro 0004: Fatia 04 — Prazos, lembretes e recorrência

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificações:** [Prazos, lembretes e recorrência](../specs/04-prazos-lembretes-e-recorrencia.md),
  [Persistência Drift e migrações](../specs/06-persistencia-drift-e-migracoes.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** continuidade do desenvolvimento contínuo após o gate da
  fatia 03 aprovado

## 1. Resultado obtido

- prazos com semântica de calendário local (RF-01/RF-02): `dueDate` ISO
  `YYYY-MM-DD`, passado = atrasada mas válido; lembrete como instante UTC
  independente do prazo (RF-03), único por tarefa principal;
- lembrete no passado rejeitado com orientação (RF-04); conclusão preserva a
  configuração e reabrir mantém vencido registrado sem alerta (RF-05);
- recorrência essencial (RF-08): diária, dias úteis (seg–sex), semanal,
  mensal e anual, ancorada na data-base do prazo (RF-07); séries com
  cancelamento manual que preserva histórico (RF-10);
- datas de calendário no calendário original (RF-09): 31/01 → 28/02 → 31/03
  (não desloca por fevereiro), 29/02 → 28/02 em anos não bissextos e volta
  a 29/02 em bissextos;
- conclusão de ocorrência (RF-11): histórico preservado com subtarefas,
  nova ocorrência ativa **sem subtarefas**, com prazo calculado no
  calendário original e lembrete herdado recalculado pela relação temporal
  com o prazo (RF-13); se o herdado cair no passado, fica vencido sem alerta
  imediato; **sem retroativas em lote** — apenas a próxima futura;
- alterar prazo/frequência vale da ocorrência atual em diante, sem reescrever
  histórico (RF-12); a base da série acompanha o prazo remarcado;
- migração Drift **v3 → v4** não destrutiva: tabela `series` + coluna
  `series_id` em `tasks`; conclusão + próxima ocorrência em **uma transação**
  (spec 06, RF-04) via `saveTasks`;
- interface: prazo com date picker, lembrete com date+time picker e
  validação de futuro, seletor de recorrência (bloqueado sem prazo) e
  cancelamento de série com confirmação.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 139 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 114 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate: igual ao registro 0001 (macOS arm64, Flutter 3.47.0,
Dart 3.13.0, Chrome 153.0.8010.53, ChromeDriver 153.0.8010.52).

## 3. Cobertura dos critérios de aceitação (spec 04)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 criar/editar prazo | coberto | `recurrence_service_test.dart` |
| CA-02 aceitar prazo atrasado | coberto | `recurrence_service_test.dart` (2026-09-01 em 25/09) |
| CA-03 lembrete independente | coberto | `recurrence_service_test.dart` (sem prazo) |
| CA-04 lembrete vs. prazo | coberto | `recurrence_service_test.dart` (antes/depois do prazo) |
| CA-05 rejeitar lembrete passado | coberto | `recurrence_service_test.dart` (instante exato incluído) |
| CA-06 cancelar notificação ao concluir | coberto | configuração preservada em `recurrence_service_test.dart` (agendamento = spec 08) |
| CA-07 reabrir com lembrete futuro | coberto | `recurrence_service_test.dart` |
| CA-08 reabrir com lembrete vencido | coberto | `recurrence_service_test.dart` (preservado) |
| CA-09 recorrência nas 5 frequências | coberto | `recurrence_test.dart` (diária/úteis/semanal/mensal/anual) |
| CA-10 cálculo mensal/anual | coberto | `recurrence_test.dart` (31/01→28/02→31/03; 29/02→28/02→29/02) |
| CA-11 concluir ocorrência | coberto | `recurrence_service_test.dart` (próxima criada) |
| CA-12 não copiar subtarefas | coberto | `recurrence_service_test.dart` |
| CA-13 herdar lembrete | coberto | `recurrence_service_test.dart` (+1 dia preservado) |
| CA-14 preservar histórico | coberto | `recurrence_service_test.dart` (ocorrência concluída com etapas) |
| CA-15 sem ocorrências retroativas | coberto | `recurrence_service_test.dart` (atrasada → próxima futura única) |
| CA-16 alterar série da ocorrência atual | coberto | `recurrence_service_test.dart` (frequência e prazo) |
| CA-17 cancelar série manualmente | coberto | `recurrence_service_test.dart`, `drift_recurrence_repository_test.dart` |
| CA-18 recorrência exige prazo | coberto | `recurrence_service_test.dart` |

## 4. Decisões técnicas

- **Cálculo da série pelo índice da data-base** (`occurrenceDateAt(n)`):
  mensal/anual nunca derivam da ocorrência anterior (evita 31/01→28/02→28/03),
  mantendo o calendário original (RF-09).
- **Próxima ocorrência = primeira data estritamente após `max(prazo, hoje)`**:
  concluída no prazo gera o passo seguinte; concluída atrasada pula direto
  para a próxima futura, sem retroativas em bloco (RF-11/CA-15).
- **Herança de lembrete por deslocamento**: a diferença entre o lembrete e o
  prazo da ocorrência concluída é preservada na nova (ex.: +1 dia), com
  validação de futuro apenas em criação/edição manual (RF-04/RF-13).
- **`saveTasks` transacional** para concluir + criar próxima (spec 06, RF-04).
- **Normalização UTC na leitura**: `row.reminder?.toUtc()` mantém a
  invariante "instante UTC" do modelo (spec 06, RF-12) independente do fuso
  do dispositivo.

## 5. Limitações e desvios

- Capacidade da plataforma, permissões e agendamento real de notificações
  (RF-06 da spec 04 e toda a spec 08) são a fatia 08; nesta fatia a
  configuração de lembrete persiste e as visões a utilizam.
- Um único lembrete por tarefa principal conforme a spec; não há lembretes
  por subtarefa (proibido pela spec 01/02).
- A página de detalhe usa `SingleChildScrollView` (conteúdo limitado) após
  observar que a `ListView` lazy do Flutter não construía as seções finais
  fora da dobra em testes, prejudicando interação e acessibilidade.
