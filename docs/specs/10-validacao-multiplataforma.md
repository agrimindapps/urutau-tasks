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
| Windows | Nenhum mínimo de versão definido | Versão Windows, arquitetura e versão/revisão Flutter |

A entrada de cada ensaio deverá conter data, plataforma, ambiente, categorias
de testes executadas, resultado, evidência ou log e limitações conhecidas.
Valores desconhecidos deverão ser marcados como não registrados, nunca
presumidos.

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
mesma família de plataforma.

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
