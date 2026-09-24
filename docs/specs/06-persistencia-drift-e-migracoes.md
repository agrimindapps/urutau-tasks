# Especificação SDD: Persistência Drift e Migrações

**Status:** proposta para implementação
**Versão:** 1.0
**Escopo:** armazenamento local, integridade e evolução do esquema

## 1. Contexto

Esta especificação define como os dados do Urutau Tasks serão persistidos
localmente. Ela deriva do [Escopo do MVP](../04-escopo-do-mvp.md) e traduz as
regras das especificações de tarefas, listas, visões, prazos, recorrência e
busca em um modelo relacional implementável.

O documento define o contrato lógico da persistência. Não define ainda código
Dart, tabelas Drift concretas, APIs públicas ou consultas específicas.

## 2. Objetivo

Garantir que o aplicativo funcione sem conta, backend ou conexão com a
internet, preservando dados, relações, histórico e ordenação após o fechamento
do aplicativo, atualizações de versão e operações compostas.

## 3. Princípios de persistência

### RF-01 — Banco local por instalação

Cada instalação do aplicativo utilizará um único banco local SQLite acessado
por Drift. O banco reunirá tarefas, subtarefas, listas, grupos, categorias,
tags, My Day, recorrência e metadados necessários ao funcionamento local.

O aplicativo não dependerá de conta, backend, Firebase ou sincronização para
ler ou gravar esses dados.

### RF-02 — Modelo relacional normalizado

As entidades e seus relacionamentos serão representados por tabelas e
referências explícitas. Dados de domínio não deverão ser serializados em JSON
dentro de uma coluna para substituir relações consultáveis.

JSON poderá ser considerado futuramente para dados externos de backup ou
intercâmbio, conforme especificação própria, mas não será a representação
principal do banco local.

### RF-03 — Identificadores estáveis

Tarefas e demais entidades persistidas utilizarão UUIDs estáveis gerados pela
camada de domínio/aplicação. O identificador de uma entidade não deverá mudar
quando ela for editada, movida, restaurada ou migrada.

Os UUIDs deverão ser preservados em backup, importação, exportação e futuras
sincronizações, sem depender de chaves autoincrementais locais.

### RF-04 — Transações atômicas

Toda operação que alterar mais de um registro ou relacionamento deverá ser
executada em uma transação atômica. Em caso de falha, nenhuma parte da
operação deverá permanecer aplicada.

As transações deverão ser usadas, no mínimo, para:

- mover ou restaurar uma hierarquia de tarefa;
- excluir uma lista com movimentação de tarefas;
- reordenar itens;
- concluir ocorrência recorrente e criar a próxima;
- alterar ou remover relações de categoria e tags;
- executar rollover do My Day;
- aplicar migrações do esquema.

## 4. Modelo lógico de dados

### RF-05 — Tarefas

Cada registro de tarefa principal deverá possuir, conceitualmente:

- UUID estável;
- título obrigatório;
- notas opcionais;
- status ativo, concluído ou na lixeira;
- prioridade;
- referência opcional à lista;
- referência opcional à categoria;
- prazo opcional como data ISO sem horário;
- lembrete opcional como instante UTC;
- referência opcional à série recorrente;
- datas de criação, alteração e conclusão;
- posição na lista ou contexto de origem;
- metadados de exclusão e restauração quando estiver na lixeira.

O modelo deverá permitir tarefas sem lista. A ausência de lista será
representada por uma referência nula e não por uma lista artificial criada
pelo sistema.

Os dados da tarefa deverão ser suficientes para que as visões Todas,
Importante, Planejado, Concluídas, My Day e a busca sejam projeções sem cópia
da tarefa.

### RF-06 — Subtarefas

Cada subtarefa deverá possuir:

- UUID estável;
- referência obrigatória à tarefa principal;
- descrição obrigatória;
- estado de conclusão;
- posição inteira dentro da tarefa principal.

Subtarefas não possuirão referências próprias para lista, grupo, categoria,
tags, prioridade, prazo, lembrete ou recorrência.

A remoção individual de uma subtarefa deverá excluir fisicamente seu registro
e referências dependentes em uma transação. Ela não deverá ser enviada à
lixeira nem reaparecer como item independente.

Ao enviar a tarefa principal para a lixeira, as subtarefas deverão permanecer
relacionadas a ela e acompanhar sua hierarquia. Ao restaurar a tarefa, a
relação, a ordem e os estados das subtarefas deverão ser preservados.

### RF-07 — Listas e grupos

Cada lista deverá possuir UUID, nome obrigatório, posição inteira e referência
opcional a um grupo.

Cada grupo deverá possuir UUID, nome obrigatório e posição inteira. O grupo
não armazenará tarefas diretamente.

Uma lista poderá pertencer a no máximo um grupo. A exclusão de um grupo deverá
remover apenas a referência das listas, preservando listas e tarefas.

Ao excluir uma lista com tarefas, a movimentação das tarefas principais e de
suas subtarefas para uma lista de destino deverá ocorrer na mesma transação da
exclusão da lista. A operação deverá ser bloqueada se não houver destino
válido, conforme as regras de listas e grupos.

### RF-08 — Categorias e tags

Cada categoria deverá possuir UUID e nome globalmente único. Uma tarefa poderá
referenciar no máximo uma categoria.

Cada tag deverá possuir UUID e nome normalizado. A relação entre tarefas e
tags será muitos-para-muitos por meio de uma entidade de associação própria.

A exclusão de uma categoria deverá remover o vínculo com as tarefas sem
excluir tarefas. A exclusão de uma tag deverá remover as associações sem
excluir tarefas ou outras tags.

As regras de normalização, igualdade sem diferenciação de maiúsculas e
unicidade deverão seguir a
[especificação de listas, grupos, categorias e tags](02-listas-grupos-categorias-tags.md).

### RF-09 — Séries recorrentes

Cada série recorrente deverá possuir UUID, regra fixa, data-base de calendário,
status ativo ou cancelado e referência suficiente para manter sua identidade
ao longo das ocorrências.

Cada ocorrência será armazenada como uma tarefa principal própria, ligada à
série recorrente. O histórico não será reconstruído a partir de um único
registro mutável.

Uma ocorrência deverá manter seus próprios título, notas, prazo, lembrete,
estado, posição, datas e demais dados históricos. A próxima ocorrência será
criada em transação com a conclusão da ocorrência anterior quando a série
continuar ativa.

A nova ocorrência não receberá cópia das subtarefas da ocorrência anterior.
As subtarefas continuarão pertencendo exclusivamente à ocorrência em que
foram criadas.

### RF-10 — Entradas do My Day

Cada entrada do My Day deverá possuir UUID, referência à tarefa principal,
data local do foco e posição inteira dentro daquela data.

Uma tarefa poderá possuir no máximo uma entrada para cada data local. A
entrada não substituirá nem alterará a lista de origem da tarefa.

A remoção da entrada não deverá excluir, concluir ou mover a tarefa. O
rollover deverá remover entradas pendentes do dia anterior em transação,
mantendo os dados da tarefa e sua origem.

Tarefas concluídas ou na lixeira não deverão possuir entradas ativas no My
Day. Essa regra deverá ser aplicada pela camada de aplicação e protegida por
operações transacionais.

## 5. Datas e horários

### RF-11 — Prazo

O prazo será persistido como uma data ISO de calendário, sem horário. O valor
não deverá ser convertido em timestamp UTC, pois a semântica do prazo é uma
data local e não um instante.

Datas passadas continuarão válidas e poderão representar tarefas atrasadas.

### RF-12 — Lembrete

O lembrete será persistido como instante UTC. A apresentação e o agendamento
deverão converter o valor para o fuso local do dispositivo.

O banco não deverá armazenar o lembrete como texto formatado para exibição.
Formatação e locale ficarão nas camadas apropriadas. A consulta de capacidade,
permissão e reconstrução dos agendamentos está definida na
[especificação de notificações por plataforma](08-notificacoes-por-plataforma.md).

### RF-13 — My Day e calendário local

A data do My Day será uma data de calendário local, sem horário. O rollover
deverá utilizar o fuso local configurado no dispositivo e não poderá depender
de uma conversão UTC que altere o dia do foco.

## 6. Lixeira e restauração

### RF-14 — Exclusão lógica de tarefas

Excluir uma tarefa principal deverá marcar seus registros como pertencentes à
lixeira, sem apagar a tarefa ou suas subtarefas. A operação deverá preservar:

- hierarquia;
- lista de origem;
- posição;
- status anterior;
- estados das subtarefas;
- dados de prazo, lembrete, prioridade, categoria, tags e recorrência;
- instante e contexto necessários para restauração.

Itens na lixeira deverão ficar fora das visões normais, do My Day e da busca
normal.

### RF-15 — Restauração

Restaurar uma tarefa deverá desfazer sua exclusão lógica e recuperar a tarefa,
as subtarefas e os relacionamentos preservados. A hierarquia, a posição e os
estados anteriores deverão ser restaurados em uma única transação.

A restauração não deverá criar uma cópia ou alterar o UUID dos registros.

### RF-16 — Exclusão definitiva

A exclusão definitiva da lixeira não faz parte desta especificação. Nenhuma
rotina automática de limpeza deverá ser criada como parte da persistência do
MVP.

## 7. Integridade e ordenação

### RF-17 — Integridade referencial

As relações obrigatórias deverão impedir registros órfãos. A implementação
deverá habilitar e testar as restrições de chave estrangeira do SQLite.

Exclusões em cascata não previstas não serão permitidas. Toda remoção de
relacionamento deverá seguir a regra de domínio correspondente, inclusive
para subtarefas, tags, categorias, grupos e listas.

### RF-18 — Posições

Listas, grupos, subtarefas, tarefas dentro de uma lista e entradas do My Day
utilizarão posições inteiras relativas ao seu contexto.

Após reordenação, as posições deverão ser renumeradas de forma determinística
em uma transação. O processo não deverá deixar posições duplicadas ou lacunas
que alterem a ordem observada pelo usuário.

A posição de origem não deverá ser confundida com a posição do My Day. O
My Day manterá sua própria ordem por data.

### RF-19 — Unicidade

O banco deverá proteger, conforme o modelo de cada entidade:

- UUIDs únicos;
- nomes únicos de listas, grupos e categorias dentro de seus escopos;
- nomes normalizados de tags;
- no máximo uma categoria por tarefa;
- no máximo uma entrada do My Day por tarefa e data;
- relações tarefa-tag sem duplicação;
- uma subtarefa pertencente a uma única tarefa principal.

## 8. Separação entre persistência e domínio

### RF-20 — Modelos de domínio

As tabelas e classes geradas pelo Drift não deverão ser expostas diretamente
às regras de negócio ou à apresentação. A camada de persistência deverá
converter registros do banco em modelos de domínio e receber comandos ou
modelos apropriados para gravação.

As regras de conclusão, restauração, recorrência, rollover, busca e filtros
deverão permanecer testáveis sem depender de widgets Flutter ou de uma
conexão com banco real.

### RF-21 — Repositórios e transações

A implementação poderá usar repositórios ou portas de persistência por
feature, desde que cada abstração tenha responsabilidade clara. Operações que
exigem múltiplas escritas deverão expor uma unidade transacional para a camada
de aplicação.

Nenhuma API pública do pacote, tipo de domínio ou nome concreto de tabela é
definido nesta etapa.

## 9. Migrações

### RF-22 — Versionamento do esquema

O banco deverá possuir uma versão de esquema monotônica. Cada mudança de
estrutura deverá ser registrada como migração incremental, versionada e
revisável.

Uma migração deverá declarar o estado de origem, o estado de destino e como
os dados existentes serão preservados ou transformados.

### RF-23 — Migrações não destrutivas

As migrações do MVP não deverão apagar dados de usuário nem recriar o banco
sem uma estratégia explícita de preservação. Alterações incompatíveis deverão
incluir transformação determinística e testes com dados representativos.

Migrações não deverão alterar UUIDs, histórico de ocorrências, estados de
subtarefas, posições ou relações sem uma decisão documentada.

### RF-24 — Execução e falha

Cada migração deverá ser executada atomicamente. Se qualquer etapa falhar, a
transação deverá realizar rollback integral.

Após uma falha, o aplicativo deverá bloquear a abertura normal da base e
informar que a migração não foi concluída. Não deverá abrir o banco em estado
parcial nem ignorar a incompatibilidade silenciosamente.

O mecanismo de recuperação e suporte ao usuário será definido em uma etapa
posterior, mas a base não poderá ser modificada novamente como se estivesse
atualizada.

### RF-25 — Compatibilidade aplicativo-esquema

O aplicativo deverá verificar se a versão do esquema é compatível com a
versão que ele sabe ler. Bases futuras ou desconhecidas não deverão ser
abertas em modo de escrita por uma versão antiga do aplicativo.

Cada versão de aplicativo que alterar o esquema deverá incluir a migração
correspondente e testes de upgrade a partir das versões suportadas.

## 10. Testes da persistência

### RF-26 — Banco isolado

Os testes de persistência deverão usar banco isolado ou em memória. Nenhum
teste deverá depender do banco pessoal do desenvolvedor, de dados externos ou
de ordem de execução compartilhada.

### RF-27 — Camadas de teste

Deverão existir testes para:

- conversão entre modelos de domínio e registros Drift;
- restrições e relações do esquema;
- operações transacionais;
- migrações entre versões;
- rollback após falha;
- filtros e projeções persistidas;
- restauração da lixeira;
- ordenação e renumeração;
- histórico e criação de ocorrências recorrentes.

## 11. Fora do escopo

Não fazem parte desta especificação:

- implementação efetiva de Drift ou Riverpod;
- APIs públicas, nomes finais de classes ou tabelas;
- código de repositórios e casos de uso;
- backup e restauração como arquivo;
- importação e exportação em formato aberto;
- sincronização com Google Drive;
- notificações locais e adaptadores de plataforma conforme a
  [especificação de notificações por plataforma](08-notificacoes-por-plataforma.md);
- configuração de idioma e preferências de interface conforme a
  [especificação de internacionalização](09-internacionalizacao.md);
- exclusão definitiva da lixeira;
- resolução de conflitos entre bancos ou dispositivos.

## 12. Critérios de aceitação

### CA-01 — Persistir e recuperar tarefa

**Dado** que uma tarefa foi criada com seus dados válidos, **quando** o
aplicativo é fechado e aberto novamente, **então** a tarefa e seus dados são
recuperados sem alteração.

### CA-02 — Preservar tarefa sem lista

**Dado** que uma tarefa não possui lista, **quando** ela é persistida e
recuperada, **então** continua sem lista e disponível como inbox implícita.

### CA-03 — Preservar hierarquia

**Dado** que uma tarefa possui subtarefas, **quando** a base é reaberta,
**então** cada subtarefa continua ligada à tarefa principal correta.

### CA-04 — Preservar estados e posições

**Dado** que subtarefas possuem estados e ordem manual, **quando** são
persistidas e recuperadas, **então** estados e posições permanecem iguais.

### CA-05 — Remover subtarefa individualmente

**Dado** que uma tarefa possui uma subtarefa, **quando** o usuário a remove
individualmente, **então** o registro é excluído sem ir para a lixeira e sem
afetar a tarefa principal ou as demais subtarefas.

### CA-06 — Mover hierarquia em transação

**Dado** que uma tarefa com subtarefas pertence a uma lista, **quando** é
movida para outra lista, **então** toda a hierarquia muda de origem em uma
única transação ou permanece integralmente na origem em caso de falha.

### CA-07 — Preservar categoria e tags

**Dado** que uma tarefa possui categoria e várias tags, **quando** é
persistida e recuperada, **então** todas as associações são preservadas sem
duplicação.

### CA-08 — Preservar grupos e listas

**Dado** que listas pertencem a grupos, **quando** a base é reaberta, **então**
os grupos, listas e posições são recuperados com os vínculos corretos.

### CA-09 — Persistir prazo como data

**Dado** que uma tarefa possui prazo, **quando** é persistida, **então** o
valor é recuperado como data de calendário sem horário ou deslocamento UTC.

### CA-10 — Persistir lembrete como instante

**Dado** que uma tarefa possui lembrete, **quando** é persistida e recuperada
em outro fuso de apresentação, **então** o mesmo instante é convertido para o
horário local sem alterar o valor persistido.

### CA-11 — Persistir entradas do My Day

**Dado** que tarefas foram adicionadas a uma data do My Day em ordem manual,
**quando** o aplicativo é reaberto no mesmo dia, **então** as entradas e a
ordem são preservadas sem alterar a lista de origem.

### CA-12 — Remover concluída do My Day

**Dado** que uma tarefa possui entrada no My Day, **quando** é concluída,
**então** sua entrada ativa é removida e a tarefa permanece disponível em
Concluídas.

### CA-13 — Preservar tarefa na lixeira

**Dado** que uma tarefa com subtarefas é excluída, **quando** a operação é
confirmada, **então** a hierarquia permanece armazenada na lixeira com os
metadados necessários à restauração.

### CA-14 — Restaurar hierarquia

**Dado** que uma tarefa e sua hierarquia estão na lixeira, **quando** são
restauradas, **então** estrutura, posições, dados e estados anteriores são
recuperados sem criar cópias.

### CA-15 — Criar ocorrência ligada à série

**Dado** que uma tarefa recorrente foi concluída, **quando** a próxima
ocorrência é criada, **então** ela possui novo UUID e permanece ligada à mesma
série recorrente.

### CA-16 — Preservar ocorrência anterior

**Dado** que uma ocorrência recorrente foi concluída, **quando** a próxima é
gerada, **então** a ocorrência anterior permanece intacta no histórico.

### CA-17 — Não copiar subtarefas

**Dado** que a ocorrência anterior possui subtarefas, **quando** a próxima
ocorrência é criada, **então** nenhuma dessas subtarefas é copiada.

### CA-18 — Preservar UUIDs

**Dado** que entidades foram criadas, **quando** são editadas, movidas,
restauradas ou migradas, **então** seus UUIDs permanecem estáveis.

### CA-19 — Preservar dados após migração

**Dado** que existe uma base em uma versão anterior, **quando** uma migração
válida é aplicada, **então** os dados, relações, estados e histórico são
preservados no novo esquema.

### CA-20 — Rollback de migração

**Dado** que uma etapa de migração falha, **quando** a operação termina,
**então** nenhuma alteração parcial permanece na base.

### CA-21 — Bloquear base incompatível

**Dado** que a migração não pôde ser concluída, **quando** o aplicativo tenta
abrir a base, **então** a abertura normal é bloqueada e a incompatibilidade é
informada.

### CA-22 — Evitar cascatas indevidas

**Dado** que existem relações entre tarefas, listas, grupos, categorias e
tags, **quando** um vínculo é removido, **então** somente os registros
permitidos pela regra de domínio são alterados.

### CA-23 — Manter ordenação determinística

**Dado** que itens foram reordenados, **quando** a operação é persistida e a
base é reaberta, **então** a mesma ordem é apresentada sem posições
duplicadas.

### CA-24 — Testar em banco isolado

**Dado** que um teste de persistência é executado, **quando** ele cria,
altera e remove dados, **então** o resultado não depende de dados reais nem
interfere em outros testes.

## 13. Dependências e próximos documentos

Esta especificação deverá ser usada como entrada para:

- implementação das features e repositórios Drift;
- [especificação de backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md);
- [especificação de notificações por plataforma](08-notificacoes-por-plataforma.md);
- [especificação de internacionalização](09-internacionalizacao.md);
- [especificação de validação multiplataforma](10-validacao-multiplataforma.md);
- validação das migrações e da experiência Web.

O modelo local deverá continuar sendo a fonte de verdade do aplicativo no
MVP. Qualquer integração futura, incluindo Google Drive, deverá ser isolada
por adaptador e não poderá tornar a persistência local dependente de conta ou
serviço externo.
