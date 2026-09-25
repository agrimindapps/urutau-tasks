# ADR-0004: Pacotes de notificação por plataforma

- **Data:** 2026-09-25
- **Status:** aceito
- **Contexto:** o [ADR-0002](0002-notificacoes-locais.md) definiu adaptadores
  atrás de contrato compartilhado, entrega *best effort* e deixou a escolha
  de pacotes/APIs como decisão técnica anterior à implementação (fatia 08).
  A [spec 08](../specs/08-notificacoes-por-plataforma.md) exige agendamento
  local, cancelamento idempotente, permissão pedida uma única vez e aviso
  sem ações rápidas.

## Decisão

- **Android/iOS/macOS/Windows/Linux:** `flutter_local_notifications` com
  `zonedSchedule` em modo **inexactAllowWhileIdle** no Android (sem alarmes
  exatos, conforme a matriz da spec 08) e fuso resolvido por
  `flutter_timezone` + `timezone`.
- **Web:** API `Notification` do navegador via `package:web`, com agendamento
  em timer da página (best effort; sem servidor, não há entrega com o
  navegador fechado).
- **Plataformas sem suporte:** adaptador *stub* que reporta capacidade
  ausente.
- Seleção por **import condicional** (`dart.library.io` /
  `dart.library.js_interop`), mantendo cada implementação isolada.

## Alternativas consideradas

- **Push Web com servidor:** contraria o ADR-0002 (exige infraestrutura e
  enfraquece o modelo local-first).
- **`awesome_notifications`:** mais recursos, porém mais acoplamento e
  sobreposição com o contrato já definido; o `flutter_local_notifications`
  cobre o necessário (agendar/atualizar/cancelar) com manutenção ativa.
- **Alarmes exatos no Android:** exigiria permissão especial e contradiz a
  matriz da spec 08 (agendamento aproximado).

## Consequências

- Entrega pontual **não é garantida** (aproximada no Android; janela de
  ~5 min no Windows; best effort na Web/Linux), como já avisado pelos
  estados de entrega na interface.
- IDs de agendamento derivam do UUID da tarefa por *hash* determinístico:
  são infraestrutura e não entram no backup (spec 08, §3).
- Atualizações futuras de pacotes podem exigir ajustes nos adaptadores,
  isolados por compilação condicional.
