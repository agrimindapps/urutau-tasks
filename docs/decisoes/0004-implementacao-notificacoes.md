# ADR-0004: Implementação de notificações locais

- **Status:** aceito
- **Data:** 2026-09-24
- **Especificações relacionadas:** [Notificações por plataforma](../specs/08-notificacoes-por-plataforma.md), [Prazos, lembretes e recorrência](../specs/04-prazos-lembretes-e-recorrencia.md)

## Contexto

O Urutau Tasks precisa entregar lembretes em Android, iOS, Web, Linux, macOS e
Windows sem servidor. A especificação 08 exige notificações nativas quando
disponíveis, um aviso dentro do app em primeiro plano e fallbacks sem prometer
entrega com o navegador fechado ou o app Linux encerrado.

## Decisão

- Usar `flutter_local_notifications` (`^22.3.1` na implementação inicial) como
  integração de avisos do sistema em todas as seis plataformas. O adaptador do
  produto chamará a API do plugin; widgets e repositórios de tarefas não
  dependerão diretamente dele.
- Agendar lembretes como instantes UTC usando `zonedSchedule` e a zona UTC do
  pacote `timezone`. O valor persistido permanece o instante UTC escolhido
  pelo usuário, inclusive após mudança de fuso.
- No Android, usar agendamento inexacto que permite execução durante idle e
  declarar somente as permissões normais necessárias para notificações e
  reinício. Não pedir `SCHEDULE_EXACT_ALARM` nem `USE_EXACT_ALARM`. O pequeno
  ícone do aviso usará um recurso monocromático dedicado em `drawable`, separado
  do ícone colorido de inicialização do aplicativo.
- No iOS e macOS, usar notificações locais do sistema e o fluxo de autorização
  do plugin, sempre respeitando a resposta do usuário.
- No Windows, usar notificações locais agendadas quando a integração do sistema
  estiver disponível. Empacotar a distribuição MSIX com o pacote `msix`
  (`^3.18.0`, dependência de desenvolvimento), identidade estável
  `com.urutau.urutautasks` e suporte mínimo de pacote Windows 10 versão 1809
  (`10.0.17763.0`). A identidade permite cancelamento e reconciliação
  confiáveis pelo plugin. Configurar o ativador de toast MSIX com o CLSID usado
  pelo adaptador Windows para que tocar no aviso abra a tarefa. O identificador
  informado ao plugin para registrar o app também será
  `com.urutau.urutautasks`, mantendo a configuração coerente com o nome de
  identidade MSIX; quando houver identidade de pacote, o plugin usa a
  identidade do pacote para criar o agendador de toasts. Em sessões sem essa
  integração confirmada, manter o lembrete e usar o temporizador em primeiro
  plano. O certificado de teste do pacote serve apenas para validação local;
  assinatura para distribuição pública fica para uma decisão própria.
- No Linux e na Web, manter um temporizador do processo enquanto o app puder
  executar e exibir o aviso imediato pelo plugin quando o prazo vencer. Essas
  plataformas não usarão uma API de agendamento futuro que não oferecem; o
  fechamento do app/página impede a entrega.
- Distinguir disponibilidade da integração e autorização do usuário. Na Web,
  consultar o resultado de inicialização do plugin, a Notification API e o
  registro do service worker. No Linux, consultar as capacidades do serviço de
  notificações via D-Bus no início e ao retomar o app. Se a integração estiver
  indisponível, manter o lembrete e o fallback dentro do app, informando a
  limitação sem classificá-la como permissão negada.
- Ao entrar em primeiro plano, cancelar o agendamento nativo controlado pelo
  app e manter o aviso local em memória; ao ir para segundo plano, cancelar o
  temporizador em memória e agendar no sistema quando suportado. Essa troca
  evita que o mesmo lembrete produza dois avisos.
- Pedir autorização durante a ação explícita de configurar o primeiro lembrete,
  antes de abrir etapas assíncronas de seleção de data e hora na Web. Persistir
  se a solicitação já ocorreu. Uma negativa não causa novos pedidos
  automáticos; uma ação específica do usuário nas configurações pode tentar de
  novo quando o sistema permitir.
- Usar o UUID da tarefa como payload de navegação e manter uma associação local
  estável entre tarefas e IDs inteiros exigidos pelo plugin. Essa associação é
  infraestrutura e fica fora dos arquivos de portabilidade.
- Reconciliar configurações de lembrete com tarefas ativas no início, ao
  retomar e após mudanças de tarefa, sem catch-up para lembretes vencidos.

## Alternativas consideradas

### Um pacote Flutter diferente por plataforma

Rejeitada porque criaria contratos e ciclos de manutenção separados. O plugin
escolhido oferece uma API compartilhada, permitindo reservar adaptações apenas
às diferenças documentadas entre plataformas.

### Temporizadores do app em todas as plataformas

Rejeitada porque não entregaria quando o processo estivesse suspenso ou
encerrado em plataformas com agendamento do sistema.

### Usar Push Web

Rejeitada para o MVP por exigir serviço de aplicação e infraestrutura remota,
fora do contrato local-first.

## Consequências

- A versão inicial exige Flutter 3.38.1 ou superior; o ambiente atual do
  projeto usa Flutter 3.47.2.
- A configuração Android precisará habilitar desugaring e receivers de
  agendamento/reinício exigidos pelo plugin. A configuração não incluirá
  permissão de alarmes exatos.
- O plugin não agenda no Linux nem na Web; seus temporizadores são melhores
  esforços e dependem do app estar executando.
- No Windows, cancelamento confiável requer que o pacote possua identidade
  MSIX. O adaptador deverá indicar indisponibilidade quando essa condição não
  puder ser confirmada.
- A configuração MSIX estabelece Windows 10 versão 1809 (`10.0.17763.0`) como
  requisito mínimo de instalação do pacote atual. O ambiente Windows ainda
  precisa gerar e instalar o pacote para validar a identidade e os avisos.
- Notificações aceitas pelo sistema continuam sujeitas aos limites do sistema,
  permissões, economia de energia e políticas de entrega de cada plataforma.

## Referências técnicas

- [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
- [Limitações Linux e Web do plugin](https://pub.dev/packages/flutter_local_notifications#caveats-and-limitations)
- [Agendamento Android aproximado e exato no plugin](https://pub.dev/packages/flutter_local_notifications#scheduled-notifications)
