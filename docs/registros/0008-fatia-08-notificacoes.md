# Registro 0008: Fatia 08 — Notificações por plataforma

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Notificações por plataforma](../specs/08-notificacoes-por-plataforma.md)
  e o [ADR-0004 de pacotes](../decisoes/0004-pacotes-notificacao.md)
- **Branch:** `Mimo-2.6-Flash`
- **Depende de:** Registros 0001–0007 e ADR-0002

## 1. Resultado obtido

Oitava fatia funcional do MVP entregue:

- **contrato do adaptador** (spec 08, seção 5): consultar capacidade e
  permissão sem efeitos colaterais, pedir permissão apenas por ação
  explícita, agendar/atualizar/cancelar de forma idempotente, aviso
  imediato de fallback e callback de toque com payload = UUID da tarefa;
- **identificador estável** derivado do UUID (hash de 31 bits) — no
  máximo um agendamento por tarefa, sem expor IDs do sistema;
- **estados de entrega** (seção 3.2): Agendado, Permissão necessária,
  Indisponível nesta plataforma, Vencido e Pendente de verificação,
  exibidos em chip no detalhe da tarefa (CA-12);
- **coordenador de lembretes**: elegibilidade (ativas, fora da lixeira,
  instante futuro — RF-05), reconciliação idempotente (CA-10), camada de
  sistema só fora do primeiro plano x aviso no app em primeiro plano sem
  duplicidade (CA-05/CA-13), sem catch-up de vencidos (CA-08), timers de
  primeiro plano e aviso imediato para Web/Linux com processo vivo;
- **permissão** (seção 6/CA-01/CA-02): diálogo explicativo no primeiro
  lembrete, pedido único via adaptador, marcação persistida; nunca
  repete o pedido automaticamente após a primeira execução;
- **adaptadores por compilação condicional** (ADR-0004):
  `adapter_io.dart` com `flutter_local_notifications` 22 (zonedSchedule
  aproximado — CA-11, permissões Darwin/Android, fuso via
  `flutter_timezone`+`timezone`), `adapter_web.dart` com a API
  `Notification` (sem agendamento — entrega best effort, CA-09) e stub;
  a Web nunca importa pacotes nativos;
- **integração**: reconciliação no start/retomada e após mutações de
  tarefa (criar/editar/concluir/lixear/restaurar/recorrência — RF-01 a
  RF-04), navegação ao toque da notificação (CA-06) e SnackBar em
  primeiro plano com ação para abrir a tarefa;
- i18n: novas chaves em `pt-BR`, `en` e `es`.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 193 testes |
| `flutter test --platform chrome` (domínio/aplicação/resolvedor) | aprovado, 110 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `./tool/web-smoke.sh` → `All tests passed` |

Ambiente do gate: idêntico ao
[Registro 0001](0001-fatia-01-ciclo-de-tarefas.md) — macOS 26.6.2 arm64,
Flutter 3.47.0 (`4cf2416426`), Chrome Stable 153.0.8010.53,
ChromeDriver 153.0.8010.52.

## 3. Cobertura dos critérios de aceitação

- CA-01/CA-02: widget do fluxo de permissão — diálogo único, marcação
  persistida e nenhuma nova solicitação automática.
- CA-03/CA-04: coordenador — atualização substitui o mesmo id; concluir/
  lixeira cancelam com configuração preservada; restauração reagenda só
  instantes futuros (reconciliação).
- CA-05: widget com relógio de teste — aviso no app em primeiro plano
  com ação "Abrir tarefa", sem notificação do sistema.
- CA-06: widget — toque simulado no adaptador navega ao detalhe.
- CA-07/CA-08: sem ações rápidas (SnackBar só navega); vencidos sem
  catch-up (coordenador + estado `expired`).
- CA-09: Web sem agendamento de sistema (adaptador `supportsScheduling=false`;
  entrega só com a página viva) — comportamento documentado e coberto
  pelos testes do coordenador (caminho de aviso imediato).
- CA-10: reconciliação repetida idempotente e revogação cancela avisos
  preservando a configuração.
- CA-11: `AndroidScheduleMode.inexact` sem acesso a alarmes exatos.
- CA-12: chip `Agendado` com permissão concedida.
- CA-13: segundo plano com sistema (não duplica) e Web/Linux (imediato
  único) — testes do coordenador.

## 4. Limitações, desvios e aprendizados

- O código do adaptador nativo (`adapter_io`) **não é exercitado pelo
  gate**: roda apenas em builds de plataforma real; validação depende da
  matriz manual (spec 10). O coordenador e o fluxo de permissão são
  cobertos com adaptador falso.
- **Bug real pescado:** no instante do disparo `now == reminder` — o
  `isAfter` estrito descartava o próprio aviso (o alerta nunca
  dispararia); o `_onTimer` agora aceita o instante atual e rejeita
  apenas instantes estritamente anteriores.
- `ref` não pode ser usado em `State.dispose` (Riverpod): o coordenador
  da casca ficou em campo `late final` inicializado no `initState`.
- `tester.runAsync(() => service.createTask(...))` pendurava a ponte
  entre os relógios real/fake; o padrão vencedor é criar sem await e
  avançar o relógio com `tester.pump(duration)`.
- Uma cópia residual de `Zone.root.run(database.close)` no helper de
  teste causou hangs intermitentes de fechamento; o helper limpo
  (pumpWidget → pump(1ms) → close) é o contrato.
- `SharedPreferences.setMockInitialValues({})` por teste isola a
  preferência de idioma e a marcação de permissão (spec 09/08).
- Decisão: a reconciliação roda após cada mutação relevante de tarefa
  via hook opcional em `TasksService` — operação barata e idempotente,
  alinhada ao RF-05.

## 5. Intervenções humanas

- Instrução para prosseguir com a spec 08 após a entrega da fatia 07 e
  pedido de commit + push ao final desta etapa.
