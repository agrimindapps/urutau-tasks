# Especificação SDD: Prazos, Lembretes e Recorrência

**Status:** proposta para implementação
**Versão:** 1.0
**Escopo:** prazos, lembretes e tarefas recorrentes

## 1. Contexto

Esta especificação detalha prazos, lembretes e recorrência no Urutau Tasks.
Ela deriva do [Escopo do MVP](../04-escopo-do-mvp.md) e complementa as regras
de tarefas, subtarefas, listas e visões inteligentes já definidas nas
especificações anteriores.

As regras são locais e independentes de contas, servidores ou serviços
externos. A entrega de notificações será feita por adaptadores de plataforma
em uma etapa posterior.

## 2. Objetivo

Permitir que o usuário associe datas de conclusão, lembretes locais e padrões
simples de repetição às tarefas, preservando o histórico e mantendo o
calendário previsível mesmo quando uma tarefa for concluída com atraso.

## 3. Terminologia

### 3.1 Prazo

Data de calendário em que a tarefa deveria ser concluída. O prazo não possui
horário e é interpretado no calendário local do dispositivo.

### 3.2 Lembrete

Data e horário locais para alertar o usuário sobre uma tarefa. Uma tarefa pode
ter no máximo um lembrete. O lembrete pode existir com ou sem prazo e pode
ocorrer antes ou depois dele.

### 3.3 Ocorrência

Uma instância concreta de uma tarefa recorrente. Quando uma ocorrência é
concluída, ela permanece no histórico e uma nova ocorrência futura pode ser
criada conforme a regra da série.

### 3.4 Série recorrente

Conjunto de ocorrências geradas por uma mesma regra de recorrência. A série é
ancorada no calendário original e continua ativa até ser cancelada
manualmente.

## 4. Regras de prazo

### RF-01 — Criar e editar prazo

O usuário poderá criar, alterar ou remover o prazo de uma tarefa principal.
O prazo poderá ser hoje, uma data futura ou uma data passada. Uma data passada
não invalida a tarefa: ela será tratada como atrasada pelas visões e filtros
que utilizarem prazo.

O prazo de uma subtarefa não poderá ser configurado, pois subtarefas possuem
somente descrição, estado de conclusão e posição conforme a
[especificação de tarefas e subtarefas](01-tarefas-e-subtarefas.md).

### RF-02 — Calendário local

O prazo será interpretado de acordo com o calendário e o fuso local do
dispositivo. A mudança de fuso não deverá transformar a data armazenada em um
horário UTC diferente; a aplicação deverá continuar tratando o prazo como uma
data de calendário local.

Uma tarefa com prazo deverá aparecer na visão Planejado, desde que esteja
ativa e fora da lixeira, conforme a
[especificação de visões inteligentes e My Day](03-visoes-inteligentes-e-my-day.md).

## 5. Regras de lembrete

### RF-03 — Configurar lembrete

O usuário poderá criar, editar ou remover um lembrete de uma tarefa principal.
O lembrete terá uma única data e horário e utilizará o fuso local do
dispositivo no momento do agendamento.

O lembrete poderá:

- existir sem prazo;
- ocorrer antes do prazo;
- ocorrer depois do prazo;
- ocorrer no mesmo dia ou horário do prazo, quando aplicável.

Subtarefas não poderão possuir lembretes próprios.

### RF-04 — Lembrete no passado

Ao criar ou editar um lembrete para um horário já passado no fuso local, a
operação deverá ser rejeitada e orientar o usuário a escolher um horário
futuro. O valor inválido não deverá ser salvo como um lembrete agendável.

Essa validação não se aplica ao prazo: prazos passados são válidos e
representam tarefas atrasadas.

### RF-05 — Conclusão e reabertura

Ao concluir uma tarefa, a notificação pendente do lembrete deverá ser
cancelada. A configuração do lembrete permanecerá associada à tarefa para
fins de histórico e eventual reabertura.

Ao reabrir uma tarefa:

- um lembrete futuro poderá ser agendado novamente;
- um lembrete que já passou permanecerá registrado como vencido, sem
  notificação imediata;
- a tarefa não deverá ser alterada automaticamente por causa do lembrete.

### RF-06 — Capacidade da plataforma

Quando a plataforma não oferecer suporte à notificação local ou exigir uma
permissão que ainda não foi concedida, a configuração do lembrete deverá ser
preservada e o usuário deverá ser informado sobre a limitação. A tarefa
continuará utilizável sem depender da entrega da notificação.

A especificação não define APIs de notificação nem diferenças detalhadas
entre Web, Android, iOS, Linux, macOS e Windows. Essas regras pertencerão aos
adaptadores de plataforma futuros.

## 6. Regras de recorrência

### RF-07 — Pré-condição

Uma tarefa recorrente deverá possuir um prazo. Não será possível ativar
recorrência em uma tarefa sem prazo.

O prazo define a data-base da série e a recorrência continuará sendo um dado
da tarefa principal. Subtarefas poderão existir na ocorrência atual, mas não
serão copiadas para ocorrências futuras.

### RF-08 — Frequências do MVP

O MVP suportará somente estas frequências fixas:

- **diária:** próxima data do calendário;
- **dias úteis:** segunda a sexta-feira;
- **semanal:** mesmo dia da semana da data-base;
- **mensal:** mesmo dia do mês da data-base;
- **anual:** mesmo mês e dia da data-base.

Não serão suportados intervalos personalizados, como “a cada 2 semanas”,
nem regras posicionais, como “segunda segunda-feira do mês”.

### RF-09 — Datas de calendário

A série será calculada usando o calendário original, sem deslocar a sequência
porque a ocorrência foi concluída depois do prazo.

Se o dia escolhido não existir em determinado mês, a ocorrência mensal usará o
último dia válido daquele mês. Uma recorrência anual de 29 de fevereiro usará
28 de fevereiro nos anos não bissextos.

### RF-10 — Término e cancelamento

As séries não terão data final nem quantidade máxima de ocorrências no MVP.
Continuarão ativas até o usuário cancelar manualmente a recorrência.

Cancelar a recorrência impedirá novas ocorrências, mas não removerá nem
alterará as ocorrências já registradas no histórico.

### RF-11 — Conclusão de ocorrência

Ao concluir uma ocorrência recorrente, a ocorrência concluída deverá:

- permanecer no histórico como uma tarefa principal concluída;
- preservar prazo, lembrete, subtarefas e demais dados daquela ocorrência;
- não alterar os estados das suas subtarefas;
- gerar somente a próxima ocorrência futura da série, quando a recorrência
  ainda estiver ativa.

A nova ocorrência deverá:

- receber o próximo prazo calculado pela regra original;
- começar ativa e não concluída;
- ser criada sem subtarefas;
- herdar a configuração de lembrete, recalculando-a para o novo prazo quando
  o lembrete estiver relacionado temporalmente ao prazo;
- preservar os demais dados da tarefa conforme as regras gerais do produto.

Se uma ou mais datas da série tiverem ficado para trás, não serão criadas
ocorrências retroativas em lote. Será criada apenas a próxima ocorrência que
estiver no futuro em relação ao calendário local.

### RF-12 — Alterar prazo ou regra

Ao editar o prazo ou a regra de recorrência, a alteração valerá a partir da
ocorrência atual e para as ocorrências futuras. Ocorrências concluídas ou
registradas no histórico não serão reescritas.

Se a alteração produzir uma próxima data que já tenha passado, a série deverá
avançar até a próxima data futura conforme a regra, sem criar várias
ocorrências retroativas.

### RF-13 — Lembrete recorrente

O lembrete da ocorrência atual será independente da existência de prazo em
tarefas não recorrentes. Como a recorrência exige prazo, uma nova ocorrência
recorrente que herdar um lembrete deverá preservar sua relação temporal com o
novo prazo e ser agendada no fuso local.

Se a configuração herdada resultar em um horário passado, ela deverá ser
tratada como vencida sem notificação imediata, respeitando as regras de
reabertura e de capacidade da plataforma.

## 7. Integração com visões e subtarefas

- Tarefas ativas com prazo ou lembrete aparecem em Planejado.
- Tarefas recorrentes concluídas permanecem em Concluídas por meio de suas
  ocorrências históricas.
- Itens na lixeira ficam fora das visões normais.
- Subtarefas nunca aparecem como itens independentes nas visões inteligentes.
- A conclusão da tarefa principal não conclui automaticamente subtarefas.
- Uma nova ocorrência recorrente não copia subtarefas da ocorrência anterior.

As visões devem continuar sendo projeções dos dados das tarefas, sem criar
cópias independentes de tarefas ou ocorrências.

## 8. Fora do escopo

Não fazem parte desta especificação:

- intervalos personalizados e regras avançadas de recorrência;
- múltiplos lembretes por tarefa;
- lembretes em subtarefas;
- reconhecimento de datas ou regras em linguagem natural;
- integração com calendários, Outlook, e-mail ou serviços externos;
- sincronização entre dispositivos;
- APIs públicas, tipos de domínio e contratos de persistência;
- consultas Drift, migrações e formato dos dados locais;
- detalhes de implementação das notificações em cada plataforma.

## 9. Critérios de aceitação

### CA-01 — Criar e editar prazo

**Dado** que existe uma tarefa ativa, **quando** o usuário define ou altera um
prazo, **então** a tarefa passa a utilizar a nova data de calendário.

### CA-02 — Aceitar prazo atrasado

**Dado** que o usuário escolhe uma data anterior ao dia atual, **quando** salva
o prazo, **então** a tarefa é salva e pode ser identificada como atrasada.

### CA-03 — Criar lembrete independente

**Dado** que existe uma tarefa sem prazo, **quando** o usuário define um
lembrete futuro, **então** o lembrete é salvo e a tarefa pode aparecer em
Planejado.

### CA-04 — Criar lembrete relacionado ao prazo

**Dado** que uma tarefa possui prazo, **quando** o usuário define um lembrete
antes ou depois dele, **então** a relação escolhida é aceita sem alterar o
prazo.

### CA-05 — Rejeitar lembrete passado

**Dado** que o horário escolhido já passou no fuso local, **quando** o usuário
tenta salvar o lembrete, **então** a operação é rejeitada e o usuário é
orientado a escolher outro horário.

### CA-06 — Cancelar notificação ao concluir

**Dado** que uma tarefa possui lembrete futuro agendado, **quando** o usuário
conclui a tarefa, **então** a notificação pendente é cancelada e a configuração
é preservada.

### CA-07 — Reabrir tarefa com lembrete futuro

**Dado** que uma tarefa concluída possui lembrete futuro, **quando** o usuário a
reabre, **então** o lembrete pode ser agendado novamente.

### CA-08 — Reabrir tarefa com lembrete vencido

**Dado** que uma tarefa concluída possui lembrete já vencido, **quando** o
usuário a reabre, **então** ela permanece sem alerta imediato e mantém o
lembrete registrado.

### CA-09 — Criar recorrência nas frequências do MVP

**Dado** que uma tarefa possui prazo, **quando** o usuário escolhe diária, dias
úteis, semanal, mensal ou anual, **então** a série é criada conforme a
frequência escolhida.

### CA-10 — Calcular datas mensais e anuais

**Dado** que uma série usa uma data de calendário que não existe no próximo mês
ou é 29 de fevereiro, **quando** a próxima ocorrência é calculada, **então** o
sistema usa o último dia mensal válido ou 28 de fevereiro em ano não
bissexto, respectivamente.

### CA-11 — Concluir ocorrência recorrente

**Dado** que uma ocorrência recorrente está ativa, **quando** o usuário a
conclui, **então** ela permanece no histórico e somente a próxima ocorrência
futura é criada.

### CA-12 — Não copiar subtarefas

**Dado** que a ocorrência concluída possui subtarefas, **quando** a próxima
ocorrência é criada, **então** a nova ocorrência não possui essas subtarefas.

### CA-13 — Herdar lembrete

**Dado** que a ocorrência concluída possui configuração de lembrete, **quando**
a próxima ocorrência é criada, **então** ela herda a configuração, recalculada
para o novo prazo quando necessário.

### CA-14 — Preservar histórico

**Dado** que uma ocorrência recorrente foi concluída, **quando** a próxima
ocorrência é gerada ou a série é editada, **então** a ocorrência anterior e
seus dados históricos permanecem intactos.

### CA-15 — Não recuperar ocorrências perdidas

**Dado** que várias datas da série ficaram para trás, **quando** o aplicativo
calcula a continuidade da recorrência, **então** não são criadas ocorrências
retroativas em lote; somente a próxima data futura é considerada.

### CA-16 — Alterar série a partir da ocorrência atual

**Dado** que existe histórico e uma ocorrência atual recorrente, **quando** o
usuário altera prazo ou regra, **então** a alteração afeta a ocorrência atual e
as futuras, sem reescrever o histórico.

### CA-17 — Cancelar manualmente a série

**Dado** que uma tarefa possui recorrência ativa, **quando** o usuário cancela a
recorrência, **então** nenhuma nova ocorrência é gerada e as anteriores
permanecem disponíveis no histórico.

### CA-18 — Recorrência exige prazo

**Dado** que uma tarefa não possui prazo, **quando** o usuário tenta ativar
recorrência, **então** a operação é rejeitada e a tarefa permanece não
recorrente.

## 10. Dependências e próximos documentos

Esta especificação deverá ser usada como entrada para:

- especificação de notificações por plataforma;
- especificação de persistência Drift e migrações;
- especificação de backup, restauração e formato aberto;
- implementação das visões Planejado e Concluídas.

Prazos, lembretes e recorrência devem continuar sendo dados da tarefa e de
suas ocorrências, sem criar estados paralelos nas visões inteligentes.
