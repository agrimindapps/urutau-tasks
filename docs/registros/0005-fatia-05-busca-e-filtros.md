# Registro 0005: Fatia 05 — Busca e filtros

- **Data:** 2026-09-24
- **Ferramenta:** OpenCode CLI
- **Modelo:** `mimo-v2.6-flash` (opencode-go/mimo-v2.6-flash)
- **Papel:** agente de implementação
- **Especificações:** [Busca e filtros](../specs/05-busca-e-filtros.md)
- **Branch:** `Mimo-2.6-Flash`
- **Depende de:** Registros 0001–0004

## 1. Resultado obtido

Quinta fatia funcional do MVP entregue (sem mudança de esquema — projeção
pura dos dados existentes):

- busca textual global sobre título, notas e descrição de subtarefas
  (RF-01/RF-04), sempre retornando a tarefa principal única (RF-03/CA-18);
- correspondência parcial, sem distinção de caixa nem acentos, com
  normalização apenas na comparação (RF-05/CA-04/CA-05);
- debounce de 300 ms na apresentação (RF-06/CA-07); campo vazio delega aos
  filtros (RF-07);
- lixeira sempre excluída da busca normal (RF-02/CA-08);
- filtros estruturados combinados com AND entre categorias e OR dentro de
  cada categoria (RF-08/CA-12): status, listas (com **Sem lista**), grupos,
  categorias (com **Sem categoria**), tags (com **Sem tags**), prioridades,
  prazo (sem/atrasadas/hoje/próximos 7 dias/intervalo personalizado
  inclusivo — RF-13/CA-13/CA-14/CA-20), lembrete (RF-14/CA-15) e
  recorrência (ativa/sem/cancelada — RF-15/CA-16);
- ordenação por relevância textual (título → notas → subtarefas) com
  desempate de origem; só filtros → ordem de origem (RF-16/CA-17);
- interface: campo de busca com debounce, botão de filtros com folha
  rolável de seções, atalhos rápidos de lista, modo global ocultando as
  visões enquanto a busca está ativa, limpeza em um toque;
- decisão: cancelar recorrência mantém o vínculo da ocorrência com a série
  inativa para suportar o filtro "Recorrência cancelada" (RF-15);
- i18n: novas chaves em `pt-BR`, `en` e `es`.

## 2. Validações executadas (gate Web)

| Verificação | Resultado |
| --- | --- |
| `flutter analyze` | aprovado, sem issues |
| `flutter test` (VM) | aprovado, 142 testes |
| `flutter test --platform chrome` (domínio/aplicação) | aprovado, 103 testes |
| `flutter build web --release` | aprovado (`build/web`) |
| Smoke Web automatizado no Chrome Stable (spec 10, RF-01 a RF-04) | aprovado — `./tool/web-smoke.sh` → `All tests passed` |

Ambiente do gate: idêntico ao
[Registro 0001](0001-fatia-01-ciclo-de-tarefas.md) — macOS 26.6.2 arm64,
Flutter 3.47.0 (`4cf2416426`), Chrome Stable 153.0.8010.53,
ChromeDriver 153.0.8010.52.

## 3. Cobertura dos critérios de aceitação

- CA-01 a CA-05 (busca textual): domínio + widget (inclui debounce).
- CA-06 (filtros sem texto): domínio + widget com folha de filtros.
- CA-07 (debounce): widget com relógio de teste.
- CA-08 (lixeira fora): domínio.
- CA-09 a CA-16 (filtros por categoria): domínio, incluindo combinação
  AND/OR (CA-12), prazos relativos e intervalo (CA-13/CA-14) e os três
  estados de recorrência (CA-16).
- CA-17 (relevância): domínio.
- CA-18 (resultado único): domínio.
- CA-19 (preservação): domínio (função pura, sem mutação).
- CA-20 (concluída não é atrasada): domínio.

## 4. Limitações, desvios e aprendizados

- RF-17 (indicar local da correspondência) é opcional ("poderá"); não foi
  implementada nesta fatia e fica registrada como pendência opcional.
- A tela própria da lixeira permanece sem busca, conforme o fora de escopo.
- `ListView` monta filhos de forma preguiçosa: em testes, seções abaixo da
  dobra não existem na árvore (`ensureVisible` falha com "No element").
  A folha de filtros usa `SingleChildScrollView` + `Column` para montagem
  imediata — decisão também melhor para a hierarquia da folha.
- O fixture de testes (`_TaskBuilder.build`) já havia perdido campos em
  atualizações anteriores; agora repassa todos os campos do domínio — terceiro
  registro do mesmo padrão de bug (registros 0003 e 0004 também).
- Cancelamento de recorrência deixou de limpar `seriesId` para viabilizar o
  filtro "cancelada" da RF-15; o teste CA-17 foi atualizado para o novo
  contrato.

## 5. Intervenções humanas

- Instrução para prosseguir com a spec 05 após a entrega da fatia 04.
