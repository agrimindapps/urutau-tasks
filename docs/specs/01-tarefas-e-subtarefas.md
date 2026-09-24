# Especificação SDD: Tarefas e Subtarefas

**Status:** proposta para implementação
**Versão:** 1.0
**Escopo:** ciclo de vida de tarefas e subtarefas

## 1. Contexto

Esta especificação detalha a primeira unidade funcional do Urutau Tasks. Ela
deriva do [Escopo do MVP](../04-escopo-do-mvp.md) e define o comportamento de
tarefas e subtarefas antes de qualquer implementação.

O documento não define o esquema do banco, APIs públicas, widgets ou detalhes
de uma plataforma específica. Listas, grupos, categorias, tags, My Day,
lembretes e persistência serão integrados por especificações próprias.

## 2. Objetivo

Permitir que o usuário crie e gerencie tarefas pessoais, decomponha uma tarefa
em etapas menores, acompanhe o progresso e preserve seu histórico sem perder a
hierarquia ou os estados dos itens.

## 3. Terminologia

### 3.1 Tarefa principal

Item de trabalho independente que pode pertencer a uma lista e receber os
demais dados de contexto definidos pelo MVP, como prioridade, prazo,
lembrete, recorrência, categoria, tags e nota.

### 3.2 Subtarefa

Etapa interna de uma tarefa principal. Uma subtarefa existe apenas para
destrinchar o trabalho e acompanhar seu progresso; ela não é uma tarefa
independente do ponto de vista do produto.

### 3.3 Ocorrência recorrente

Nova tarefa criada a partir da conclusão de uma tarefa que possui uma regra de
recorrência. A ocorrência anterior permanece preservada para consulta no
histórico.

## 4. Requisitos funcionais

### RF-01 — Título obrigatório

Toda tarefa e subtarefa deverá possuir um título não vazio após a remoção de
espaços nas extremidades. Títulos compostos apenas por espaços deverão ser
rejeitados.

O título poderá ser editado enquanto o item estiver ativo ou concluído. Itens
na lixeira não poderão ser editados até serem restaurados.

### RF-02 — Estados da tarefa

Uma tarefa principal deverá possuir um dos seguintes estados:

- **Ativa:** pode ser editada, organizada e concluída;
- **Concluída:** representa uma tarefa finalizada e permanece disponível no
  histórico;
- **Na lixeira:** foi excluída logicamente e não aparece nas visões normais.

As transições permitidas são:

| Estado atual | Ação | Próximo estado |
| --- | --- | --- |
| inexistente | criar | Ativa |
| Ativa | concluir | Concluída |
| Concluída | reabrir | Ativa |
| Ativa ou Concluída | excluir | Na lixeira |
| Na lixeira | restaurar | Estado anterior |

A exclusão definitiva de itens na lixeira não faz parte desta especificação.

### RF-03 — Criação e edição

O usuário deverá poder criar uma tarefa com o título obrigatório e depois
adicionar ou alterar seus dados de contexto conforme as especificações de
listas, prioridades, prazos, lembretes, recorrência, categorias, tags e notas.

Uma edição válida deverá preservar a identidade da tarefa, sua relação com
subtarefas e seu histórico de conclusão.

### RF-04 — Conclusão e reabertura

O usuário poderá concluir uma tarefa ativa e reabrir uma tarefa concluída.

Concluir ou reabrir uma tarefa principal não deverá alterar automaticamente o
estado de nenhuma de suas subtarefas. Subtarefas concluídas continuarão
concluídas e subtarefas pendentes continuarão pendentes.

### RF-05 — Criação de subtarefas

O usuário poderá adicionar subtarefas a uma tarefa principal ativa ou
concluída.

Uma subtarefa deverá:

- possuir título obrigatório;
- pertencer a uma única tarefa principal;
- possuir apenas título, estado de conclusão e posição dentro da tarefa;
- poder ser editada, concluída e reaberta;
- não possuir subtarefas próprias.

Não será permitida hierarquia com mais de um nível. Uma subtarefa não poderá
ser convertida em tarefa principal por esta especificação.

### RF-06 — Ordenação das subtarefas

As subtarefas deverão manter uma ordem definida pelo usuário. O usuário
deverá poder mover uma subtarefa para outra posição dentro da mesma tarefa
principal.

A reordenação não deverá alterar o estado de conclusão, o título ou os dados
da tarefa principal.

### RF-07 — Remoção de subtarefa

O usuário poderá remover uma subtarefa individualmente da tarefa principal.

Essa remoção:

- retirará a subtarefa da tarefa principal;
- fará com que ela deixe de compor o progresso;
- não criará uma entrada independente na lixeira;
- não alterará o estado ou os dados das demais subtarefas.

### RF-08 — Progresso

Quando uma tarefa possuir subtarefas, sua interface deverá exibir a proporção
de subtarefas concluídas em relação ao total, no formato `concluídas/total`.

Uma tarefa sem subtarefas não deverá exibir um progresso artificial. A
conclusão da tarefa principal não poderá ser bloqueada por subtarefas
pendentes.

### RF-09 — Exclusão da hierarquia

Quando uma tarefa principal for excluída, ela e todas as suas subtarefas
deverão ser movidas juntas para a lixeira.

Ao mover a hierarquia para a lixeira, deverão ser preservados:

- a relação entre tarefa principal e subtarefas;
- a ordem das subtarefas;
- os estados de conclusão;
- os títulos e demais dados existentes;
- a posição da tarefa na organização de origem.

Subtarefas não deverão continuar aparecendo em listas ou visões normais
enquanto a tarefa principal estiver na lixeira.

### RF-10 — Restauração da hierarquia

Ao restaurar uma tarefa principal, a tarefa e suas subtarefas deverão ser
restauradas juntas.

A restauração deverá recuperar a hierarquia, a posição e os estados anteriores
à exclusão. Uma tarefa que estava concluída antes da exclusão deverá voltar a
concluída; uma tarefa ativa deverá voltar a ativa.

### RF-11 — Recorrência

Quando uma tarefa recorrente for concluída, a ocorrência concluída deverá ser
preservada e uma nova ocorrência deverá ser criada de acordo com a regra de
recorrência definida em sua especificação própria.

A nova ocorrência não deverá copiar as subtarefas da ocorrência anterior. Ela
deverá nascer sem etapas internas, enquanto a ocorrência concluída preservará
suas próprias subtarefas e estados no histórico.

## 5. Regras de visibilidade

- Tarefas principais ativas ou concluídas poderão aparecer nas listas e
  visões inteligentes conforme suas regras próprias.
- Subtarefas não aparecerão como itens independentes em listas ou visões
  inteligentes.
- Subtarefas serão exibidas dentro da tarefa principal e poderão contribuir
  para seu indicador de progresso.
- Itens na lixeira ficarão fora das visões normais.
- A conclusão da tarefa principal não removerá nem concluirá suas subtarefas.

## 6. Fora do escopo

Não fazem parte desta especificação:

- listas e grupos;
- categorias e tags;
- My Day e visões inteligentes;
- prazos e lembretes;
- regras detalhadas de recorrência;
- persistência Drift e migrações;
- backup e importação ou exportação;
- sincronização;
- anexos;
- colaboração entre usuários;
- exclusão definitiva da lixeira;
- subtarefas aninhadas;
- subtarefas com metadados próprios.

## 7. Critérios de aceitação

### CA-01 — Criar tarefa válida

**Dado** que o usuário está criando uma tarefa
**Quando** informa um título com conteúdo
**Então** a tarefa é criada no estado Ativa.

### CA-02 — Rejeitar título inválido

**Dado** que o usuário está criando ou editando uma tarefa
**Quando** o título está vazio ou contém apenas espaços
**Então** a operação é rejeitada e a tarefa não é salva com título inválido.

### CA-03 — Gerenciar subtarefas

**Dado** que existe uma tarefa principal
**Quando** o usuário adiciona, edita, conclui e reabre uma subtarefa
**Então** a subtarefa permanece vinculada à tarefa principal e seu estado é
atualizado sem alterar o estado da tarefa principal.

### CA-04 — Reordenar subtarefas

**Dado** que uma tarefa possui várias subtarefas
**Quando** o usuário move uma subtarefa
**Então** a nova ordem é preservada sem alterar títulos ou estados.

### CA-05 — Remover subtarefa

**Dado** que uma tarefa possui uma subtarefa
**Quando** o usuário a remove
**Então** ela deixa de existir dentro da tarefa e deixa de compor o progresso,
sem afetar as demais subtarefas.

### CA-06 — Calcular progresso

**Dado** que uma tarefa possui cinco subtarefas, das quais duas estão
concluídas
**Quando** o usuário visualiza a tarefa
**Então** o progresso exibido é `2/5`.

### CA-07 — Concluir com pendências

**Dado** que uma tarefa possui subtarefas pendentes
**Quando** o usuário conclui a tarefa principal
**Então** a tarefa fica Concluída e as subtarefas permanecem pendentes.

### CA-08 — Preservar estados ao reabrir

**Dado** que uma tarefa concluída possui subtarefas concluídas e pendentes
**Quando** o usuário reabre a tarefa principal
**Então** a tarefa fica Ativa e os estados das subtarefas permanecem iguais.

### CA-09 — Mover hierarquia para a lixeira

**Dado** que uma tarefa possui subtarefas
**Quando** o usuário exclui a tarefa principal
**Então** a tarefa e todas as subtarefas são movidas juntas para a lixeira,
mantendo sua hierarquia, ordem e estados.

### CA-10 — Restaurar hierarquia

**Dado** que uma hierarquia está na lixeira
**Quando** o usuário restaura a tarefa principal
**Então** a tarefa e as subtarefas voltam juntas à organização original com os
mesmos estados e posições anteriores.

### CA-11 — Criar ocorrência recorrente

**Dado** que uma tarefa recorrente possui subtarefas
**Quando** o usuário conclui a ocorrência
**Então** a ocorrência concluída permanece no histórico e a próxima ocorrência
é criada sem subtarefas.

### CA-12 — Preservar histórico recorrente

**Dado** que uma nova ocorrência recorrente foi criada
**Quando** o usuário consulta a ocorrência anterior
**Então** a ocorrência anterior mantém seu estado concluído, seus dados e suas
subtarefas originais.

## 8. Dependências e próximos documentos

Esta especificação deverá ser usada como entrada para:

- especificação de listas, grupos, categorias e tags;
- especificação de visões inteligentes e My Day;
- especificação de recorrência, prazos e lembretes;
- especificação de busca e filtros;
- [especificação de persistência Drift e migrações](06-persistencia-drift-e-migracoes.md);
- [especificação de backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md);

Nenhuma decisão de armazenamento ou integração poderá contradizer as regras
de identidade, hierarquia, estado e preservação definidas aqui sem uma nova
decisão documentada.
