# Registro 0007: Fatia 07 — Internacionalização (preferência de idioma)

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Internacionalização](../specs/09-internacionalizacao.md)
  (RF-01 a RF-04 e CA-01 a CA-09)
- **Branch:** `Mimo-2.6-Flash`
- **Depende de:** Registros 0001–0006

## 1. Resultado obtido

Sétima fatia funcional do MVP entregue:

- **resolvedor de locale testável** (`resolveAppLocale`): variantes
  regionais casam com o idioma-base (`pt-PT`→`pt-BR`, `en-GB`→`en`,
  `es-MX`→`es` — CA-01/CA-02), percorre a lista completa de preferidos do
  sistema (RF-02) e fallback explícito para `pt-BR` independente da ordem
  de `supportedLocales` (CA-03);
- **preferência manual** (RF-03/CA-04): quatro opções — Automático
  (sistema), Português (Brasil), English, Español — aplicadas
  imediatamente sem reinício, persistidas com `shared_preferences`
  (sobrevivem a reinícios da árvore) e reversíveis para o modo
  automático;
- **preferência fora do backup** (RF-02/CA-09): armazenada fora do banco,
  portanto fora do retrato lógico — teste de exportação confirma que o
  JSON nunca contém a chave;
- **formatos pela região do dispositivo** (RF-04/CA-06):
  `formatDeviceDate/DateTime/Time` usam o locale do sistema mesmo quando
  o idioma da interface difere; `initializeDateFormatting()` carrega
  símbolos de todas as regiões na subida do app;
- diálogo de **Configurações** acessível pelo ícone de engrenagem na
  aba Listas;
- i18n: novas chaves (`close`, seção de configurações) em `pt-BR`,
  `en` e `es`.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 175 testes |
| `flutter test --platform chrome` (domínio/aplicação/resolvedor) | aprovado, 110 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `./tool/web-smoke.sh` → `All tests passed` |

Ambiente do gate: idêntico ao
[Registro 0001](0001-fatia-01-ciclo-de-tarefas.md) — macOS 26.6.2 arm64,
Flutter 3.47.0 (`4cf2416426`), Chrome Stable 153.0.8010.53,
ChromeDriver 153.0.8010.52.

## 3. Cobertura dos critérios de aceitação

- CA-01/CA-02/CA-03: resolvedor de locale (unitário, inclui lista do
  sistema com idiomas sem tradução e fallback `pt-BR`).
- CA-04: widget de configurações — troca imediata, persistência após
  reinício da árvore e retorno ao modo automático.
- CA-05: tarefa criada permanece intacta ao trocar de idioma (widget).
- CA-06: `formatDeviceDate` com região `es-MX` vs `en-US` produz
  formatos distintos enquanto os textos seguem o idioma do app
  (unitário + uso nos campos de prazo/lembrete e no resumo de import).
- CA-07: chaves obrigatórias presentes nos três locales (`gen-l10n`
  falha a compilação se faltar — validação contínua).
- CA-08: nenhuma chave interna aparece na interface (todos os textos
  passam pelos recursos de tradução).
- CA-09: teste de exportação após definir a preferência — o JSON não
  contém a chave da preferência.

## 4. Limitações, desvios e aprendizados

- **Bug real pescado:** `Locale('pt-BR')` (tag completa em uma string)
  tem `languageCode == 'pt-BR'`, não `'pt'`; o resolvedor agora normaliza
  o idioma-base separando por `-`/`_`, e o fallback para `pt-BR` deixou
  de depender da ordem de `supportedLocales` (que começa em `en`).
- Testes de widget usam `SharedPreferences.setMockInitialValues` no
  helper; simular reinício com o banco real pendurava o `pumpAndSettle`
  (spinner infinito sem path_provider) — o reinício reutiliza o banco em
  memória do teste via `currentTestDatabase`.
- Ao voltar para o modo automático durante o diálogo, os rótulos já
  mudam para o novo idioma antes do próximo toque (`Fechar` vs `Close`).
- `initializeDateFormatting()` do `intl` ignora o parâmetro e carrega
  todos os símbolos — chamado uma vez no `main`.

## 5. Intervenções humanas

- Instrução para prosseguir após a entrega da fatia 06 (opção entre
  specs 08 e 09 tomada pelo agente: 09 primeiro por fechar o critério 12
  do MVP).
