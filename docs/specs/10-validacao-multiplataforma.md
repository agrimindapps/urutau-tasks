# Especificação SDD: Validação multiplataforma

**Status:** proposta para implementação

**Versão:** 1.0

**Escopo:** critérios e registro das validações nas seis plataformas do MVP

## 1. Contexto

O Urutau Tasks é construído em Flutter para Android, iOS, Web, Linux, macOS e
Windows. A Web é a plataforma principal de validação. As demais fazem parte do
escopo do produto, mas serão verificadas manualmente em marcos importantes,
conforme a [estratégia de processo e ferramentas](../02-processo-e-ferramentas.md).

Esta especificação define as verificações bloqueantes, os cenários manuais e
as evidências mínimas por plataforma. Ela registra a política de validação;
workflows de CI e testes do aplicativo serão implementados em etapas próprias.

## 2. Objetivo

Manter um conjunto de verificações reproduzível para o fluxo principal do
produto, detectar regressões na Web durante o trabalho normal e registrar
compatibilidade observada nas cinco plataformas adicionais sem criar uma
promessa de suporte maior que a matriz efetivamente verificada.

## 3. Níveis de validação

### 3.1 Bloqueante — Web

As alterações só serão consideradas validadas no fluxo normal quando passarem:

- análise estática do código;
- testes automatizados unitários e de widget aplicáveis;
- build de produção para Web;
- smoke test automatizado no Chrome Stable para inicialização, navegação e
  fluxo principal.

A versão do Chrome Stable e do Flutter deverá ser registrada em cada resultado.
Chrome Stable será o único navegador bloqueante do MVP. Verificações em
Firefox, Edge, Safari ou outros navegadores poderão ser feitas e registradas
como exploratórias, sem serem gate de CI.

### 3.2 Manual por marco — demais plataformas

Em cada marco importante do produto, deverá haver uma verificação manual em
Android, iOS, Linux, macOS e Windows. Em cada sistema será usado ao menos um
ambiente representativo; a matriz registrará dispositivo ou ambiente, versão
do sistema operacional, arquitetura e versão/revisão do Flutter.

As verificações dessas cinco plataformas são não bloqueantes para o fluxo
normal de mudanças. Falhas, incompatibilidades e itens não executados deverão
ser registrados com evidência e situação conhecida, sem serem reportados como
validação aprovada.

## 4. Matriz e versões registradas

O repositório já declara iOS 15.0 e macOS 12.0 como deployment targets. O alvo
mínimo Android permanece o `flutter.minSdkVersion` definido pela versão do SDK
Flutter usada para a build. Nenhum mínimo adicional será estabelecido nesta
especificação para navegador, distribuição Linux ou Windows.

Cada rodada deverá registrar a matriz abaixo. A versão ensaiada não cria, por
si só, compromisso de compatibilidade com todas as versões posteriores ou
anteriores.

| Plataforma | Mínimo declarado nesta rodada | Ambiente a registrar |
| --- | --- | --- |
| Web | Nenhum mínimo de navegador; Chrome Stable é o gate | Sistema hospedeiro, arquitetura, versão do Chrome e versão/revisão Flutter |
| Android | `flutter.minSdkVersion` do SDK Flutter usado | Versão Android, dispositivo ou emulador, arquitetura e versão/revisão Flutter |
| iOS | iOS 15.0 | Versão iOS, dispositivo ou simulador, arquitetura e versão/revisão Flutter |
| Linux | Nenhum mínimo de distribuição definido | Distribuição/versão, ambiente desktop, arquitetura e versão/revisão Flutter |
| macOS | macOS 12.0 | Versão macOS, arquitetura e versão/revisão Flutter |
| Windows | Windows 10 versão 1809 (`10.0.17763.0`) para o pacote MSIX configurado no ADR-0004 | Versão Windows, arquitetura e versão/revisão Flutter |

A entrada de cada ensaio deverá conter data, plataforma, ambiente, categorias
de testes executadas, resultado, evidência ou log e limitações conhecidas.
Valores desconhecidos deverão ser marcados como não registrados, nunca
presumidos.

### 4.1 Registro do marco do MVP — 2026-09-24

Ambiente disponível: Debian GNU/Linux 13 (trixie), Linux
`6.6.141-09476-g954adab60416`, arquitetura `x86_64`. Flutter `3.47.2`
stable, revisão `d3b14c876900e553bc736ca19295fc09e3853e8e`, Dart `3.13.2`.
O Chrome instalado é Google Chrome for Testing `153.0.8010.52`; não foi
identificado como Chrome Stable e, por isso, não foi usado como evidência do
gate de navegador. Nenhum aparelho Android ou emulador estava conectado.

| Plataforma | Build/análise | Smoke test manual | Resultado e evidência |
| --- | --- | --- | --- |
| Web | `flutter analyze` no projeto inteiro passou e `flutter build web --release` passou em 2026-09-24, após os ajustes de localização, organização, associação de categorias/tags, bloqueio de edição na lixeira, reconciliação idempotente de lembretes, atualização do My Day no rollover, limite local do filtro “Próximos 7 dias” calculado por calendário, atualização de filtros relativos na virada local, exigência de datas no intervalo personalizado, criação contextual em Importante/Planejado, isolamento da data-base ao editar prazo de ocorrência concluída e fluxo de permissão por plataforma e detecção de suporte da API/Service Worker, calendário gregoriano UTC nos seletores de prazo e intervalo de busca, congelamento profundo do retrato de importação, uso compartilhado do parser de datas civis na recorrência e no lembrete recorrente, cacheamento do ranking de busca por tarefa, sincronização da aba de organização ao navegar por gesto, ocultação da ação de remover prazo em séries recorrentes ativas, preservação da região preferida do sistema ao resolver o idioma de interface, orientação Web quando a permissão exige ajuste nas configurações do site, atualização imediata dos resultados ao limpar a busca, remoção da mensagem de validação do título assim que o campo recebe conteúdo válido, rótulos de progresso por operação de portabilidade e rotulagem da aba de tarefas ativas, sinalização visual de tarefas concluídas nas listas, ocultação do botão de criação na aba Concluídas de cada lista e bloqueio de geração de duplicata ao concluir ocorrência histórica depois de existir ocorrência posterior. A compactação das posições do My Day ao concluir ou enviar tarefas à lixeira e a proteção da data-base/regra ao editar ocorrência recorrente anterior reaberta também foram compiladas. A ajuda de recorrência agora aparece apenas em tarefas ativas editáveis, com o texto atualizado nos quatro idiomas. O progresso de subtarefas nas listas usa uma observação compartilhada. A busca distingue selecionar explicitamente todas as opções de grupo, prioridade e prazo de não aplicar esses filtros. Os seletores de prazo/lembrete e o intervalo personalizado da busca incluem datas existentes fora de 1900–2200. `flutter build web --release` compilou em 65,9 s nesta rodada, após o ajuste do fallback de notificações em segundo plano | Não executado no Chrome Stable | Gate incompleto: testes automatizados e smoke no navegador Stable não foram executados. Build em `build/web`; Chrome disponível era for Testing `153.0.8010.52`. |
| Android | `flutter build apk --debug` passou em 2026-09-24 após os ajustes de bloqueio de edição na lixeira, reconciliação dos lembretes, atualização do My Day no rollover, limite local do filtro “Próximos 7 dias” calculado por calendário, atualização dos filtros relativos na virada local, exigência de datas no intervalo personalizado, criação contextual em Importante/Planejado, isolamento da data-base ao editar prazo de ocorrência concluída, consulta de disponibilidade da integração separada do estado de permissão, calendário gregoriano UTC nos seletores de prazo e intervalo de busca, congelamento profundo do retrato de importação, uso compartilhado do parser de datas civis na recorrência e no lembrete recorrente, cacheamento do ranking de busca por tarefa e sincronização da aba de organização ao navegar por gesto; após a proteção da data-base e da regra recorrente em ocorrências anteriores reabertas, a ajuda de recorrência passou a aparecer apenas em tarefas ativas editáveis e foi atualizada nos quatro idiomas; o progresso de subtarefas nas listas usa uma observação compartilhada; a busca distingue selecionar explicitamente todas as opções de grupo, prioridade e prazo de não aplicar esses filtros; os seletores de prazo/lembrete e o intervalo personalizado da busca incluem datas existentes fora de 1900–2200; após adotar um ícone monocromático dedicado para notificações, a build debug passou novamente nesta rodada em 13,3 s em `build/app/outputs/flutter-apk/app-debug.apk`; `flutter.minSdkVersion` do SDK usado é 24 | Não executado | APK debug compilado no marco; o manifesto mesclado declara `POST_NOTIFICATIONS` via plugin; não havia dispositivo ou emulador conectado. |
| Linux | `flutter build linux --release` passou em 2026-09-24 após os ajustes de bloqueio de edição na lixeira, reconciliação dos lembretes, atualização do My Day no rollover, limite local do filtro “Próximos 7 dias” calculado por calendário, atualização dos filtros relativos na virada local, exigência de datas no intervalo personalizado, criação contextual em Importante/Planejado, isolamento da data-base ao editar prazo de ocorrência concluída e consulta de disponibilidade do servidor D-Bus separada do estado de permissão, calendário gregoriano UTC nos seletores de prazo e intervalo de busca, congelamento profundo do retrato de importação, uso compartilhado do parser de datas civis na recorrência e no lembrete recorrente, cacheamento do ranking de busca por tarefa e sincronização da aba de organização ao navegar por gesto; após a proteção da data-base e da regra recorrente em ocorrências anteriores reabertas, a ajuda de recorrência passou a aparecer apenas em tarefas ativas editáveis e foi atualizada nos quatro idiomas; o progresso de subtarefas nas listas usa uma observação compartilhada; a busca distingue selecionar explicitamente todas as opções de grupo, prioridade e prazo de não aplicar esses filtros; os seletores de prazo/lembrete e o intervalo personalizado da busca incluem datas existentes fora de 1900–2200; a build release passou novamente nesta rodada em `build/linux/x64/release/bundle/urutau_tasks` | Não executado | Bundle x64 release compilado no Debian 13; interação em desktop não foi ensaiada. |
| iOS | Não executado | Não executado | Host Linux sem macOS/Xcode e sem simulador iOS. Alvo declarado permanece iOS 15.0. |
| macOS | Não executado | Não executado | Host Linux; build e execução requerem ambiente macOS. Alvo declarado permanece macOS 12.0. |
| Windows | Não executado | Não executado | Host Linux sem ambiente Windows para build, gerar/instalar o MSIX ou executar smoke test. A configuração do pacote declara mínimo Windows 10 versão 1809 (`10.0.17763.0`); a execução ainda não foi validada. |

Este registro separa compilação de execução manual. Ele não declara o gate Web
completo nem aprova o smoke test das plataformas em que somente a build foi
executada.

Após o ajuste do fallback em segundo plano, `flutter analyze --no-pub` passou e
as builds Web release, Android debug e Linux release passaram. O APK Android
foi recompilado após a correção do ícone pequeno de notificação.

Depois da inicialização explícita dos dados de formatação regional do `intl`
antes de montar a interface, `flutter analyze --no-pub` passou e as builds Web
release (53,7 s), Android debug (9,9 s) e Linux release passaram em
2026-09-24. Testes automatizados do app e smoke manual não foram executados
nesta rodada.

Após corrigir a atualização visual do campo de busca para consultas contendo
somente espaços, `flutter analyze --no-pub` passou e `flutter build web
--release --no-pub` compilou em 145,9 s em 2026-09-24. Testes e smoke manual
continuam não executados.

Após tornar crescente a marca temporal de criação das ocorrências recorrentes
para preservar sua ordem em empates de milissegundos ou retrocesso do relógio,
`flutter analyze --no-pub` passou e `flutter build apk --debug --no-pub`
compilou em 18,4 s em 2026-09-24. O smoke Android ainda não foi executado.

Após reagendar o rollover do My Day quando o locale do dispositivo muda,
`flutter analyze --no-pub` passou e `flutter build apk --debug --no-pub`
compilou em 30,0 s em 2026-09-24. O smoke Android ainda não foi executado.

Após preservar os mapeamentos quando o cancelamento de uma notificação nativa
falha, expor o estado de cancelamento não confirmado e evitar um temporizador
concorrente, `flutter analyze --no-pub` passou em 3,4 s;
`flutter build web --release --no-pub` compilou em 76,1 s e
`flutter build apk --debug --no-pub` em 14,5 s, em 2026-09-24. Smoke tests e
testes automatizados não foram executados.

Após definir My Day como visão inicial, `flutter analyze --no-pub` passou em
4,6 s; `flutter build web --release --no-pub` compilou em 60,3 s,
`flutter build apk --debug --no-pub` em 13,1 s, e a build Linux release também
passou, em 2026-09-24 com Flutter 3.47.2/Dart 3.13.2 no Debian 13 x86_64.
Nenhum smoke test ou teste automatizado foi executado nesta rodada; iOS, macOS
e Windows continuam sem build neste host.

Após incluir prazo, lembrete e prioridade nos cartões de tarefas,
`flutter analyze --no-pub` passou em 3,8 s.
`flutter build web --release --no-pub` compilou em 60,2 s,
`flutter build apk --debug --no-pub` em 11,7 s e a build Linux release passou,
em 2026-09-24 no mesmo ambiente Flutter 3.47.2/Dart 3.13.2 e Debian 13
x86_64. Smoke tests e testes automatizados não foram executados.

Após identificar lista, grupo ou ausência de lista nos cartões de visões
agregadas, `flutter analyze --no-pub` passou em 3,6 s.
`flutter build web --release --no-pub` compilou em 65,2 s,
`flutter build apk --debug --no-pub` em 11,4 s e a build Linux release passou
em 2026-09-24 com Flutter 3.47.2/Dart 3.13.2 no Debian 13 x86_64. Smoke tests
e testes automatizados não foram executados.

Após mostrar origem e metadados nos resultados da busca,
`flutter analyze --no-pub` passou em 5,9 s.
`flutter build web --release --no-pub` compilou em 60,1 s,
`flutter build apk --debug --no-pub` em 11,0 s e a build Linux release passou
em 2026-09-24, com Flutter 3.47.2/Dart 3.13.2 no Debian 13 x86_64. Smoke
tests e testes automatizados não foram executados.

Após sincronizar a indicação de prazo atrasado na tela de lista com a virada
da data local e o retorno do segundo plano, `flutter analyze --no-pub` passou
em 5,3 s; `flutter build web --release --no-pub` compilou em 69,1 s,
`flutter build apk --debug --no-pub` em 13,4 s e a build Linux release passou
em 2026-09-24, com Flutter 3.47.2/Dart 3.13.2 no Debian 13 x86_64. Não foram
executados testes automatizados nem smoke tests.

## 5. Cenários comuns de smoke test

### RF-01 — Inicialização e navegação

O aplicativo deverá iniciar sem erro fatal e permitir abrir as principais
áreas do MVP no tamanho de janela ou tela testado.

### RF-02 — Ciclo básico da tarefa

O ensaio deverá criar uma tarefa, editar seu título, concluir e reabrir a
tarefa, confirmando que as transições são visíveis e mantêm os dados.

### RF-03 — Persistência local

Após fechar e abrir novamente o aplicativo, a tarefa criada no ensaio deverá
continuar disponível, sem conta ou conexão de rede.

### RF-04 — Layout e interação

O ensaio deverá confirmar que a interface permanece utilizável no tamanho
testado, sem conteúdo essencial cortado. Dispositivos móveis deverão ser
operados por toque; Web e plataformas desktop deverão verificar teclado e
mouse, incluindo foco e ativação das ações principais.

### RF-05 — Integrações previstas

Quando uma rodada exercitar uma capacidade incluída no MVP, deverá validar o
fluxo conforme sua especificação relacionada: idioma e formatos regionais,
notificações locais e backup/importação/exportação. Ausência de permissão ou
capacidade deverá seguir o fallback documentado, sem perda de dados.

## 6. Registro de falhas e limitações

Um resultado `falhou`, `não executado` ou `não suportado` deverá incluir a
plataforma, o ambiente, o cenário afetado, o comportamento observado e a
referência ao registro de acompanhamento, quando houver.

Uma falha não Web não bloqueará o fluxo normal do MVP, mas não poderá ser
descrita como validada. Limitações conhecidas deverão permanecer visíveis na
matriz até serem corrigidas ou formalmente aceitas como limitação da
plataforma.

## 7. Critérios de aceitação

### CA-01 — Gate Web

**Dado** que uma mudança está pronta para integração, **quando** o conjunto
bloqueante Web é executado, **então** análise, testes automatizados, build Web
e smoke test no Chrome Stable passam antes de ser considerada validada.

### CA-02 — Ambiente do gate registrado

**Dado** que o gate Web foi executado, **quando** o resultado é registrado,
**então** contém as versões do Flutter e do Chrome Stable, arquitetura,
resultado e evidência.

### CA-03 — Rodada de marco nas seis plataformas

**Dado** que um marco importante foi concluído, **quando** a rodada de
validação é encerrada, **então** cada plataforma tem um resultado registrado
como aprovada, falhou ou não executada. Testes executados incluem ambiente e
evidência; itens não executados incluem o motivo e a lacuna conhecida.

### CA-04 — Fluxo principal nas plataformas verificadas

**Dado** que uma plataforma está sendo ensaiada, **quando** o smoke test comum
é executado, **então** o app inicia, permite navegar, criar/editar/concluir e
reabrir uma tarefa, e preserva a tarefa após reinício.

### CA-05 — Registrar falha não Web sem gate global

**Dado** que um cenário falha em Android, iOS, Linux, macOS ou Windows,
**quando** o resultado é registrado, **então** ele permanece visível como
falha conhecida e não é apresentado como aprovado, mas não bloqueia o fluxo
normal de mudanças.

### CA-06 — Sem promessa além da matriz

**Dado** que uma versão de sistema, distribuição ou navegador não aparece como
alvo declarado ou ambiente ensaiado, **quando** a compatibilidade é
comunicada, **então** nenhuma garantia será inferida apenas por pertencer à
mesma família de plataforma. No Windows, a versão mínima declarada pelo pacote
MSIX é a definida no ADR-0004; a compatibilidade observada continua limitada
aos ambientes ensaiados.

## 8. Fora do escopo

Não fazem parte desta especificação:

- criar ou alterar workflows de CI;
- selecionar versões mínimas de sistema além dos alvos já declarados;
- exigir que Android, iOS, Linux, macOS ou Windows passem em toda mudança;
- validar navegadores além do Chrome Stable como condição de integração;
- substituir os critérios funcionais definidos nas specs de cada feature.

## 9. Documentos relacionados

- [Processo e ferramentas de desenvolvimento](../02-processo-e-ferramentas.md);
- [Princípios técnicos](../03-principios-tecnicos.md);
- [Escopo do MVP](../04-escopo-do-mvp.md);
- [Tarefas e subtarefas](01-tarefas-e-subtarefas.md);
- [Busca e filtros](05-busca-e-filtros.md);
- [Internacionalização](09-internacionalizacao.md);
- [Notificações por plataforma](08-notificacoes-por-plataforma.md);
- [Backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md).
