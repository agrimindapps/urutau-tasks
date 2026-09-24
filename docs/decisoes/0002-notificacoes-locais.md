# ADR-0002: Notificações locais por plataforma

- **Status:** aceito
- **Data:** 2026-09-23
- **Especificação relacionada:** [Notificações por plataforma](../specs/08-notificacoes-por-plataforma.md)

## Contexto

O Urutau Tasks mantém as tarefas localmente e oferece um lembrete por tarefa
principal. As seis plataformas previstas — Android, iOS, Web, Linux, macOS e
Windows — oferecem capacidades diferentes de agendamento e dependem de
permissões ou de o aplicativo continuar em execução. O MVP não terá backend.

## Decisão

- Usar adaptadores de plataforma atrás de um contrato compartilhado para
  consultar capacidade e permissão, agendar, atualizar, cancelar, reconciliar
  e abrir a tarefa ao tocar no aviso.
- Solicitar autorização ao salvar o primeiro lembrete. Depois de uma negativa,
  não pedir novamente de forma automática; preservar a configuração e exibir
  o estado das notificações do sistema. A negativa não impede um aviso dentro
  do app enquanto ele estiver aberto e puder executar o temporizador.
- Reconciliar de forma idempotente ao iniciar ou retomar o app e após mudanças
  relevantes no lembrete, tarefa ou permissão, sem criar notificações
  duplicadas.
- Mostrar um aviso dentro do app quando ele estiver em primeiro plano e uma
  notificação do sistema quando estiver em segundo plano e a plataforma
  oferecer suporte. O aviso mostrará o título e abrirá a tarefa ao toque, sem
  ações rápidas.
- Cancelar o aviso ao concluir ou enviar a tarefa à lixeira. Preservar a
  configuração e reagendar apenas lembretes futuros ao editar, reabrir ou
  restaurar a tarefa.
- Não gerar avisos de catch-up quando o instante já tiver passado antes do
  agendamento ou da reconciliação. Respeitar atrasos próprios do sistema após
  aceitar um agendamento.
- Tratar a entrega como best effort segundo a matriz da especificação: Android
  aproximado sem acesso especial a alarmes exatos; iOS/macOS por notificações
  locais autorizadas; Web sem promessa com navegador fechado; Linux enquanto o
  aplicativo puder executar; Windows por agendamento local quando disponível,
  dentro das limitações documentadas do sistema.
- Não oferecer Push Web nem serviço de entrega remoto no MVP.
- Adiar a escolha do pacote Flutter e das APIs nativas para uma decisão técnica
  anterior à implementação.

## Alternativas consideradas

### Exigir que todas as plataformas entreguem no horário exato

Rejeitada porque os sistemas operacionais controlam o momento efetivo dos
avisos, algumas plataformas exigem que o aplicativo esteja executando e os
limites de permissão variam. Prometer pontualidade uniforme criaria um contrato
que não pode ser cumprido.

### Usar alarmes exatos no Android

Rejeitada para o MVP. A documentação do Android recomenda alarmes aproximados
para a maioria dos casos e reserva os alarmes exatos para usos estritamente
dependentes de horário, que exigem acesso especial em determinadas versões.
Lembretes de tarefa aceitarão atraso do sistema.

### Enviar Push Web por serviço remoto

Adiada. A Push API prevê entrega do servidor de aplicação através de um serviço
de Push quando o navegador ou o app web está inativo. Isso exigiria
infraestrutura, tratamento de assinatura e novas implicações de privacidade,
em conflito com o escopo local-first sem backend do MVP.

### Pedir permissão novamente sempre que um agendamento falhar

Rejeitada porque repetição automática após uma negativa prejudicaria a
previsibilidade do usuário. O aplicativo mantém a configuração e apresenta o
caminho para ajustar a permissão explicitamente.

### Usar apenas temporizadores do aplicativo em todas as plataformas

Rejeitada como estratégia geral porque um temporizador dentro do processo não
entrega enquanto o app não estiver executando. O adaptador usará agendamento do
sistema onde ele existir e manterá fallback visível nas demais situações.

## Consequências

- A configuração de lembrete permanece independente do estado da permissão e
  dos IDs locais de agendamento.
- O estado mostrado ao usuário deverá deixar claro que “agendado” significa
  que o sistema aceitou o pedido, sem prometer exibição pontual.
- O aplicativo precisará recompor os agendamentos desejados a partir dos dados
  locais e reconciliá-los sem duplicação.
- Notificações serão inconsistentes entre plataformas por limitações
  documentadas, principalmente quando Web ou Linux não mantiverem o app em
  execução.
- Testes de implementação deverão cobrir permissões, reconciliação, toques e
  transições de primeiro e segundo plano em cada adaptador.
- Nenhum pacote nem API nativa foi escolhido neste ADR. Essas opções deverão
  ser avaliadas e registradas antes da implementação.
