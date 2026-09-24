# Especificação SDD: Backup, Restauração e Formato Aberto

- **Status:** proposta para implementação
- **Versão:** 1.0
- **Escopo:** backup lógico local, restauração e intercâmbio em JSON

## 1. Contexto

Esta especificação define como o Urutau Tasks exporta, importa e restaura os
dados locais do usuário. Ela complementa as especificações de tarefas,
organização, visões, prazos, busca e persistência.

O projeto oferece duas formas complementares de portabilidade:

- um backup lógico completo, protegido por senha e destinado à restauração
  fiel dos dados no aplicativo;
- um arquivo JSON aberto, legível e versionado, destinado à inspeção,
  interoperabilidade e migração.

As decisões de arquitetura que fundamentam esses formatos estão registradas
no [ADR de backup e formato aberto](../decisoes/0001-backup-e-formato-aberto.md).

## 2. Objetivo

Permitir que o usuário salve e recupere todo o estado persistido do aplicativo
ou transfira seus dados por um formato independente do banco SQLite/Drift,
sem depender de contas, servidores ou serviços externos.

## 3. Terminologia

### 3.1 Conjunto de dados

Todos os registros persistidos que representam conteúdo e estado do usuário,
conforme o modelo lógico definido nesta especificação e nas especificações
relacionadas.

### 3.2 Backup lógico

Arquivo criptografado que contém um retrato versionado do conjunto de dados,
independente da representação física do banco local.

### 3.3 Formato aberto

Arquivo JSON UTF-8, legível sem senha, que contém o conjunto de dados completo
em um contrato versionado independente do esquema interno do banco.

### 3.4 Importação ou restauração

Operação que valida um arquivo e, após confirmação explícita do usuário,
substitui integralmente os dados locais pelo conjunto de dados do arquivo.

## 4. Conteúdo e identidade dos dados

### RF-01 — Conjunto completo

Backup, exportação e importação deverão incluir todos os dados persistidos
definidos pelas especificações atuais, incluindo:

- tarefas ativas, concluídas e na lixeira, com títulos, notas, prioridades,
  prazos, lembretes, estados e metadados necessários à restauração;
- subtarefas e suas relações, posições e estados;
- listas, grupos, categorias, tags e associações entre tarefas e tags;
- séries recorrentes, regras e todas as ocorrências preservadas no histórico;
- entradas do My Day, incluindo data local e posição.

O conteúdo exportado deverá preservar os campos e relações definidos nas
[especificações de tarefas](01-tarefas-e-subtarefas.md), de
[organização](02-listas-grupos-categorias-tags.md), de
[prazos e recorrência](04-prazos-lembretes-e-recorrencia.md) e de
[persistência](06-persistencia-drift-e-migracoes.md).

### RF-02 — Dados excluídos do arquivo

O arquivo não deverá incluir visões calculadas, caches, índices reconstruíveis
ou identificadores de notificações mantidos pelo sistema operacional. A
configuração de lembrete associada à tarefa deverá ser incluída; o
agendamento efetivo deverá ser reconstruído pelos adaptadores de notificação
após a restauração, quando a plataforma oferecer suporte, conforme a
[especificação de notificações por plataforma](08-notificacoes-por-plataforma.md).

Anexos não fazem parte do MVP. Preferências do sistema operacional e dados de
apresentação que não pertençam ao modelo persistido do aplicativo também não
fazem parte do arquivo. A preferência local de idioma da interface está
excluída, conforme a [especificação de internacionalização](09-internacionalizacao.md).

### RF-03 — Preservar identidade e relações

Todos os UUIDs deverão ser preservados sem alteração. Referências entre
registros deverão continuar apontando para os mesmos UUIDs após exportação,
importação ou restauração.

Uma operação não deverá gerar novas cópias de registros nem reconstruir
identidades a partir de títulos ou nomes.

### RF-04 — Preservar semântica de datas

Prazos e datas do My Day deverão permanecer datas locais de calendário no
formato ISO YYYY-MM-DD, sem conversão para timestamp UTC.

Lembretes deverão permanecer instantes UTC, conforme a especificação de
persistência. Ao restaurar em outro fuso, a apresentação local poderá mudar,
mas o instante salvo não deverá ser alterado.

Datas-base de recorrência deverão preservar a semântica de calendário
definida na especificação de prazos e recorrência.

## 5. Backup lógico

### RF-05 — Criar backup manual

O usuário deverá iniciar a criação do backup explicitamente e escolher o
destino do arquivo usando o mecanismo de arquivo disponível na plataforma.
O MVP não deverá criar backups periódicos ou automáticos, nem enviar arquivos
a serviços externos.

Cada operação deverá produzir um único arquivo de backup lógico.

### RF-06 — Criptografar com senha

O backup completo deverá ser criptografado com uma senha definida pelo
usuário. A senha será solicitada novamente durante a restauração e não deverá
ser armazenada pelo aplicativo nem enviada a um serviço externo.

A perda da senha tornará o backup inacessível. O aplicativo não oferecerá
recuperação por conta, servidor ou código alternativo e deverá informar essa
limitação antes de concluir a exportação.

A implementação deverá usar uma biblioteca mantida e proteção autenticada
adequada a arquivos protegidos por senha. A escolha da biblioteca, dos
algoritmos e dos parâmetros criptográficos deverá ser registrada em decisão
técnica antes da implementação, conforme o ADR relacionado.

### RF-07 — Versionar o retrato lógico

O retrato do backup deverá conter uma versão de formato monotônica,
independente da versão do esquema SQLite/Drift. O arquivo também deverá
conter o instante UTC de criação, para identificação e apresentação no resumo
antes da restauração.

A restauração deverá converter o formato lógico para o modelo aceito pela
versão atual do aplicativo. Não deverá abrir nem substituir diretamente o
banco SQLite por uma cópia física do arquivo.

### RF-08 — Restaurar entre plataformas

Um backup deverá poder ser restaurado em qualquer plataforma suportada pelo
aplicativo, desde que a versão instalada reconheça o formato do arquivo.

Formatos antigos só poderão ser restaurados se existir uma conversão
determinística suportada. Formatos desconhecidos ou mais novos deverão ser
rejeitados sem modificar os dados locais.

## 6. Formato aberto JSON

### RF-09 — Exportar arquivo legível

O usuário deverá poder exportar o conjunto completo para um único arquivo
JSON codificado em UTF-8. O arquivo não será criptografado. Antes da
exportação, a interface deverá informar que o conteúdo é legível e inclui
dados pessoais, como notas e lembretes.

### RF-10 — Estrutura da versão 1

A versão 1 do formato aberto deverá ser um objeto JSON com:

- **format_version**: inteiro obrigatório, igual a 1 nesta versão do
  documento;
- **exported_at**: instante UTC em formato ISO 8601;
- **data**: objeto obrigatório contendo arrays para **tasks**, **subtasks**,
  **lists**, **groups**, **categories**, **tags**, **task_tags**,
  **recurring_series** e **my_day_entries**.

Todos os arrays deverão estar presentes, inclusive quando vazios. Cada
registro deverá conter os campos lógicos e UUIDs definidos pelas
especificações correspondentes, sem expor detalhes internos do banco.

O campo **format_version** não deverá ser confundido com a versão do esquema
Drift. Uma mudança incompatível no contrato JSON deverá introduzir uma nova
versão do formato.

### RF-11 — Exportação completa

O formato aberto deverá exportar o conjunto de dados completo. Exportação
parcial por lista, grupo, categoria ou seleção manual não fará parte do MVP.

### RF-12 — Importar sem mesclar

Uma importação JSON deverá substituir integralmente os dados locais após
validação e confirmação explícita. A importação não deverá mesclar registros,
ignorar duplicatas ou resolver conflitos por nome.

### RF-13 — Validar versão e estrutura

O aplicativo deverá validar a estrutura JSON, os tipos dos campos, a versão
do formato, a unicidade de UUIDs e a integridade das referências entre
registros antes de alterar o banco local.

Uma versão antiga só será aceita se houver conversor explícito para a versão
atual. Uma versão desconhecida, mais nova ou com estrutura incompatível
deverá ser rejeitada. Campos não reconhecidos que possam conter dados não
poderão ser descartados silenciosamente.

## 7. Fluxo de importação e restauração

### RF-14 — Validar antes de substituir

O aplicativo deverá concluir leitura, descriptografia quando aplicável e
validação antes de iniciar qualquer alteração nos dados locais.

O resumo deverá apresentar o tipo de arquivo, a data de exportação e a
quantidade de tarefas por estado, subtarefas, listas, grupos, categorias,
tags, séries recorrentes e entradas do My Day.

### RF-15 — Confirmar substituição integral

Antes da troca, a interface deverá informar claramente que todos os dados
atuais serão substituídos pelos dados do arquivo e solicitar confirmação
explícita.

Cancelar ou fechar o fluxo antes da confirmação deverá deixar o conjunto
local inalterado.

### RF-16 — Troca atômica

Após confirmação, a substituição dos dados deverá ocorrer em uma transação
atômica. Se qualquer etapa falhar, a transação deverá realizar rollback e os
dados locais anteriores deverão permanecer disponíveis sem alterações
parciais.

Após o commit, o aplicativo deverá atualizar as projeções derivadas e pedir
que os adaptadores de notificação reconstruam os agendamentos aplicáveis a
partir das configurações de lembrete restauradas.

### RF-17 — Preservar configurações após falha

Senha incorreta, falha de autenticação, arquivo truncado, JSON malformado,
versão incompatível, UUID duplicado ou referência inválida deverão encerrar
a operação com uma mensagem compreensível e sem alterar os dados locais.

## 8. Fora do escopo

Não fazem parte desta especificação:

- sincronização entre dispositivos ou serviços de nuvem;
- backups agendados ou automáticos;
- mesclagem de bancos ou arquivos;
- importação e exportação parciais;
- anexos;
- recuperação de senha;
- detalhes da biblioteca, do algoritmo e dos parâmetros criptográficos;
- implementação de APIs públicas, widgets ou seletores de arquivo específicos
  de cada plataforma.

## 9. Critérios de aceitação

### CA-01 — Exportar conjunto completo

**Dado** que existem tarefas em estados ativos, concluídos e na lixeira, além
de relações e dados auxiliares
**Quando** o usuário exporta um backup ou JSON
**Então** o arquivo contém o conjunto completo e preserva os UUIDs e relações.

### CA-02 — Preservar histórico e estrutura

**Dado** que existem subtarefas, recorrências com ocorrências anteriores,
listas, grupos, tags e entradas do My Day
**Quando** o usuário restaura ou importa o arquivo
**Então** esses dados mantêm sua estrutura, estado, posição e identidade.

### CA-03 — Preservar semântica temporal

**Dado** que tarefas possuem prazos, lembretes e datas do My Day
**Quando** os dados são exportados e importados
**Então** prazos e datas do My Day permanecem datas locais e lembretes
permanecem os mesmos instantes UTC.

### CA-04 — Proteger o backup com senha

**Dado** que o usuário cria um backup
**Quando** escolhe uma senha e conclui a exportação
**Então** o arquivo não pode ser restaurado sem a senha correta e o
aplicativo informa que a senha perdida não poderá ser recuperada.

### CA-05 — Exportar JSON legível

**Dado** que o usuário escolhe exportar em formato aberto
**Quando** confirma a exportação
**Então** recebe um único JSON UTF-8 versão 1 e é informado de que ele não é
criptografado.

### CA-06 — Restaurar entre plataformas

**Dado** que um backup foi criado em uma plataforma suportada
**Quando** ele é restaurado em outra plataforma com suporte à sua versão
**Então** o conjunto lógico de dados é recuperado com os mesmos UUIDs e relações.

### CA-07 — Resumir antes da substituição

**Dado** que um arquivo válido foi escolhido
**Quando** a validação termina
**Então** o aplicativo mostra data e contagens por tipo e estado antes de
solicitar confirmação.

### CA-08 — Cancelar sem alterar dados

**Dado** que o resumo do arquivo está aberto
**Quando** o usuário cancela
**Então** os dados locais permanecem inalterados.

### CA-09 — Substituir integralmente após confirmação

**Dado** que o arquivo foi validado e o usuário confirmou a operação
**Quando** a importação ou restauração termina com sucesso
**Então** os dados locais anteriores foram substituídos integralmente pelo
conjunto de dados do arquivo.

### CA-10 — Reverter falha durante substituição

**Dado** que ocorre uma falha ao gravar os dados importados
**Quando** a operação termina
**Então** a transação é revertida e os dados locais anteriores permanecem
íntegros.

### CA-11 — Rejeitar senha incorreta ou corrupção

**Dado** que o arquivo criptografado tem senha incorreta ou falha de
autenticação
**Quando** o usuário tenta restaurá-lo
**Então** o aplicativo rejeita o arquivo e não altera os dados locais.

### CA-12 — Rejeitar JSON inválido

**Dado** que o arquivo aberto está malformado, contém UUID duplicado ou
referência inconsistente
**Quando** o usuário tenta importá-lo
**Então** o aplicativo informa a falha e não altera os dados locais.

### CA-13 — Rejeitar formato incompatível

**Dado** que o arquivo usa uma versão desconhecida ou mais nova do formato
**Quando** o aplicativo tenta validá-lo
**Então** a operação é rejeitada sem modificar o conjunto local.

### CA-14 — Usar versão antiga com conversor

**Dado** que o arquivo usa uma versão antiga com conversor suportado
**Quando** o aplicativo importa ou restaura o arquivo
**Então** os dados são convertidos deterministicamente e preservados.

## 10. Dependências e documentos relacionados

Esta especificação depende das regras definidas em:

- [tarefas e subtarefas](01-tarefas-e-subtarefas.md);
- [listas, grupos, categorias e tags](02-listas-grupos-categorias-tags.md);
- [visões inteligentes e My Day](03-visoes-inteligentes-e-my-day.md);
- [prazos, lembretes e recorrência](04-prazos-lembretes-e-recorrencia.md);
- [busca e filtros](05-busca-e-filtros.md);
- [persistência Drift e migrações](06-persistencia-drift-e-migracoes.md);
- [notificações por plataforma](08-notificacoes-por-plataforma.md);
- [internacionalização](09-internacionalizacao.md);
- [validação multiplataforma](10-validacao-multiplataforma.md).

O formato aberto deverá continuar independente da representação física da
persistência. Nenhuma mudança de esquema poderá tornar os arquivos antigos
ilegíveis sem uma estratégia de conversão documentada.
