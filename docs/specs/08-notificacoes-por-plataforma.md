# Especificação SDD: Notificações por plataforma

**Status:** proposta para implementação

**Versão:** 1.0

**Escopo:** entrega de lembretes locais em Android, iOS, Web, Linux, macOS e Windows

## 1. Contexto

Esta especificação define como a configuração de lembrete de uma tarefa será
convertida em um aviso em cada plataforma suportada. Ela detalha os adaptadores
mencionados na [especificação de prazos, lembretes e recorrência](04-prazos-lembretes-e-recorrencia.md)
e respeita o armazenamento do lembrete como instante UTC definido pela
[especificação de persistência](06-persistencia-drift-e-migracoes.md).

O produto não terá servidor de aplicação nem serviço de Push no MVP. A entrega
depende da capacidade e das permissões do sistema e, portanto, será best effort.
As escolhas arquiteturais estão registradas no
[ADR de notificações locais](../decisoes/0002-notificacoes-locais.md). A
escolha do plugin e o tratamento das limitações estão no
[ADR técnico de implementação](../decisoes/0004-implementacao-notificacoes.md).

## 2. Objetivo

Definir um contrato compartilhado para consultar a capacidade de notificação,
solicitar autorização, agendar, atualizar e cancelar lembretes, reconciliar o
estado local com o sistema operacional e abrir a tarefa quando o usuário tocar
no aviso.

## 3. Conceitos e invariantes

### 3.1 Configuração do lembrete

A configuração é o instante UTC persistido na tarefa principal. Cada tarefa
pode ter no máximo um lembrete, tratado como evento único. A seleção de data e
hora continua sendo interpretada no horário local no momento em que é salva,
conforme a especificação 04.

A configuração pertence ao produto e não será removida por falta de permissão,
indisponibilidade da plataforma, conclusão ou envio à lixeira. IDs atribuídos
pelo sistema operacional são dados de infraestrutura, não portáveis e não
incluídos em backup, conforme a
[especificação de backup](07-backup-restauracao-formato-aberto.md).

### 3.2 Estado de entrega

O detalhe da tarefa deverá mostrar um estado compreensível, atualizado quando
o aplicativo consultar a plataforma:

- **Agendado:** há um caminho de entrega preparado para o horário futuro: o
  sistema aceitou uma notificação agendada ou o aplicativo armou um temporizador
  local em memória. Isso não garante que o aviso será exibido no horário
  pretendido. Quando o caminho depender do processo, o app deverá continuar
  executando; Web e Linux não prometem entrega depois que a página ou o app
  deixa de executar.
- **Permissão necessária:** a autorização para notificações do sistema está
  negada ou precisa ser alterada nas configurações do sistema ou navegador. O
  aviso dentro do app continua possível enquanto ele puder executar.
- **Indisponível nesta plataforma:** a plataforma ou a sessão atual não oferece
  a entrega necessária.
- **Cancelamento não confirmado:** uma tentativa de remover um aviso anterior
  falhou; ele ainda poderá aparecer, e o adaptador tentará cancelar novamente.
- **Vencido:** o instante passou e não será criado um aviso atrasado pelo
  aplicativo.
- **Pendente de verificação:** a capacidade ainda não foi consultada, ou uma
  falha temporária impediu a confirmação do estado.

O estado de entrega não altera a configuração do lembrete nem a disponibilidade
das demais funções da tarefa.

## 4. Matriz de capacidade por plataforma

| Plataforma | Comportamento previsto |
| --- | --- |
| Android | Agendamento aproximado, sem solicitar acesso especial a alarmes exatos. O sistema pode atrasar o aviso, por exemplo, por economia de bateria. [Android Developers: alarms](https://developer.android.com/develop/background-work/services/alarms) |
| iOS | Notificações locais agendadas pelo sistema, sujeitas à autorização do usuário. [Apple: agendar notificação local](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app) |
| macOS | Notificações locais agendadas pelo sistema, sujeitas à autorização do usuário. [Apple: agendar notificação local](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app) |
| Web | Best effort sem servidor. Não prometer entrega com o navegador fechado: a Push API prevê entrega assíncrona quando o app está inativo por meio de um servidor de aplicação e serviço de Push, fora do MVP. [W3C Push API](https://www.w3.org/TR/push-api/) |
| Linux | Best effort enquanto o aplicativo puder executar. O protocolo freedesktop envia um aviso ao serviço de notificações, sem definir um temporizador futuro; exigir o app ativo para disparar o temporizador é uma inferência desse limite. [freedesktop Notifications](https://specifications.freedesktop.org/notification/1.2/protocol.html) |
| Windows | Agendamento local quando a integração do sistema estiver disponível. A janela documentada de entrega é de cinco minutos; se o computador permanecer desligado por mais tempo após o horário, o aviso pode ser descartado. [Microsoft Learn: scheduled app notifications](https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/app-notifications-scheduled) |

O adaptador deverá distinguir falta de permissão de falta de capacidade. Não
deverá apresentar a entrega como garantida em nenhuma plataforma.

## 5. Contrato do adaptador

O aplicativo deverá depender de um contrato de aplicação independente das APIs
nativas. Os nomes abaixo descrevem responsabilidades, não exigem nomes de
classes ou métodos específicos.

| Operação | Responsabilidade |
| --- | --- |
| Consultar capacidade e permissão | Informar suporte atual, estado de autorização, possibilidade de pedir autorização, canal de entrega disponível e limitações relevantes, sem abrir diálogo ou alterar estado. |
| Pedir permissão | Abrir o fluxo do sistema apenas em resposta à ação do usuário durante a configuração do primeiro lembrete. Devolver o resultado para a interface e para a reconciliação. |
| Agendar | Registrar um único aviso futuro com o ID da tarefa, seu título atual e o instante UTC. Retornar se o sistema aceitou ou indicar permissão/indisponibilidade/falha. |
| Atualizar | Substituir o agendamento existente da mesma tarefa quando o instante ou o título mudar, sem deixar cópias do aviso anterior. |
| Cancelar | Remover o agendamento associado à tarefa. A operação é idempotente e não falha apenas porque o aviso já não existe. |
| Reconciliar | Comparar os lembretes elegíveis persistidos com os avisos controlados pelo aplicativo: criar os ausentes, atualizar os alterados, cancelar os que já não se aplicam e atualizar os estados exibidos. Repetir a operação não deverá criar duplicatas. |
| Abrir ao tocar | Resolver o ID da tarefa associado ao aviso, abrir o aplicativo e navegar ao detalhe dessa tarefa. |

O identificador usado para substituir ou cancelar avisos deverá ser estável
para a mesma tarefa durante a vida do agendamento. A implementação poderá
derivá-lo do UUID da tarefa ou mantê-lo em um registro local, mas deverá impedir
mais de um agendamento ativo para a mesma tarefa. Identificadores internos do
sistema não deverão ser compartilhados entre plataformas.

O aviso conterá o título atual da tarefa. A interface não oferecerá ações
rápidas, como concluir, adiar ou dispensar o lembrete permanentemente. Tocar
no aviso abrirá o detalhe da tarefa.

## 6. Permissão e disponibilidade

Ao configurar o primeiro lembrete, o aplicativo deverá explicar que avisos
dependem da permissão do sistema e então solicitar autorização, se a plataforma
suportar esse pedido e ainda não houver uma negativa anterior. O lembrete será
salvo mesmo quando a autorização for recusada.

Depois de uma negativa, o aplicativo não deverá repetir automaticamente o
pedido ao criar outro lembrete, editar a tarefa, iniciar ou retomar o app,
restaurar dados ou executar reconciliação. Deverá preservar e exibir a
configuração, informar que as notificações do sistema estão desativadas e
oferecer orientação ou atalho para as configurações do sistema/navegador
quando disponível. A negativa não impedirá um aviso dentro do app enquanto ele
estiver aberto e puder executar o temporizador. Uma nova tentativa de pedir a
permissão do sistema deverá decorrer de ação explícita do usuário.

Se a autorização for concedida posteriormente, a próxima consulta ou evento de
ciclo de vida deverá atualizar o estado e agendar lembretes futuros elegíveis.
Se for revogada, o estado deverá passar a indicar permissão necessária; o
aplicativo deverá cancelar agendamentos pendentes quando a plataforma permitir
e preservar as configurações.

No Android, o adaptador não deverá solicitar acesso especial para alarmes
exatos. A permissão normal para exibir notificações deverá ser consultada e
solicitada conforme o fluxo da plataforma.

## 7. Ciclo de vida e reconciliação

### RF-01 — Criar lembrete

No primeiro uso, explicar e solicitar autorização durante a ação explícita de
configurar um lembrete, conforme a seção 6. Na Web, fazer isso no botão da
explicação antes dos seletores assíncronos de data e hora, preservando o gesto
do usuário exigido pelo navegador. Nas plataformas nativas, salvar primeiro a
configuração escolhida e solicitar autorização em seguida, antes de agendar o
aviso. Em qualquer plataforma, salvar o lembrete mesmo se a autorização for
recusada. Se houver suporte e autorização, agendar o aviso; caso contrário,
manter a tarefa utilizável e exibir o estado correspondente.

Quando a plataforma não oferece agendamento futuro pelo sistema, armar um
temporizador local enquanto o app puder executar e tentar exibir um aviso
imediato do sistema no vencimento se essa integração estiver disponível.

### RF-02 — Editar ou remover lembrete

Ao editar um lembrete, rejeitar a alteração se o novo horário já tiver
passado, conforme a especificação 04. Se for futuro, substituir o agendamento
anterior pelo novo instante, desde que a entrega esteja disponível. Ao remover
a configuração, cancelar o aviso associado e remover o lembrete da tarefa.

### RF-03 — Concluir, reabrir e enviar à lixeira

Ao concluir uma tarefa ou enviá-la à lixeira, cancelar o aviso pendente e
preservar a configuração do lembrete. Ao reabrir ou restaurar a tarefa,
reagendar somente se o instante ainda estiver no futuro e a plataforma
permitir.

### RF-04 — Recorrência

Quando uma ocorrência recorrente concluída gerar a próxima ocorrência, seguir
a regra de herança e cálculo definida na especificação 04. Agendar somente o
lembrete da ocorrência ativa e futura; cada ocorrência mantém a própria
configuração e identificador de tarefa.

### RF-05 — Reconciliação idempotente

Executar reconciliação ao iniciar e retomar o aplicativo, após alterações de
lembrete ou estado da tarefa e após mudança de permissão quando ela for
observável. Em plataformas que permitem reagendamento depois de reiniciar o
dispositivo, a integração poderá disparar a mesma reconciliação nesse evento.

A reconciliação deverá considerar como elegíveis somente tarefas existentes,
ativas, fora da lixeira e com lembrete futuro. Deverá corrigir agendamentos
ausentes, desatualizados ou órfãos sem duplicar avisos. Reconciliar não deverá
abrir o pedido de permissão nem alterar os dados do domínio.

Se a plataforma falhar ao cancelar um aviso que deixou de ser elegível, o
adaptador deverá preservar seu mapeamento local, marcar o **cancelamento não
confirmado** e tentar novamente na próxima reconciliação. Enquanto o
cancelamento estiver incerto, não deverá iniciar um temporizador de fallback
que possa disparar um segundo aviso. Se a configuração do lembrete já tiver
sido removida, o detalhe da tarefa ainda deverá mostrar esse estado até a
reconciliação confirmar o cancelamento.

## 8. Apresentação do aviso e vencimento

Quando o aplicativo estiver em primeiro plano no instante do lembrete, mostrar
um aviso dentro do app. Quando estiver em segundo plano, usar a notificação do
sistema se houver suporte e permissão. Um mesmo lembrete não deverá produzir
um aviso dentro do app e outro do sistema para o mesmo disparo.

Se o instante já tiver passado ao validar uma nova configuração, a criação ou
edição será rejeitada conforme a especificação 04. Se um lembrete salvo vencer
antes de ser agendado, ou estiver vencido quando a tarefa for reaberta,
restaurada, importada ou reconciliada, não agendar nem emitir aviso atrasado e
mostrar o estado vencido. O app não fará catch-up ao iniciar ou retomar. Uma
notificação já aceita pelo sistema antes do vencimento ainda pode chegar com
atraso dentro das limitações documentadas da plataforma, como Android e
Windows; o aplicativo não deverá criar um novo aviso de recuperação por causa
desse atraso.

## 9. Fora do escopo

Não fazem parte desta especificação:

- implementação de pacotes Flutter, APIs nativas, widgets ou configurações de
  plataforma;
- servidor de aplicação, Push Web ou entrega por backend;
- garantias de horário exato ou entrega quando o app/plataforma não puder
  executar;
- acesso especial do Android a alarmes exatos;
- ações rápidas, repetição de alertas ou adiamento/soneca;
- múltiplos lembretes por tarefa;
- sincronização de agendamentos entre dispositivos.

A escolha de pacote Flutter e das APIs nativas deverá ser registrada em uma
decisão técnica antes da implementação.

## 10. Critérios de aceitação

### CA-01 — Pedir permissão no primeiro lembrete

**Dado** que nenhuma permissão foi solicitada e ainda não há lembretes
configurados, **quando** o usuário inicia a configuração do primeiro lembrete,
**então** o app explica e solicita autorização. Na Web, o pedido começa no
gesto explícito antes dos seletores; nas plataformas nativas, ocorre após
salvar a configuração e antes do agendamento pelo sistema.

### CA-02 — Preservar lembrete após negativa

**Dado** que o usuário nega a permissão, **quando** termina o fluxo, **então**
o lembrete permanece salvo, a tarefa continua utilizável, o estado de
notificação do sistema desativada fica visível e não há novo pedido automático.
Se o app estiver aberto quando o lembrete vencer, ainda poderá mostrar o aviso
dentro do app.

### CA-03 — Atualizar e cancelar agendamento

**Dado** que uma tarefa tem um aviso futuro, **quando** o lembrete é alterado
ou removido, **então** o aviso antigo é substituído ou cancelado e não resta
uma duplicata.

### CA-04 — Conclusão, lixeira e restauração

**Dado** que uma tarefa tem lembrete, **quando** ela é concluída ou enviada à
lixeira, **então** o aviso é cancelado e a configuração permanece; ao reabrir
ou restaurar, somente um lembrete futuro volta a ser agendado.

### CA-05 — Aviso em primeiro plano

**Dado** que o app está aberto quando o lembrete vence, **quando** o evento é
processado, **então** aparece um aviso dentro do app, sem uma segunda
notificação do sistema para o mesmo evento.

### CA-06 — Toque abre o detalhe

**Dado** que o usuário toca em uma notificação do sistema, **quando** o app é
aberto ou retomado, **então** ele navega para o detalhe da tarefa associada.

### CA-07 — Sem ações rápidas

**Dado** que o sistema exibe um lembrete, **então** o aviso contém o título da
tarefa e não oferece ações rápidas para concluir ou adiar.

### CA-08 — Vencimento sem catch-up

**Dado** que o lembrete já passou quando o app inicia, retoma, restaura,
importa ou reconcilia, **então** o app não cria um novo aviso atrasado e mostra
o estado vencido.

### CA-09 — Web e Linux sem execução garantida

**Dado** que a entrega Web ou Linux não pode executar seu temporizador, **quando**
chega o horário, **então** a especificação não promete entrega posterior nem
recuperação automática do aviso.

### CA-10 — Reconciliação idempotente e revogação

**Dado** que a reconciliação é executada repetidamente ou a permissão é
revogada, **quando** o app inicia ou retoma, **então** não são criados avisos
duplicados, a limitação aparece no estado e a configuração do lembrete é
preservada.

Se o cancelamento nativo falhar, o mapeamento continua disponível para a
próxima reconciliação, o estado **Cancelamento não confirmado** fica visível
mesmo se o lembrete foi removido, e nenhum temporizador concorrente é iniciado.

### CA-11 — Android sem alarme exato

**Dado** que um lembrete é configurado no Android, **quando** o adaptador
agenda, **então** utiliza uma opção aproximada sem pedir acesso especial a
alarmes exatos e informa que o sistema pode atrasar a entrega.

### CA-12 — Preparar o caminho de entrega disponível

**Dado** que um lembrete futuro tem autorização para notificações do sistema,
**quando** o adaptador prepara sua entrega, **então** o sistema aceita o
agendamento nas plataformas que oferecem essa capacidade, ou o app arma seu
temporizador local onde o agendamento futuro não existe. O detalhe mostra
“Agendado” e não promete entrega se o processo precisar continuar executando.

### CA-13 — App em segundo plano

**Dado** que o app está em segundo plano quando um lembrete elegível vence,
**quando** a plataforma oferece suporte e a permissão está concedida,
**então** é apresentada uma notificação do sistema com o título da tarefa.

### CA-14 — Não salvar lembrete após cancelar a seleção

**Dado** que ainda não houve pedido de permissão, **quando** o usuário cancela
a seleção do lembrete ou escolhe um horário passado, **então** nenhum novo
lembrete é salvo e a configuração existente permanece inalterada. Nas
plataformas nativas, o app não solicita permissão nesse caso. Na Web, a
permissão pode ter sido solicitada durante a ação explícita antes dos
seletores, para preservar o gesto exigido pelo navegador.

## 11. Documentos relacionados e fontes

- [Prazos, lembretes e recorrência](04-prazos-lembretes-e-recorrencia.md);
- [Persistência Drift e migrações](06-persistencia-drift-e-migracoes.md);
- [Backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md);
- [Validação multiplataforma](10-validacao-multiplataforma.md);
- [ADR-0002: Notificações locais](../decisoes/0002-notificacoes-locais.md);
- [Android Developers — Schedule alarms](https://developer.android.com/develop/background-work/services/alarms);
- [Apple Developer — Scheduling a notification locally](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app);
- [W3C — Push API](https://www.w3.org/TR/push-api/);
- [freedesktop.org — Desktop Notifications Specification](https://specifications.freedesktop.org/notification/1.2/protocol.html);
- [Microsoft Learn — Schedule an app notification](https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/app-notifications-scheduled).
