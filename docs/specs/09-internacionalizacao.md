# Especificação SDD: Internacionalização

**Status:** proposta para implementação

**Versão:** 1.0

**Escopo:** idiomas da interface e formatos regionais do Urutau Tasks

## 1. Contexto

Esta especificação detalha os princípios de internacionalização definidos nos
[princípios técnicos](../03-principios-tecnicos.md) e no
[escopo do MVP](../04-escopo-do-mvp.md). O MVP oferece a interface em
português do Brasil, inglês e espanhol.

Idioma da interface e região de formatação são preferências distintas. A
seleção de idioma não poderá alterar tarefas ou dados de calendário; datas e
instantes mantêm a semântica definida nas especificações de prazos, persistência
e notificações.

## 2. Objetivo

Definir como selecionar o idioma da interface, como formatar datas e números,
quais textos devem ser traduzidos e como assegurar que a mudança de idioma
preserve todos os dados do usuário.

## 3. Idiomas e resolução do locale

### RF-01 — Idiomas do MVP

A interface deverá oferecer estes locales:

| Idioma | Locale da interface |
| --- | --- |
| Português do Brasil | `pt-BR` |
| Inglês | `en` |
| Espanhol | `es` |

Variantes regionais do sistema deverão corresponder ao idioma disponível pela
parte-base do locale. Por exemplo, `en-GB` corresponde a `en`, e `es-MX`
corresponde a `es`. Como o MVP oferece somente `pt-BR`, qualquer locale cujo
idioma-base seja português deverá corresponder a `pt-BR`.

### RF-02 — Idioma automático do sistema

Na primeira abertura e enquanto a preferência do app estiver em **Automático
(sistema)**, o aplicativo deverá percorrer a lista de locales preferidos do
sistema e usar o primeiro idioma-base que tiver tradução disponível.

Se nenhum idioma preferido for suportado, a interface deverá usar `pt-BR`.
Essa resolução afeta somente os textos do aplicativo; não altera as
preferências nem os dados do sistema operacional.

### RF-03 — Substituição manual

As configurações do aplicativo deverão oferecer **Automático (sistema)**,
**Português (Brasil)**, **English** e **Español**. A escolha manual deverá ser
salva localmente neste dispositivo, sobreviver a reinícios do aplicativo e
ser aplicada imediatamente, sem exigir reinício.

Selecionar **Automático (sistema)** remove a substituição manual e volta a
seguir a lista de locales do sistema. Uma preferência manual de idioma é dado
de apresentação da instalação: não será sincronizada nem incluída em backup,
exportação, importação ou restauração, conforme a
[especificação de backup](07-backup-restauracao-formato-aberto.md).

### RF-04 — Separar idioma e região

Os textos estáticos da interface deverão usar o idioma selecionado em RF-02
ou RF-03. Formatos de data, hora, número e início da semana deverão usar a
região definida no sistema operacional, mesmo quando ela for diferente do
idioma da interface.

Quando o sistema operacional alterar sua configuração regional, os formatos
deverão ser atualizados na próxima atualização de locale do aplicativo. A
alteração de idioma ou região não deverá regravar valores persistidos.

## 4. Tradução e conteúdo

### RF-05 — Textos traduzidos

Todos os textos estáticos visíveis ao usuário deverão vir de recursos de
tradução centralizados. Isso inclui, no mínimo:

- navegação, ações, nomes de campos e opções;
- títulos, descrições, estados vazios e mensagens de confirmação;
- validação, erros, sucesso e avisos de disponibilidade;
- rótulos acessíveis, nomes de botões e dicas de uso;
- mensagens dentro do app associadas a lembretes;
- singular, plural, contagens e variáveis inseridas em frases.

Cada texto exigido pelo MVP deverá ter uma tradução revisada em `pt-BR`, `en`
e `es`. Chaves internas de tradução não deverão aparecer na interface; a
ausência de uma mensagem em qualquer idioma será uma falha de validação da
localização. Textos fornecidos pelo sistema operacional, como diálogos de
permissão, permanecem sob localização do próprio sistema.

### RF-06 — Dados escritos pelo usuário

Títulos, notas, nomes de listas, categorias, tags e demais textos criados pelo
usuário deverão permanecer exatamente como foram salvos ao trocar o idioma.
O aplicativo não traduzirá conteúdo do usuário automaticamente.

### RF-07 — Datas, horários e valores

Datas, horários e números apresentados na interface deverão usar os formatos
regionais apropriados e APIs de formatação localizadas; formatos internos ou
serializados não deverão ser exibidos como texto de interface.

- Prazos e datas do My Day continuarão sendo datas de calendário local, sem
  horário ou conversão UTC.
- Lembretes continuarão sendo instantes UTC persistidos e serão apresentados
  no fuso local, conforme as especificações de persistência e notificações.
- A troca de idioma ou região não alterará instantes, datas, ordenação ou
  relações persistidas.

## 5. Critérios de aceitação

### CA-01 — Idioma do sistema suportado

**Dado** que nenhum idioma manual foi escolhido e o sistema prefere um locale
suportado, **quando** o app inicia, **então** a interface usa a tradução
correspondente ao primeiro idioma suportado da lista do sistema.

### CA-02 — Locale regional equivalente

**Dado** que o sistema prefere uma variante regional de inglês, espanhol ou
português, **quando** o locale é resolvido, **então** o app usa `en`, `es` ou
`pt-BR`, respectivamente.

### CA-03 — Fallback português do Brasil

**Dado** que nenhum locale preferido do sistema corresponde aos idiomas
suportados, **quando** a interface é carregada, **então** o idioma usado é
`pt-BR`.

### CA-04 — Substituir e restaurar modo automático

**Dado** que o app está em modo automático, **quando** o usuário escolhe outro
idioma, **então** os textos mudam imediatamente e a escolha permanece após
fechar e reabrir o app; ao escolher **Automático (sistema)**, o idioma volta a
seguir o sistema.

### CA-05 — Preservar dados ao trocar idioma

**Dado** que existem tarefas, notas, listas, categorias e tags, **quando** o
idioma é alterado, **então** o conteúdo criado pelo usuário permanece
inalterado.

### CA-06 — Formatação regional independente

**Dado** que o idioma da interface difere da região configurada no dispositivo,
**quando** são exibidas datas, horas, números ou início da semana, **então** os
textos seguem o idioma do app e os formatos seguem a região do dispositivo.

### CA-07 — Preservar semântica temporal

**Dado** que existem prazos, datas do My Day e lembretes, **quando** o usuário
altera idioma ou região, **então** os prazos e datas do My Day permanecem as
mesmas datas locais e os lembretes permanecem os mesmos instantes UTC.

### CA-08 — Cobertura de traduções

**Dado** que os recursos de tradução são verificados, **quando** uma mensagem
obrigatória estiver ausente em `pt-BR`, `en` ou `es`, **então** a validação
falha e a chave interna não é apresentada ao usuário.

### CA-09 — Preferência fora do backup

**Dado** que a instalação possui uma substituição manual de idioma, **quando**
os dados são exportados e restaurados em outra instalação, **então** a
preferência não faz parte do arquivo e a configuração de idioma da instalação
de destino permanece inalterada.

## 6. Fora do escopo

Não fazem parte desta especificação:

- tradução automática de conteúdo criado pelo usuário;
- idiomas além de `pt-BR`, `en` e `es`;
- escolha manual de região ou fuso horário dentro do aplicativo;
- escolha de pacote, formato de recurso ou ferramenta de geração de traduções.

## 7. Documentos relacionados

- [Escopo do MVP](../04-escopo-do-mvp.md);
- [Princípios técnicos](../03-principios-tecnicos.md);
- [Visões inteligentes e My Day](03-visoes-inteligentes-e-my-day.md);
- [Busca e filtros](05-busca-e-filtros.md);
- [Persistência Drift e migrações](06-persistencia-drift-e-migracoes.md);
- [Backup, restauração e formato aberto](07-backup-restauracao-formato-aberto.md);
- [Notificações por plataforma](08-notificacoes-por-plataforma.md).
