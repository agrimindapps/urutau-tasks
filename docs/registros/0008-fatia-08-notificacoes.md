# Registro 0008: Fatia 08 — Notificações por plataforma

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificações:** [Notificações por plataforma](../specs/08-notificacoes-por-plataforma.md),
  [ADR-0002](../decisoes/0002-notificacoes-locais.md) e
  [ADR-0004](../decisoes/0004-pacotes-notificacao.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** continuidade do desenvolvimento contínuo após o gate da
  fatia 07 aprovado

## 1. Resultado obtido

- contrato de adaptador único (spec 08, §5): consultar capacidade/permissão,
  pedir permissão (só em ação do usuário), agendar (um único aviso futuro
  por tarefa, ID estável derivado do UUID), atualizar substituindo,
  cancelar idempotente e reconciliar;
- **estados de entrega exibidos** (§3): Agendado, Permissão necessária,
  Indisponível nesta plataforma, Vencido e Pendente de verificação;
- adaptadores por compilação condicional (ADR-0004):
  `flutter_local_notifications` (Android com agendamento **aproximado**
  `inexactAllowWhileIdle`, iOS/macOS com autorização, Windows/Linux best
  effort), **Web** com Notification API em modo best effort (sem promessa
  com navegador fechado) e stub para plataformas sem suporte;
- permissão (§6): explicação + pedido **uma única vez** no primeiro lembrete;
  após negativa nada é repetido automaticamente — a configuração é
  preservada, o estado aparece na interface e nova tentativa só por ação
  explícita (botão "Permitir notificações"); permissão concedida depois
  agenda futuros; revogada cancela pendentes quando possível;
- ciclo do lembrete (RF-01 a RF-05): concluir/excluir cancela o aviso e
  preserva a configuração; reabrir/restaurar reagenda apenas se futuro;
  recorrência agenda só a ocorrência ativa futura (via reconciliação);
  **reconciliação idempotente** vinculada ao stream de tarefas — executa ao
  iniciar e após cada mudança, sem pedir permissão e sem alterar o domínio;
- primeiro plano × segundo plano (§8): o disparo com o app aberto vira aviso
  no app e **cancela** o do sistema (sem duplicidade); instante no passado
  não agenda nem faz catch-up (estado Vencido);
- tocar no aviso **navega para o detalhe da tarefa** (CA-06) via chave
  global de navegação, sem ações rápidas no aviso (§5).

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 208 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 170 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate: igual ao registro 0001 (macOS arm64, Flutter 3.47.0,
Dart 3.13.0, Chrome 153.0.8010.53, ChromeDriver 153.0.8010.52).

## 3. Cobertura dos critérios de aceitação (spec 08)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 pedir permissão no primeiro lembrete | coberto | `reminder_coordinator_test.dart`, `reminder_flow_test.dart` (explicação + pedido único) |
| CA-02 preservar lembrete após negativa | coberto | `reminder_coordinator_test.dart` (config intacta + estado) |
| CA-03 atualizar/cancelar sem duplicata | coberto | `reminder_coordinator_test.dart` (substituição; cancelar idempotente) |
| CA-04 conclusão/lixeira/restauração | coberto | `reminder_coordinator_test.dart` (cancela; reabrir reagenda se futuro) |
| CA-05 aviso em primeiro plano | coberto | `reminder_coordinator_test.dart` (aviso no app + cancela o do sistema) |
| CA-06 toque abre o detalhe | coberto | `reminder_flow_test.dart` (roteamento para o detalhe) |
| CA-07 sem ações rápidas | coberto | aviso com título e corpo simples (implementação do adaptador) |
| CA-08 vencimento sem catch-up | coberto | `reminder_coordinator_test.dart` (estado Vencido, nada agendado) |
| CA-09 Web/Linux sem execução garantida | coberto | contrato best effort; matriz registrada no ADR-0004 |
| CA-10 reconciliação idempotente e revogação | coberto | `reminder_coordinator_test.dart` (duas execuções; revogar cancela) |
| CA-11 Android sem alarme exato | coberto | `AndroidScheduleMode.inexactAllowWhileIdle` (ADR-0004) |
| CA-12 permissão concedida → Agendado | coberto | `reminder_coordinator_test.dart`, `reminder_flow_test.dart` |
| CA-13 segundo plano → notificação do sistema | coberto | `reminder_coordinator_test.dart` (agenda no adaptador quando elegível) |

## 4. Decisões técnicas

- **Reconciliação ligada ao stream de tarefas** (`bindTo`): cada mudança de
  dados dispara a reconciliação idempotente, cobrindo inicialização,
  retomada e mudanças de lembrete/tarefa/permissão sem espalhar chamadas
  (RF-05).
- **Arbitragem do disparo duplo** (§8): o timer de primeiro plano cancela o
  aviso do sistema no instante do disparo; na Web o adaptador só notifica
  com a página oculta.
- **Scheduler de primeiro plano injetável** (`ForegroundScheduler`): os
  testes evitam timers reais de longa duração e o comportamento de
  primeiro plano é determinístico.
- **ID de agendamento por FNV-1a** do UUID: determinístico entre execuções
  e plataformas, é infraestrutura e não entra no backup (§3).

## 5. Limitações e desvios

- Entrega pontual segue a matriz *best effort* (Android aproximado,
  Windows com janela de ~5 min, Web/Linux condicionais), como os estados
  de entrega deixam visível.
- Verificação manual nas plataformas nativas (Android/iOS/desktop) é o
  marco da spec 10 (não bloqueante) e fica registrada como **não executada**
  nesta rodada; o gate Web é o bloqueante e está aprovado.
- Aviso em primeiro plano usa `SnackBar`; um componente mais destacado
  pode ser explorado sem mudar o contrato.

## 6. Encerramento do MVP

Com esta fatia, as 8 entregas do escopo do MVP estão completas
(specs 01–09 implementadas; spec 10 atendida pelo gate Web em cada fatia).
O [matriz de validação multiplataforma](../specs/10-validacao-multiplataforma.md)
fica com os registros por rodada nos registros 0001–0008 e as rodadas
manuais de marco (Android/iOS/Linux/macOS/Windows) como próximo passo de
validação, fora do gate.
