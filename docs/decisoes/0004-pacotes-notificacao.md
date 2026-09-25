# ADR-0004: Pacotes de notificação local

- **Status:** aceito
- **Data:** 2026-09-24
- **Especificação relacionada:** [Notificações por plataforma](../specs/08-notificacoes-por-plataforma.md) (seção 9)
- **ADR base:** [ADR-0002](0002-notificacoes-locais.md)

## Contexto

O ADR-0002 definiu o contrato de adaptadores e a estratégia best effort,
mas adiou a escolha do pacote Flutter e das APIs nativas para uma decisão
técnica anterior à implementação (spec 08, seção 9). O gate Web é
bloqueante: qualquer pacote nativo precisa ficar fora do caminho de
compilação da Web, e o Web precisa de uma implementação própria.

## Decisão

- **Plataformas nativas (Android, iOS, macOS, Windows, Linux):**
  [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
  22.3.1 — pacote maduro e mantido com agendamento local (`zonedSchedule`),
  permissões e callbacks de toque; cobre as cinco plataformas com uma API.
  - **Linux:** o pacote não oferece agendamento futuro; o adaptador declara
    `supportsScheduling = false` e a entrega usa o temporizador do
    coordenador com aviso imediato enquanto o processo estiver vivo,
    conforme a matriz da spec 08 (freedesktop não define temporizador).
  - **Android:** `zonedSchedule` em modo aproximado (sem
    `SCHEDULE_EXACT_ALARM`), conforme ADR-0002/CA-11.
  - **Fuso horário:** `timezone` 0.11 + `flutter_timezone` 5.1 para
    converter o instante UTC do lembrete em `TZDateTime` local.
- **Web:** API `Notification` do navegador via [`web`](https://pub.dev/packages/web)
  1.1.1 (W3C, Dart puro). Sem agendamento persistente (fora do MVP, ver
  ADR-0002): a entrega usa os temporizadores do coordenador enquanto a
  página estiver aberta — em primeiro plano, aviso no app; em aba oculta,
  `new Notification(title)`. Nenhuma promessa com o navegador fechado
  (CA-09).
- **Separação por compilação condicional:** `adapter_io.dart`
  (flutter_local_notifications), `adapter_web.dart` (Notification API) e
  `adapter_stub.dart` — a Web nunca importa pacotes com `dart:phi`/plugins
  nativos, preservando `flutter build web`.
- **Identificador estável:** derivado do UUID da tarefa
  (`parseInt(uuid[0..8], radix: 16) & 0x7fffffff`), garantindo no máximo
  um agendamento por tarefa sem expor IDs do sistema entre plataformas.

## Alternativas consideradas

### flutter_local_notifications em todas as plataformas (inclusive Web)

Rejeitada: o pacote não implementa Web; importá-lo quebraria o build Web
do gate.

### OneSignal / Firebase Cloud Messaging

Rejeitado: exige serviço externo e backend, contra o local-first do MVP.

### Somente temporizadores do aplicativo (todas as plataformas)

Rejeitado como estratégia única (ADR-0002): não entrega com o app fora
de execução nas plataformas que suportam agendamento do sistema.

### package:notifications ou APIs diretas por plugin

Rejeitado: APIs W3C via `package:web` já são o caminho natural na Web;
nas plataformas nativas não há substituto mantido equivalente a
`flutter_local_notifications`.

## Consequências

- O código nativo não é exercitado pelo gate Web; a validação real em
  Android/iOS/Linux/macOS/Windows depende da matriz manual (spec 10).
- O coordenador mantém a lógica de elegibilidade, reconciliação e
  primeiro-plano independente do adaptador — testável com adaptador falso.
- A troca futura do pacote nativo fica isolada em `adapter_io.dart`.
