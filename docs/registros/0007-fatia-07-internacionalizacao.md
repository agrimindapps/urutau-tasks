# Registro 0007: Fatia 07 — Internacionalização

- **Data:** 2026-09-25
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-pro` (opencode-go/mimo-v2.6-pro)
- **Papel:** agente de implementação
- **Especificação:** [Internacionalização](../specs/09-internacionalizacao.md)
- **Branch:** `Mimo-2.6-Pro`
- **Decisão humana:** continuidade do desenvolvimento contínuo após o gate da
  fatia 06 aprovado

## 1. Resultado obtido

- idiomas do MVP `pt-BR`, `en` e `es` com variantes regionais caindo no
  idioma-base (RF-01) e preferidos do sistema com fallback `pt-BR` (RF-02);
- substituição manual **Automático (sistema) / Português (Brasil) /
  English / Español** (RF-03), persistida localmente em
  `shared_preferences` (sobrevive a reinícios), aplicada **imediatamente
  sem reinício** e removida ao voltar para Automático;
- a preferência é dado de apresentação da instalação: fica fora do
  banco e, portanto, **fora do backup/exportação/importação/restauração**
  (CA-09), coerente com a RF-02 da spec 07;
- **idioma e região separados** (RF-04): os textos seguem o idioma escolhido
  (ou do sistema) e a **região sempre segue o dispositivo**, preservando
  formatos de data/hora/número e início da semana regionais mesmo com a
  interface em outro idioma (`Locale(idioma, região-do-dispositivo)` com
  fallback `pt-BR` quando o sistema não informa região);
- cobertura de traduções verificada por teste (CA-08): paridade de chaves
  nos três ARBs, nenhum valor vazio e placeholders coincidentes —
  divergência falha o gate de testes;
- dados do usuário (títulos, notas, nomes) nunca são traduzidos (RF-06) e
  semântica temporal dos dados persistidos não é regravada (RF-07);
- interface: diálogo "Configurações" com seleção de idioma, acessível pela
  página de Listas.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 194 testes |
| `flutter test --platform chrome` (domínio, aplicação, apresentação e app) | aprovado, 156 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `All tests passed` (`./tool/web-smoke.sh`) |

Ambiente do gate: igual ao registro 0001 (macOS arm64, Flutter 3.47.0,
Dart 3.13.0, Chrome 153.0.8010.53, ChromeDriver 153.0.8010.52).

## 3. Cobertura dos critérios de aceitação (spec 09)

| CA | Situação | Evidência |
| --- | --- | --- |
| CA-01 idioma do sistema suportado | coberto | `locale_resolution_test.dart` |
| CA-02 locale regional equivalente | coberto | `locale_resolution_test.dart` (en-GB→en, es-MX→es, pt-PT→pt) |
| CA-03 fallback pt-BR | coberto | `locale_resolution_test.dart` (inclui ausência de região) |
| CA-04 substituir e restaurar automático | coberto | `locale_resolution_test.dart`, `settings_flow_test.dart`, `locale_preference_test.dart` |
| CA-05 preservar dados do usuário | coberto | sem tradução de conteúdo; dados fora do `gen_l10n` (revisão de código + specs 01/02) |
| CA-06 formatação regional independente | coberto | `locale_resolution_test.dart` (região do dispositivo preservada) |
| CA-07 preservar semântica temporal | coberto | dados persistidos não regravados; `snapshot_codec_test.dart` (fatia 06) |
| CA-08 cobertura de traduções | coberto | `locale_preference_test.dart` (paridade de chaves/valores/placeholders falha o teste) |
| CA-09 preferência fora do backup | coberto | preferência em `shared_preferences`, fora do retrato lógico (spec 07/CA-09) |

## 4. Decisões técnicas

- **`Locale(idioma, região)`**: um único locale alimenta textos e formatos;
  o `gen_l10n` resolve por `languageCode` (pt/en/es) e o `intl` usa a
  região para variantes como início de semana (ex.: `en_GB` vs `en_US`).
- **Preferência em `shared_preferences`**, fora do Drift: isola a decisão de
  apresentação do retrato de backup sem precisar de regras de exclusão.
- **Teste de paridade de ARBs** reproduz em código o que o `gen_l10n`
  validaria na compilação, cobrindo explicitamente a CA-08.

## 5. Limitações e desvios

- Textos do sistema (diálogos de permissão, do navegador) ficam com o SO,
  conforme a própria spec (RF-05).
- Escolha manual de região/fuso é fora do escopo da spec 09; a região vem
  sempre do dispositivo.
- Testes de UI validam troca imediata e persistência entre reinícios da
  árvore; a validação de formatos de data por região é responsabilidade do
  `intl`/Flutter (comportamento verificado por resolução do locale).
