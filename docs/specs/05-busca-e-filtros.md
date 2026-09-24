# Especificação SDD: Busca e Filtros

**Status:** proposta para implementação
**Versão:** 1.0
**Escopo:** busca textual e filtros de tarefas

## 1. Contexto

Esta especificação detalha a busca textual e os filtros do Urutau Tasks. Ela
deriva do [Escopo do MVP](../04-escopo-do-mvp.md) e complementa as regras de
tarefas, subtarefas, listas, visões inteligentes, prazos, lembretes e
recorrência definidas nas especificações anteriores.

A busca será uma projeção dos dados já existentes. Ela não criará cópias de
tarefas, subtarefas ou resultados persistentes.

## 2. Objetivo

Permitir que o usuário encontre tarefas rapidamente por texto e refine os
resultados por atributos de organização e planejamento, preservando a
hierarquia das tarefas e seus dados originais.

## 3. Terminologia

### 3.1 Busca textual

Consulta formada por um texto digitado pelo usuário. A busca localizará o
texto no título, nas notas e na descrição das subtarefas.

### 3.2 Filtro

Critério estruturado aplicado aos dados das tarefas. Filtros poderão ser
usados sozinhos ou combinados com uma busca textual.

### 3.3 Resultado

Uma tarefa principal apresentada ao usuário. Uma subtarefa nunca será exibida
como resultado independente, mesmo quando for o conteúdo que corresponde à
busca.

## 4. Escopo dos resultados

### RF-01 — Busca global

A busca será global por padrão e pesquisará tarefas fora da lixeira,
independentemente da lista ou visão atualmente aberta.

Os filtros de lista, grupo, categoria, tags e demais atributos poderão
restringir o conjunto global aos resultados desejados.

### RF-02 — Estados pesquisáveis

Sem filtro de status, a busca exibirá tarefas principais ativas e concluídas.
Tarefas na lixeira nunca participarão da busca normal, mesmo que atendam ao
texto ou a outros filtros.

A lixeira terá uma tela própria para consulta. Esta especificação não cria uma
opção de busca que inclua seus itens.

### RF-03 — Subtarefas

A descrição das subtarefas participará da busca textual. Quando uma subtarefa
corresponder ao termo, a tarefa principal será apresentada como resultado e
poderá ser aberta para localizar o detalhamento correspondente.

Subtarefas não serão duplicadas nem exibidas como resultados independentes.
Os filtros de status, lista, grupo, categoria, tags, prioridade, prazo,
lembrete e recorrência serão avaliados na tarefa principal.

## 5. Busca textual

### RF-04 — Campos pesquisáveis

A busca textual deverá considerar:

- título da tarefa principal;
- notas da tarefa principal;
- descrição de todas as subtarefas da tarefa principal.

O resultado será sempre a tarefa principal, independentemente do campo que
contiver a correspondência.

### RF-05 — Correspondência

A busca deverá aceitar correspondência parcial e não diferenciar maiúsculas de
minúsculas nem caracteres acentuados.

Por exemplo, uma busca por `reuniao` deverá localizar `Reunião`, e uma busca
por parte de uma palavra deverá localizar conteúdos que contenham aquele
trecho.

O texto informado deverá ser normalizado para comparação, sem modificar o
texto armazenado na tarefa, nas notas ou nas subtarefas.

### RF-06 — Atualização durante a digitação

Os resultados deverão ser atualizados automaticamente após uma breve pausa na
digitação. A implementação da camada de apresentação deverá aplicar debounce
para evitar uma consulta a cada tecla.

O intervalo exato do debounce não faz parte desta especificação. A ausência de
texto não deverá impedir o uso dos filtros.

### RF-07 — Busca vazia

Quando o campo de busca estiver vazio ou contiver somente espaços, os
resultados deverão ser determinados apenas pelos filtros ativos.

Sem texto e sem filtros, a tela poderá exibir o conjunto padrão de tarefas
pesquisáveis ou orientar o usuário a informar um critério. Essa apresentação
não deverá alterar as regras de inclusão e exclusão dos resultados.

## 6. Filtros

### RF-08 — Combinação de filtros

Filtros de categorias diferentes serão combinados com AND. A tarefa deverá
atender a todos os filtros ativos.

Quando houver várias opções selecionadas dentro da mesma categoria, elas serão
combinadas com OR. Por exemplo, selecionar as prioridades alta e urgente
deverá localizar tarefas que possuam qualquer uma dessas prioridades.

### RF-09 — Status

O filtro de status deverá permitir:

- tarefas ativas;
- tarefas concluídas.

Itens na lixeira não serão uma opção desse filtro e não aparecerão nos
resultados da busca. A consulta à lixeira ficará restrita à sua tela própria.

### RF-10 — Lista e grupo

O filtro de lista deverá permitir selecionar uma ou mais listas. Tarefas sem
lista deverão estar disponíveis pela opção **Sem lista**.

O filtro de grupo deverá considerar as listas pertencentes ao grupo. Uma tarefa
sem lista não pertencerá a grupo e não deverá ser incluída em um filtro de
grupo.

Ao selecionar várias listas ou grupos dentro da mesma categoria, a tarefa
poderá pertencer a qualquer uma das opções selecionadas. Entre lista e grupo,
os critérios serão cumulativos.

### RF-11 — Categoria e tags

O filtro de categoria deverá permitir selecionar uma ou mais categorias. Uma
tarefa sem categoria deverá poder ser localizada pela opção **Sem categoria**.

O filtro de tags deverá permitir selecionar uma ou mais tags. Uma tarefa que
possua qualquer uma das tags selecionadas deverá atender ao filtro. A opção
**Sem tags** deverá localizar tarefas sem tags associadas.

Categorias e tags serão comparadas segundo as regras de identidade já
definidas em [listas, grupos, categorias e tags](02-listas-grupos-categorias-tags.md).

### RF-12 — Prioridade

O filtro de prioridade deverá permitir selecionar uma ou mais opções entre
baixa, média, alta e urgente.

Uma tarefa sem prioridade explícita deverá permanecer fora das opções de
prioridade selecionadas, mas não será excluída da busca sem filtro de
prioridade.

### RF-13 — Prazo

O filtro de prazo deverá oferecer as seguintes categorias:

- **Sem prazo:** tarefa sem prazo configurado;
- **Atrasadas:** tarefa ativa com prazo anterior à data local atual;
- **Hoje:** tarefa com prazo na data local atual;
- **Próximos 7 dias:** tarefa com prazo entre amanhã e o sétimo dia seguinte,
  inclusive;
- **Intervalo personalizado:** tarefa com prazo entre as datas inicial e final
  informadas, com limites inclusivos.

As categorias de prazo utilizarão o calendário local do dispositivo. Tarefas
concluídas com prazo passado poderão ser encontradas pela busca, mas não serão
classificadas como atrasadas; atraso é uma condição de tarefa ativa.

Uma tarefa com prazo e lembrete deverá ser avaliada pelo seu prazo neste
filtro, sem duplicação do resultado.

### RF-14 — Lembrete

O filtro de lembrete deverá distinguir:

- tarefas com lembrete configurado;
- tarefas sem lembrete configurado.

O filtro não deverá criar notificações, alterar horários ou interpretar o
estado do lembrete. Datas e horários do lembrete continuam sujeitos às regras
da [especificação de prazos, lembretes e recorrência](04-prazos-lembretes-e-recorrencia.md).

### RF-15 — Recorrência

O filtro de recorrência deverá distinguir:

- tarefas com recorrência ativa;
- tarefas sem recorrência;
- tarefas cuja recorrência foi cancelada.

Ocorrências históricas de uma série continuarão sendo tarefas principais
pesquisáveis conforme seu próprio status. O filtro será aplicado aos dados da
ocorrência e da série sem reativar ou criar novas ocorrências.

## 7. Ordenação e apresentação

### RF-16 — Relevância textual

Quando houver texto de busca, os resultados deverão ser ordenados por
relevância textual nesta prioridade:

1. correspondência no título;
2. correspondência nas notas;
3. correspondência na descrição de subtarefas.

Dentro do mesmo nível de relevância, a ordem de origem da tarefa será usada
como desempate. Em busca global, a ordem de origem será determinística:
primeiro a ordem dos grupos e, dentro deles, a ordem das listas; depois as
listas sem grupo, na ordem manual. Dentro de cada lista, será usada a posição
da tarefa. Tarefas sem lista aparecerão depois das tarefas em listas, em ordem
de criação crescente, com UUID como desempate final. A ordenação manual das
listas e grupos seguirá a especificação 02.

Quando a consulta tiver somente filtros, os resultados deverão usar a ordem de
origem definida acima, salvo se a visão ou contexto de apresentação possuir
uma ordenação específica já documentada.

### RF-17 — Identificação da correspondência

Quando possível, a apresentação poderá indicar se o termo foi encontrado no
título, nas notas ou em uma subtarefa. Essa indicação será apenas visual e não
criará dados adicionais na tarefa.

Ao abrir um resultado cujo termo esteja em uma subtarefa, o usuário deverá
continuar acessando a tarefa principal e seu detalhamento interno.

## 8. Atualização e integridade

### RF-18 — Atualização dos resultados

Os resultados deverão refletir alterações nos dados sem exigir edição de uma
cópia da tarefa. Exemplos:

- editar título, notas ou subtarefa pode incluir ou remover uma tarefa da
  busca textual;
- concluir ou reabrir uma tarefa pode alterar o resultado do filtro de status;
- mover uma tarefa de lista pode alterar o resultado do filtro de lista ou
  grupo;
- alterar categoria, tags ou prioridade pode alterar os filtros
  correspondentes;
- adicionar ou remover prazo ou lembrete pode alterar os filtros de
  planejamento;
- ativar ou cancelar recorrência pode alterar o filtro de recorrência.

### RF-19 — Preservação dos dados

Pesquisar, filtrar, ordenar ou abrir um resultado não poderá alterar:

- título, notas ou descrição das subtarefas;
- estado da tarefa ou das subtarefas;
- lista, grupo, categoria ou tags;
- prioridade, prazo, lembrete ou recorrência;
- ordem de origem da tarefa;
- histórico de ocorrências recorrentes.

## 9. Fora do escopo

Não fazem parte desta especificação:

- busca dentro da lixeira;
- resultados independentes para subtarefas;
- reconhecimento de linguagem natural;
- interpretação automática de datas, lembretes ou recorrência;
- busca semântica ou por sinônimos;
- operadores avançados de consulta;
- histórico de buscas;
- persistência de filtros salvos;
- paginação, indexação ou consultas Drift;
- APIs públicas ou tipos de domínio;
- alterações na tela própria da lixeira.

## 10. Critérios de aceitação

### CA-01 — Pesquisar globalmente por título

**Dado** que existem tarefas com títulos em listas diferentes, **quando** o
usuário pesquisa um termo presente em um título, **então** a tarefa
correspondente é exibida independentemente da lista ou visão aberta.

### CA-02 — Pesquisar notas

**Dado** que o termo não aparece no título, mas aparece nas notas, **quando** o
usuário pesquisa o termo, **então** a tarefa principal é exibida.

### CA-03 — Localizar por subtarefa

**Dado** que o termo aparece na descrição de uma subtarefa, **quando** o
usuário pesquisa o termo, **então** a tarefa principal é exibida como
resultado.

### CA-04 — Ignorar maiúsculas e acentos

**Dado** que uma tarefa possui o texto `Reunião`, **quando** o usuário pesquisa
`reuniao`, **então** a tarefa é localizada.

### CA-05 — Aceitar correspondência parcial

**Dado** que uma tarefa possui uma palavra contendo o termo pesquisado,
**quando** o usuário informa apenas parte da palavra, **então** a tarefa é
localizada.

### CA-06 — Aplicar filtros sem texto

**Dado** que o campo de busca está vazio e existe um filtro de prioridade
ativo, **quando** o usuário consulta os resultados, **então** somente as
tarefas compatíveis com o filtro são exibidas.

### CA-07 — Atualizar durante a digitação

**Dado** que o usuário altera o texto da busca, **quando** ele pausa brevemente
a digitação, **então** os resultados são atualizados automaticamente.

### CA-08 — Excluir lixeira

**Dado** que uma tarefa na lixeira corresponde ao texto pesquisado, **quando** o
usuário realiza uma busca normal, **então** a tarefa não é exibida.

### CA-09 — Filtrar status

**Dado** que existem tarefas ativas e concluídas, **quando** o usuário
seleciona um status, **então** somente as tarefas principais daquele status são
exibidas.

### CA-10 — Filtrar organização e prioridade

**Dado** que existem tarefas em listas, grupos, categorias, tags e prioridades
diferentes, **quando** o usuário seleciona esses filtros, **então** somente as
tarefas que atendem aos critérios selecionados são exibidas.

### CA-11 — Localizar sem lista

**Dado** que existe uma tarefa sem lista, **quando** o usuário seleciona o
filtro **Sem lista**, **então** a tarefa é exibida sem ser associada a uma lista
ou grupo.

### CA-12 — Combinar filtros

**Dado** que existem tarefas com diferentes combinações de filtros, **quando**
o usuário seleciona opções em categorias diferentes e várias opções na mesma
categoria, **então** a tarefa deve atender a todas as categorias e a qualquer
opção selecionada dentro de cada categoria.

### CA-13 — Filtrar prazos relativos

**Dado** que existem tarefas sem prazo, atrasadas, para hoje e para os próximos
7 dias, **quando** o usuário seleciona uma categoria de prazo, **então** somente
as tarefas daquela categoria são exibidas conforme o calendário local.

### CA-14 — Filtrar intervalo personalizado

**Dado** que o usuário informa datas inicial e final, **quando** aplica o filtro
de intervalo personalizado, **então** tarefas com prazo exatamente nos limites
e entre eles são incluídas.

### CA-15 — Filtrar lembrete

**Dado** que existem tarefas com e sem lembrete, **quando** o usuário seleciona
uma opção do filtro de lembrete, **então** somente as tarefas compatíveis são
exibidas.

### CA-16 — Filtrar recorrência

**Dado** que existem tarefas recorrentes, não recorrentes e com recorrência
cancelada, **quando** o usuário seleciona uma opção do filtro de recorrência,
**então** somente as tarefas compatíveis são exibidas sem criar ocorrências.

### CA-17 — Ordenar por relevância

**Dado** que o termo aparece no título de uma tarefa e nas notas de outra,
**quando** o usuário realiza a busca, **então** a correspondência no título
aparece antes da correspondência nas notas.

### CA-18 — Manter resultado principal único

**Dado** que várias subtarefas da mesma tarefa correspondem ao termo, **quando**
o usuário pesquisa o termo, **então** a tarefa principal aparece uma única vez.

### CA-19 — Preservar dados

**Dado** que uma tarefa possui dados completos e subtarefas, **quando** o
usuário pesquisa, filtra, ordena e abre o resultado, **então** nenhum dado da
tarefa ou da hierarquia é alterado.

### CA-20 — Não classificar concluída como atrasada

**Dado** que uma tarefa concluída possui prazo passado, **quando** o usuário
aplica o filtro **Atrasadas**, **então** a tarefa não é exibida como atrasada.

## 11. Dependências e próximos documentos

Esta especificação deverá ser usada como entrada para:

- [especificação de persistência Drift e migrações](06-persistencia-drift-e-migracoes.md);
- [especificação de internacionalização](09-internacionalizacao.md), incluindo os termos e filtros;
- [especificação de validação multiplataforma](10-validacao-multiplataforma.md);
- [especificação de backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md);
- implementação das visões e telas de consulta.

A busca e os filtros deverão permanecer projeções dos dados existentes. Nenhuma
implementação poderá criar um estado paralelo ou modificar uma tarefa apenas
porque ela foi encontrada em um resultado.
