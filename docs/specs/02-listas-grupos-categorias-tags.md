# Especificação SDD: Listas, Grupos, Categorias e Tags

**Status:** proposta para implementação
**Versão:** 1.0
**Escopo:** organização e classificação de tarefas

## 1. Contexto

Esta especificação detalha a organização das tarefas do Urutau Tasks. Ela
deriva do [Escopo do MVP](../04-escopo-do-mvp.md) e complementa a
[especificação de tarefas e subtarefas](01-tarefas-e-subtarefas.md).

O documento define listas, grupos, categorias e tags como mecanismos distintos.
Não define o esquema do banco, widgets, APIs públicas ou os comportamentos
completos de My Day e das visões inteligentes.

## 2. Objetivo

Permitir que o usuário organize tarefas em listas e grupos, classifique-as com
uma categoria principal e várias tags, e altere essa organização sem perder a
identidade, a hierarquia ou os dados das tarefas.

## 3. Terminologia

### 3.1 Lista

Contêiner principal de tarefas. Uma tarefa principal poderá pertencer a uma
lista ou permanecer temporariamente sem lista.

### 3.2 Grupo

Contêiner opcional de listas. Um grupo organiza listas por área, projeto ou
contexto, mas não contém tarefas diretamente.

### 3.3 Categoria

Classificação principal e opcional de uma tarefa. Uma tarefa poderá possuir no
máximo uma categoria.

### 3.4 Tag

Marcador livre e reutilizável para cruzar tarefas de diferentes listas e
categorias. Uma tarefa poderá possuir várias tags.

### 3.5 Inbox implícita

Estado temporário de uma tarefa que ainda não foi atribuída a uma lista. Não é
uma lista de sistema e não poderá ser agrupada ou renomeada.

## 4. Requisitos funcionais

### RF-01 — Nomes válidos

Listas, grupos, categorias e tags deverão possuir um nome não vazio após a
remoção de espaços nas extremidades. Nomes compostos apenas por espaços
deverão ser rejeitados.

Os nomes deverão ser únicos globalmente dentro de seu próprio tipo. Não poderá
existir mais de uma lista com o mesmo nome, mais de um grupo com o mesmo nome,
mais de uma categoria com o mesmo nome ou mais de uma tag equivalente.

### RF-02 — Listas personalizadas

O usuário deverá poder:

- criar uma lista;
- renomear uma lista;
- reordenar listas manualmente;
- mover uma lista para um grupo ou removê-la de um grupo;
- excluir uma lista vazia;
- mover tarefas para outra lista.

Não haverá uma lista padrão protegida. O aplicativo não deverá criar uma lista
de sistema chamada “Tarefas” automaticamente.

Uma lista vazia continuará sendo válida e poderá ser mantida para organização
futura.

### RF-03 — Tarefas sem lista

Uma tarefa poderá ser criada sem lista e permanecerá na inbox implícita até que
o usuário a organize.

Uma tarefa sem lista:

- aparecerá na visão Todas;
- poderá ser encontrada pela busca;
- poderá ser encontrada pelo filtro “Sem lista”;
- poderá receber categoria, tags e demais dados permitidos para tarefas;
- não poderá pertencer a um grupo;
- poderá ser atribuída posteriormente a uma lista existente.

A ausência temporária de lista não deverá impedir o uso dos demais recursos da
tarefa. A integração com My Day e visões inteligentes será definida em suas
especificações próprias.

### RF-04 — Grupos simples

O usuário poderá criar, renomear, reordenar e excluir grupos.

Um grupo:

- poderá conter várias listas;
- poderá não conter nenhuma lista;
- poderá ter uma ordem manual de exibição;
- não poderá pertencer a outro grupo;
- não poderá conter tarefas diretamente.

Uma lista poderá pertencer a no máximo um grupo. Listas também poderão ficar
sem grupo.

### RF-05 — Exclusão de grupo

Ao excluir um grupo, suas listas deverão permanecer intactas e passarão a não
pertencer a nenhum grupo.

A exclusão do grupo não deverá alterar tarefas, subtarefas, categorias, tags ou
qualquer outro dado das listas que estavam agrupadas.

### RF-06 — Exclusão de lista com tarefas

Uma lista vazia poderá ser excluída diretamente.

Uma lista que possua tarefas principais não poderá ser excluída sem que o
usuário escolha outra lista existente como destino. A própria lista excluída
não poderá ser escolhida como destino.

Ao confirmar a operação:

- todas as tarefas principais da lista serão movidas para o destino;
- suas subtarefas acompanharão a tarefa principal;
- estados, ordem, categorias, tags e demais dados serão preservados;
- a lista de origem será removida;
- o grupo de origem não será removido automaticamente.

Se não existir outra lista disponível, a exclusão de uma lista com tarefas
deverá ser bloqueada até que o usuário mova ou remova suas tarefas.

### RF-07 — Movimentação de tarefas

O usuário poderá mover uma tarefa principal para qualquer lista existente.

A movimentação deverá transferir a hierarquia inteira da tarefa, sem criar uma
cópia e sem alterar:

- a identidade da tarefa;
- a relação com suas subtarefas;
- os estados de conclusão;
- a ordem das subtarefas;
- a categoria;
- as tags;
- prazo, lembrete, recorrência e notas.

Subtarefas continuarão sem lista própria; sua lista efetiva será determinada
pela tarefa principal.

### RF-08 — Categorias globais

Categorias serão globais e poderão ser usadas por tarefas de qualquer lista.

O usuário poderá:

- criar uma categoria durante a edição de uma tarefa;
- atribuir uma categoria a uma tarefa;
- substituir ou remover a categoria da tarefa;
- renomear uma categoria;
- excluir uma categoria.

Uma tarefa poderá ter zero ou uma categoria. A exclusão de uma categoria
deverá apenas desvinculá-la das tarefas associadas; as tarefas não serão
excluídas nem alteradas em outros campos.

### RF-09 — Tags globais

Tags serão globais e poderão ser usadas por tarefas de qualquer lista ou
categoria.

O usuário poderá:

- criar uma tag durante a edição de uma tarefa;
- adicionar várias tags a uma tarefa;
- remover uma tag de uma tarefa;
- renomear uma tag;
- excluir uma tag.

Tags deverão ser normalizadas para comparação: espaços nas extremidades serão
removidos e diferenças entre maiúsculas e minúsculas não criarão tags distintas.

A exclusão de uma tag deverá apenas removê-la das tarefas associadas; os demais
dados das tarefas permanecerão intactos.

### RF-10 — Ordenação

O usuário deverá poder definir manualmente a ordem de listas e grupos. A
ordenação deverá ser preservada entre sessões e não deverá depender da ordem de
criação ou do nome.

As opções de ordenação de tarefas por prioridade, prazo ou criação serão
definidas em especificação própria, sem substituir a ordem estrutural das
listas e grupos.

## 5. Regras de consistência

- Uma tarefa principal terá no máximo uma lista.
- Uma tarefa principal poderá não ter lista temporariamente.
- Uma subtarefa nunca receberá lista, grupo, categoria ou tag próprios.
- Uma lista pertencerá a no máximo um grupo.
- Um grupo não conterá grupos ou tarefas diretamente.
- Uma tarefa poderá ter no máximo uma categoria.
- Uma tarefa poderá ter várias tags, sem duplicatas equivalentes.
- Categorias e tags existirão independentemente das listas.
- Mover uma tarefa não modificará sua classificação ou hierarquia.
- Excluir grupo não excluirá listas.
- Excluir lista com tarefas exigirá destino válido.

## 6. Fora do escopo

Não fazem parte desta especificação:

- visões inteligentes;
- My Day;
- busca e filtros completos;
- prazos, lembretes e recorrência;
- persistência Drift e migrações;
- backup e importação ou exportação;
- sincronização;
- colaboração e compartilhamento;
- listas compartilhadas;
- grupos aninhados;
- categorias múltiplas por tarefa;
- tags específicas de uma única lista;
- exclusão definitiva da lixeira.

## 7. Critérios de aceitação

### CA-01 — Criar lista

**Dado** que o usuário está criando uma lista
**Quando** informa um nome válido e ainda não utilizado
**Então** a lista é criada e pode receber tarefas.

### CA-02 — Rejeitar nome duplicado

**Dado** que já existe uma lista com determinado nome
**Quando** o usuário tenta criar ou renomear outra lista com o mesmo nome
**Então** a operação é rejeitada sem alterar a lista existente.

### CA-03 — Criar tarefa sem lista

**Dado** que não existe uma lista padrão
**Quando** o usuário cria uma tarefa sem escolher uma lista
**Então** a tarefa é salva na inbox implícita e aparece em Todas, busca e no
filtro “Sem lista”.

### CA-04 — Atribuir tarefa à lista

**Dado** que uma tarefa está sem lista
**Quando** o usuário escolhe uma lista existente
**Então** a tarefa passa a pertencer à lista e deixa de aparecer no filtro
“Sem lista”.

### CA-05 — Mover hierarquia

**Dado** que uma tarefa possui subtarefas e pertence a uma lista
**Quando** o usuário a move para outra lista
**Então** a tarefa e suas subtarefas passam a ser relacionadas à nova lista,
sem cópia e sem perda de dados.

### CA-06 — Excluir lista vazia

**Dado** que uma lista não possui tarefas principais
**Quando** o usuário confirma sua exclusão
**Então** a lista é removida sem afetar outras listas ou grupos.

### CA-07 — Exigir destino ao excluir lista

**Dado** que uma lista possui tarefas e existe outra lista disponível
**Quando** o usuário tenta excluí-la sem escolher destino
**Então** a operação é bloqueada e uma lista de destino é solicitada.

### CA-08 — Excluir lista com destino

**Dado** que uma lista possui tarefas
**Quando** o usuário escolhe outra lista e confirma a exclusão
**Então** todas as tarefas e subtarefas são movidas para o destino e a lista de
origem é removida.

### CA-09 — Excluir grupo

**Dado** que um grupo contém listas
**Quando** o usuário exclui o grupo
**Então** o grupo é removido e as listas permanecem intactas e sem grupo.

### CA-10 — Criar e aplicar categoria

**Dado** que o usuário está editando uma tarefa
**Quando** cria ou seleciona uma categoria
**Então** a categoria fica disponível globalmente e é associada à tarefa.

### CA-11 — Remover categoria

**Dado** que uma categoria está associada a várias tarefas
**Quando** o usuário exclui a categoria
**Então** a categoria é removida e as tarefas permanecem sem categoria, com os
demais dados preservados.

### CA-12 — Normalizar tags

**Dado** que existe a tag “Trabalho”
**Quando** o usuário tenta criar ou adicionar “ trabalho ” a uma tarefa
**Então** não é criada uma tag equivalente duplicada.

### CA-13 — Remover tag

**Dado** que uma tag está associada a várias tarefas
**Quando** o usuário exclui a tag
**Então** ela é removida das tarefas sem alterar seus outros dados.

### CA-14 — Preservar ordenação

**Dado** que o usuário definiu uma ordem manual para listas e grupos
**Quando** fecha e reabre o aplicativo
**Então** a mesma ordem é apresentada.

## 8. Dependências e próximos documentos

Esta especificação deverá ser usada como entrada para:

- [especificação de visões inteligentes e My Day](03-visoes-inteligentes-e-my-day.md);
- [especificação de busca e filtros](05-busca-e-filtros.md);
- [especificação de persistência Drift e migrações](06-persistencia-drift-e-migracoes.md);
- [especificação de backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md).

As regras de pertencimento e classificação definidas aqui não poderão ser
alteradas por uma implementação sem uma nova decisão documentada.
