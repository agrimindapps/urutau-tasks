# Escopo do MVP

## 1. Objetivo

O MVP do Urutau Tasks será uma versão local-first de produtividade pessoal,
inspirada no núcleo funcional e visual do Microsoft To Do, mas sem depender de
contas, servidores ou integrações externas.

O objetivo é oferecer uma experiência completa para organizar tarefas,
prioridades e o planejamento diário, mantendo privacidade, simplicidade e
controle local dos dados.

O Microsoft To Do será utilizado como referência de produto para fluxos como
listas, planejamento diário, etapas, prioridades, notas, tags, prazos,
lembretes e recorrência. A implementação do Urutau Tasks continuará
independente e adaptada aos seus princípios técnicos.

Referências:

- [Gerenciamento de tarefas no Microsoft To Do](https://support.microsoft.com/en-us/todo/managing-tasks-in-microsoft-to-do)
- [My Day e sugestões no Microsoft To Do](https://support.microsoft.com/en-us/todo/my-day-and-suggestions)

## 2. Usuário e promessa principal

O usuário deverá conseguir capturar, organizar e concluir suas tarefas sem
precisar criar uma conta ou manter uma conexão com a internet.

Ao abrir o aplicativo, ele deverá encontrar uma forma clara de:

1. visualizar o que precisa fazer hoje;
2. consultar tarefas planejadas e importantes;
3. criar novas tarefas rapidamente;
4. organizar tarefas em listas, grupos, categorias e tags;
5. detalhar uma tarefa em etapas menores;
6. acompanhar o progresso e o histórico de conclusão.

## 3. Funcionalidades incluídas

### 3.1 Tarefas

O usuário poderá:

- criar tarefas;
- editar tarefas;
- concluir e reabrir tarefas;
- excluir tarefas;
- restaurar tarefas excluídas;
- adicionar notas simples;
- definir prazo;
- configurar lembrete;
- definir prioridade;
- adicionar categoria e tags;
- visualizar o progresso das subtarefas.

### 3.2 Subtarefas

Uma tarefa poderá conter subtarefas, utilizadas exclusivamente como etapas
para destrinchar e concluir a tarefa principal.

As subtarefas:

- pertencerão obrigatoriamente a uma tarefa principal;
- terão descrição e estado de conclusão;
- não terão lista, prioridade, prazo, lembrete, recorrência ou categoria
  próprios;
- não aparecerão como tarefas independentes nas visões inteligentes;
- contribuirão para o indicador de progresso da tarefa principal.

A tarefa principal poderá ser concluída mesmo que existam subtarefas pendentes.
Concluir a tarefa principal não concluirá automaticamente suas subtarefas. Os
estados das subtarefas permanecerão preservados, permitindo que o usuário
continue acompanhando o detalhamento original.

### 3.3 Prioridades

Cada tarefa poderá possuir um dos seguintes níveis:

- baixa;
- média;
- alta;
- urgente.

A prioridade deverá ser utilizada para ordenação, filtragem e planejamento,
sem impedir que o usuário conclua ou mova uma tarefa.

### 3.4 Listas e grupos

As tarefas poderão pertencer a uma lista principal ou permanecer
temporariamente sem lista, funcionando como uma inbox implícita. O usuário
poderá criar listas personalizadas e agrupá-las por áreas, projetos ou
contextos.

Tarefas sem lista aparecerão na visão Todas, na busca e no filtro “Sem lista”,
podendo ser atribuídas posteriormente a uma lista existente. Não haverá uma
lista padrão protegida criada pelo sistema.

As visões inteligentes não criarão cópias das tarefas: elas apresentarão as
mesmas tarefas a partir de critérios derivados dos dados existentes.

Uma lista vazia poderá ser excluída diretamente. Para excluir uma lista com
tarefas, o usuário deverá escolher outra lista existente como destino; a tarefa
principal e suas subtarefas serão movidas juntas, preservando seus dados.

### 3.5 Categorias e tags

O MVP diferenciará os dois mecanismos:

- cada tarefa poderá ter uma categoria principal;
- cada tarefa poderá possuir várias tags livres;
- categorias serão usadas para classificação principal;
- tags serão usadas para cruzar contextos e facilitar busca e filtros.

### 3.6 Planejamento diário

O My Day será uma visão de foco diário. O usuário poderá adicionar tarefas
existentes ou criar novas tarefas diretamente nessa visão.

Na virada do dia, tarefas não concluídas retornarão à lista principal e
permanecerão disponíveis para novo planejamento. A conclusão ou remoção da
tarefa da visão diária não excluirá a tarefa da sua lista principal.

### 3.7 Visões inteligentes

O MVP terá as seguintes visões derivadas:

- **My Day:** tarefas escolhidas para o foco do dia;
- **Importante:** tarefas marcadas com prioridade alta ou urgente;
- **Planejado:** tarefas com prazo ou lembrete configurado;
- **Todas:** tarefas ativas de todas as listas;
- **Concluídas:** tarefas concluídas.

Essas visões deverão respeitar o estado real das tarefas e não introduzir
duplicação de dados.

### 3.8 Recorrência

O MVP suportará recorrência essencial para tarefas:

- diária;
- em dias úteis;
- semanal;
- mensal;
- anual.

Regras avançadas de repetição e expressões personalizadas ficarão para uma
especificação posterior.

### 3.9 Busca e filtros

O usuário poderá pesquisar tarefas por texto e combinar a busca com filtros de:

- status;
- lista;
- grupo;
- categoria;
- tags;
- prioridade;
- prazo;
- recorrência.

O MVP não interpretará datas, lembretes ou recorrência a partir de linguagem
natural digitada no título.

### 3.10 Lembretes

Os lembretes utilizarão notificações locais adaptadas à capacidade de cada
plataforma, conforme a [especificação de notificações por plataforma](specs/08-notificacoes-por-plataforma.md).

### 3.11 Dados e portabilidade

Os dados serão armazenados localmente com Drift, conforme os princípios
técnicos do projeto.

O MVP deverá prever:

- backup e restauração completos dos dados locais;
- exportação em formato aberto;
- importação de formato aberto;
- preservação de dados durante migrações de versão.

Os detalhes do esquema dos arquivos, compatibilidade, validação e estratégia
de conflito serão definidos em especificações próprias antes da implementação.

### 3.12 Internacionalização

A interface será preparada para:

- português do Brasil (`pt-BR`);
- inglês (`en`);
- espanhol (`es`).

O idioma seguirá o sistema por padrão, permitirá substituição manual local e
usará `pt-BR` como fallback. Textos seguirão o idioma da interface; datas,
números e início da semana seguirão a região do dispositivo, conforme a
[especificação de internacionalização](specs/09-internacionalizacao.md).

## 4. Funcionalidades fora do MVP

Ficam explicitamente fora da primeira versão:

- anexos e arquivos;
- colaboração entre usuários;
- compartilhamento de listas;
- atribuição de tarefas;
- contas obrigatórias;
- Firebase;
- backend próprio;
- sincronização automática;
- integração com Outlook ou e-mail;
- sugestões inteligentes;
- reconhecimento de linguagem natural;
- notas com formatação rica;
- recorrência personalizada avançada;
- recursos de produtividade baseados em serviços proprietários.

Google Drive poderá ser estudado posteriormente como uma integração opcional
de sincronização, sem alterar o funcionamento local do aplicativo.

## 5. Critérios de aceitação do MVP

O MVP será considerado funcional quando o usuário puder:

1. criar uma tarefa e atribuí-la a uma lista;
2. editar seus detalhes e concluir a tarefa;
3. criar subtarefas e acompanhar seu progresso;
4. concluir a tarefa principal mantendo subtarefas pendentes;
5. organizar tarefas com listas, grupos, categorias, tags e prioridades;
6. planejar tarefas no My Day e retomar as não concluídas no dia seguinte;
7. consultar visões inteligentes sem duplicação de dados;
8. configurar prazo, lembrete e recorrência essencial;
9. pesquisar e filtrar tarefas;
10. excluir e restaurar tarefas;
11. fazer backup, restaurar e importar ou exportar dados;
12. utilizar a interface em português do Brasil, inglês e espanhol;
13. executar a experiência principal na Web e manter o projeto preparado para
    Android, iOS, Linux, macOS e Windows.

## 6. Decomposição futura em especificações

Este documento define o limite do MVP, mas não substitui as especificações
detalhadas. As próximas especificações SDD deverão decompor o escopo em
unidades menores, começando por:

1. [modelo, ciclo de vida de tarefas e subtarefas](specs/01-tarefas-e-subtarefas.md);
2. [listas, grupos, categorias e tags](specs/02-listas-grupos-categorias-tags.md);
3. [visões inteligentes e My Day](specs/03-visoes-inteligentes-e-my-day.md);
4. [prazos, lembretes e recorrência](specs/04-prazos-lembretes-e-recorrencia.md);
5. [busca e filtros](specs/05-busca-e-filtros.md);
6. [persistência Drift e migrações](specs/06-persistencia-drift-e-migracoes.md);
7. [backup, restauração e formato aberto](specs/07-backup-restauracao-formato-aberto.md);
8. [notificações por plataforma](specs/08-notificacoes-por-plataforma.md);
9. [internacionalização](specs/09-internacionalizacao.md);
10. [validação multiplataforma](specs/10-validacao-multiplataforma.md).
