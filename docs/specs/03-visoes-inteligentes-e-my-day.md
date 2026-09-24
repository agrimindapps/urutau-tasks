# Especificação SDD: Visões Inteligentes e My Day

**Status:** proposta para implementação
**Versão:** 1.0
**Escopo:** visões derivadas e planejamento diário

## 1. Contexto

Esta especificação detalha as visões inteligentes e o planejamento diário do
Urutau Tasks. Ela deriva do [Escopo do MVP](../04-escopo-do-mvp.md) e utiliza
as regras de tarefas, subtarefas, listas, grupos, categorias e tags já
definidas nas especificações anteriores.

O Microsoft To Do é uma referência de produto para o conceito de My Day e suas
visões pessoais, mas as regras desta especificação são próprias do Urutau
Tasks e devem respeitar o funcionamento local-first.

## 2. Objetivo

Permitir que o usuário veja rapidamente o trabalho relevante, planeje seu foco
diário e consulte tarefas por critérios derivados, sem criar cópias ou alterar
os dados originais das tarefas.

## 3. Terminologia

### 3.1 Visão inteligente

Visão calculada a partir das tarefas existentes. Não possui tarefas próprias e
não duplica dados: uma mesma tarefa poderá aparecer em várias visões quando
atender aos critérios de cada uma.

### 3.2 My Day

Visão de foco diário que registra quais tarefas ativas o usuário escolheu para
trabalhar no dia corrente. O foco diário é independente da lista principal,
categoria, tags, prioridade e prazo da tarefa.

### 3.3 Rollover

Processamento da virada do dia, realizado à meia-noite conforme o fuso horário
local do dispositivo. O rollover encerra o foco diário anterior e prepara o
My Day para a nova data.

## 4. Regras comuns das visões

- Ao iniciar o aplicativo, My Day será a visão inicial. O usuário poderá
  navegar para qualquer outra visão sem alterar os dados das tarefas.
- Todas as visões normais exibirão apenas tarefas principais.
- Subtarefas nunca aparecerão como itens independentes.
- Itens na lixeira ficarão fora de todas as visões normais.
- As visões serão derivadas dos dados existentes, sem duplicação.
- Alterações de estado ou de dados deverão atualizar as visões afetadas.
- Uma tarefa poderá aparecer simultaneamente em mais de uma visão quando
  atender a seus critérios.
- Tarefas sem lista poderão aparecer nas visões que não dependem de lista.
- As visões não poderão alterar automaticamente prazo, prioridade, lista,
  categoria, tags, recorrência ou notas da tarefa.
- Se a criação for oferecida em Importante ou Planejado, a tarefa recém-criada
  deverá continuar acessível em seu detalhe para que o usuário defina a
  prioridade, o prazo ou o lembrete que a fará corresponder à visão. A criação
  não preencherá esses dados automaticamente.

## 5. Visões inteligentes

### RF-01 — Todas

A visão Todas deverá exibir todas as tarefas principais ativas,
independentemente da lista, grupo, categoria, tags, prioridade, prazo ou
recorrência.

Tarefas sem lista deverão aparecer em Todas. Tarefas concluídas, na lixeira e
subtarefas não deverão aparecer nessa visão.

### RF-02 — Importante

A visão Importante deverá exibir tarefas principais ativas com prioridade alta
ou urgente.

Tarefas com prioridade baixa ou média não aparecerão nessa visão. Tarefas
concluídas e itens na lixeira também ficarão fora dela, mesmo que mantenham uma
prioridade alta ou urgente.

### RF-03 — Planejado

A visão Planejado deverá exibir todas as tarefas principais ativas que possuam
prazo ou lembrete configurado.

Tarefas atrasadas deverão permanecer em Planejado até serem concluídas,
reabertas ou terem seu prazo e lembrete removidos. Uma tarefa que possua prazo
e lembrete deverá aparecer uma única vez.

Tarefas sem prazo e sem lembrete, concluídas, na lixeira e subtarefas não
aparecerão nessa visão.

### RF-04 — Concluídas

A visão Concluídas deverá exibir tarefas principais concluídas, incluindo
ocorrências recorrentes anteriores preservadas no histórico.

Subtarefas concluídas não aparecerão como itens independentes. Elas continuarão
visíveis dentro da tarefa principal quando a tarefa for aberta.

### RF-05 — Exclusão e restauração

Quando uma tarefa for enviada para a lixeira, deverá deixar imediatamente todas
as visões normais, incluindo My Day.

Ao remover a entrada do My Day por conclusão ou envio à lixeira, a ordem
relativa das demais entradas do mesmo dia deverá ser preservada e as posições
deverão ser renumeradas em uma transação.

Quando uma tarefa for restaurada, deverá voltar às visões correspondentes ao
seu estado e aos seus dados atuais. Uma tarefa restaurada como concluída deverá
aparecer em Concluídas; uma tarefa restaurada como ativa poderá aparecer em
Todas, Importante ou Planejado conforme seus critérios.

## 6. My Day

### RF-06 — Adicionar tarefa ao My Day

O usuário poderá adicionar ao My Day qualquer tarefa principal ativa, esteja
ela atribuída a uma lista ou na inbox implícita.

Adicionar uma tarefa ao My Day deverá apenas associá-la ao foco do dia. A ação
não deverá alterar prazo, prioridade, lista, grupo, categoria, tags,
recorrência, notas ou subtarefas.

Uma tarefa não poderá ser adicionada ao My Day enquanto estiver concluída ou
na lixeira.

### RF-07 — Ordem manual do My Day

O usuário deverá poder reordenar manualmente as tarefas dentro do My Day. Essa
ordem será específica do foco diário e não deverá alterar a ordem da lista de
origem.

A ordem definida deverá permanecer após fechar e reabrir o aplicativo, até que
o usuário a altere ou ocorra o rollover.

### RF-08 — Remover tarefa do My Day

O usuário poderá remover uma tarefa do My Day sem excluí-la, concluí-la ou
alterar sua lista de origem.

Após a remoção, a tarefa continuará disponível nas visões correspondentes ao
seu estado e aos seus dados.

### RF-09 — Concluir tarefa no My Day

Quando uma tarefa do My Day for concluída, ela deverá deixar imediatamente o
foco diário e aparecer em Concluídas.

Essa transição não deverá concluir ou alterar automaticamente suas subtarefas.
Subtarefas concluídas e pendentes deverão manter seus estados.

A remoção da entrada deverá preservar a ordem das demais tarefas do dia e
compactar suas posições.

Uma tarefa concluída não poderá ser adicionada novamente ao My Day.

### RF-10 — Rollover diário

O rollover deverá ocorrer na meia-noite do fuso horário local do dispositivo.

Durante o rollover:

- tarefas não concluídas serão removidas do My Day;
- tarefas concluídas já não estarão no My Day e permanecerão em Concluídas;
- tarefas não concluídas manterão sua lista original;
- tarefas não concluídas sem lista retornarão à inbox implícita;
- prazo, lembrete, prioridade, classificação, recorrência, notas e subtarefas
  não serão alterados;
- a ordem do My Day anterior não será transferida automaticamente para o novo
  dia.

O processamento deverá ser idempotente: reabrir o aplicativo ou repetir a
verificação da mesma data não poderá remover ou duplicar tarefas novamente.

## 7. Ordenação

Os cartões de tarefas em My Day, nas visões inteligentes e nas listas deverão
mostrar o prazo e o horário do lembrete quando configurados, além da
prioridade quando diferente de nenhuma. Tarefas ativas com prazo anterior à
data local atual deverão identificar visualmente que estão atrasadas. A
formatação de datas e horários seguirá a região do dispositivo.

Fora da lista de origem, o cartão deverá identificar a lista da tarefa e seu
grupo quando houver. Tarefas sem lista deverão ser identificadas como sem
lista. Essa informação será contextual e não modificará a organização da
tarefa.

### RF-11 — Ordenação das visões inteligentes

As visões Todas, Importante, Planejado e Concluídas utilizarão a seguinte
ordem padrão:

1. tarefas atrasadas;
2. tarefas vencendo hoje;
3. tarefas com próximos prazos;
4. prioridade, da mais alta para a mais baixa;
5. ordem de origem como desempate final.

Quando uma tarefa não possuir prazo, ela deverá ser posicionada depois das
tarefas com prazo, respeitando sua prioridade e a ordem de origem.

A visão Concluídas poderá utilizar a data de conclusão como informação de
ordenação dentro da mesma regra, mantendo as tarefas concluídas mais recentes
em posição de destaque.

### RF-12 — Ordenação do My Day

O My Day utilizará exclusivamente a ordem manual definida pelo usuário. A
ordenação por prazo ou prioridade não poderá substituir essa escolha
automaticamente.

## 8. Atualização das visões

As visões deverão refletir as mudanças das tarefas sem exigir duplicação ou
edição separada de um item da visão.

Exemplos:

- concluir uma tarefa remove-a de Todas, Importante e Planejado e adiciona-a a
  Concluídas;
- reabrir uma tarefa remove-a de Concluídas e pode recolocá-la em Todas,
  Importante e Planejado;
- alterar prioridade pode adicionar ou remover a tarefa de Importante;
- adicionar ou remover prazo ou lembrete pode adicionar ou remover a tarefa de
  Planejado;
- mover uma tarefa de lista não altera sua presença nas visões derivadas;
- remover uma tarefa do My Day não altera as demais visões;
- mover uma tarefa para a lixeira remove-a de todas as visões normais.

## 9. Fora do escopo

Não fazem parte desta especificação:

- sugestões automáticas de tarefas;
- reconhecimento de datas, lembretes ou recorrência em linguagem natural;
- integração com calendário, Outlook, e-mail ou serviços externos;
- sincronização entre dispositivos;
- regras detalhadas de recorrência;
- persistência Drift e consultas específicas;
- notificações e limitações nativas de cada plataforma;
- busca e filtros avançados;
- subtarefas exibidas como resultados independentes.

## 10. Critérios de aceitação

### CA-01 — Visualizar todas as tarefas ativas

**Dado** que existem tarefas ativas em várias listas e na inbox implícita
**Quando** o usuário abre Todas
**Então** todas as tarefas principais ativas são exibidas.

### CA-02 — Localizar tarefa sem lista

**Dado** que existe uma tarefa sem lista
**Quando** o usuário abre Todas ou pesquisa pelo título
**Então** a tarefa é encontrada sem precisar ser atribuída a uma lista.

### CA-03 — Filtrar importantes

**Dado** que existem tarefas com prioridades baixa, média, alta e urgente
**Quando** o usuário abre Importante
**Então** apenas as tarefas ativas alta e urgente são exibidas.

### CA-04 — Incluir tarefas planejadas

**Dado** que existem tarefas com prazo, lembrete e ambos
**Quando** o usuário abre Planejado
**Então** cada tarefa aparece uma única vez.

### CA-05 — Incluir tarefa atrasada

**Dado** que uma tarefa ativa possui prazo no passado
**Quando** o usuário abre Planejado
**Então** a tarefa atrasada é exibida.

### CA-06 — Evitar duplicação

**Dado** que uma tarefa atende aos critérios de várias visões
**Quando** o usuário navega entre as visões
**Então** cada visão referencia a mesma tarefa sem criar cópias.

### CA-07 — Excluir concluídas de visões de trabalho

**Dado** que uma tarefa importante e planejada foi concluída
**Quando** o usuário abre Importante ou Planejado
**Então** a tarefa não é exibida e aparece em Concluídas.

### CA-08 — Excluir itens da lixeira

**Dado** que uma tarefa atende ao critério de uma visão e é movida para a
lixeira
**Quando** o usuário abre qualquer visão normal
**Então** a tarefa não é exibida.

### CA-09 — Adicionar tarefa ativa ao My Day

**Dado** que existe uma tarefa ativa com ou sem lista
**Quando** o usuário a adiciona ao My Day
**Então** ela aparece no foco do dia sem alterar seus dados de origem.

### CA-10 — Preservar prazo ao adicionar ao My Day

**Dado** que uma tarefa possui prazo futuro
**Quando** o usuário a adiciona ao My Day
**Então** o prazo permanece inalterado.

### CA-11 — Reordenar foco diário

**Dado** que o My Day possui várias tarefas
**Quando** o usuário altera sua ordem e reabre o aplicativo no mesmo dia
**Então** a ordem manual é preservada.

### CA-12 — Remover do My Day

**Dado** que uma tarefa ativa está no My Day
**Quando** o usuário a remove do foco diário
**Então** ela deixa o My Day e permanece na lista de origem ou na inbox.

### CA-13 — Concluir no My Day

**Dado** que uma tarefa está no My Day
**Quando** o usuário a conclui
**Então** ela sai do My Day, aparece em Concluídas e não altera suas
subtarefas.

### CA-14 — Executar rollover

**Dado** que o My Day possui tarefas concluídas e não concluídas
**Quando** chega a meia-noite no fuso local
**Então** as tarefas não concluídas retornam à origem e as concluídas
permanecem fora do My Day.

### CA-15 — Rollover da inbox implícita

**Dado** que uma tarefa sem lista está no My Day e permanece pendente
**Quando** ocorre o rollover
**Então** ela retorna à inbox implícita sem receber uma lista automática.

### CA-16 — Manter subtarefas internas

**Dado** que uma tarefa possui subtarefas
**Quando** ela aparece em uma visão inteligente ou no My Day
**Então** apenas a tarefa principal aparece como item, com suas subtarefas
acessíveis em seu detalhe.

### CA-17 — Criar tarefa a partir de visão derivada

**Dado** que o usuário inicia a criação em Importante ou Planejado, **quando**
uma nova tarefa ainda não atende ao critério da visão, **então** o app abre seu
detalhe para manter a tarefa acessível e permitir completar os dados, sem
atribuir prioridade, prazo ou lembrete implicitamente.

### CA-18 — Preservar a ordem ao concluir ou excluir do My Day

**Dado** que há várias tarefas no My Day, **quando** uma delas é concluída ou
enviada à lixeira, **então** as demais mantêm a ordem relativa e suas posições
são renumeradas sem lacunas.

### CA-19 — Abrir o aplicativo em My Day

**Dado** que existem tarefas adicionadas ao foco da data local atual
**Quando** o usuário inicia o aplicativo
**Então** My Day é a visão inicial e exibe essas tarefas na ordem manual
definida para o dia.

### CA-20 — Identificar prazo, lembrete e prioridade no cartão

**Dado** que uma tarefa em My Day, numa visão inteligente ou numa lista possui
prazo, lembrete ou prioridade
**Quando** o usuário visualiza o cartão da tarefa
**Então** os dados configurados são mostrados com formato regional, e um prazo
passado de tarefa ativa é identificado como atrasado.

### CA-21 — Identificar a origem da tarefa em visões agregadas

**Dado** que uma tarefa sem lista ou atribuída a uma lista dentro de um grupo
aparece em My Day ou numa visão inteligente
**Quando** o usuário visualiza o cartão
**Então** ele identifica a lista e o grupo de origem, ou que a tarefa está sem
lista, sem alterar sua organização.

### CA-22 — Atualizar o estado de atraso pela data local

**Dado** que uma tarefa ativa possui prazo para hoje e está visível numa lista
**Quando** chega a meia-noite local ou o aplicativo retorna do segundo plano
em outro dia
**Então** o cartão atualiza a indicação de atraso sem exigir edição da tarefa.

## 11. Dependências e próximos documentos

Esta especificação deverá ser usada como entrada para:

- [especificação de prazos, lembretes e recorrência](04-prazos-lembretes-e-recorrencia.md);
- [especificação de busca e filtros](05-busca-e-filtros.md);
- [especificação de persistência Drift e migrações](06-persistencia-drift-e-migracoes.md);
- [especificação de notificações por plataforma](08-notificacoes-por-plataforma.md);
- [especificação de backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md).

As visões deverão continuar sendo projeções dos dados das tarefas. Nenhuma
implementação poderá criar um segundo estado independente para uma tarefa sem
uma nova decisão documentada.
