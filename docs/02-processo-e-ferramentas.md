# Processo e Ferramentas de Desenvolvimento

## 1. Objetivo

Este documento registra como o Urutau Tasks será desenvolvido por agentes de
inteligência artificial. Seu objetivo é tornar o processo compreensível,
avaliável e, sempre que possível, reproduzível pela comunidade.

As ferramentas e os modelos descritos aqui representam o ambiente de
referência do projeto em determinado momento. Eles podem ser substituídos ao
longo do tempo, desde que a mudança seja registrada junto com seus motivos e
impactos.

## 2. Ferramentas de referência

### OpenCode CLI

Será utilizado como uma das interfaces de trabalho dos agentes no repositório,
especialmente para atividades que envolvam inspeção do projeto, planejamento,
alterações locais, execução de comandos e validação técnica.

### ChatGPT app

Será utilizado como ambiente de interação, coordenação e tomada de decisões
entre o desenvolvedor e os agentes. As conversas poderão fornecer contexto,
refinar intenções, avaliar alternativas e revisar resultados produzidos no
processo.

### Modelo de referência

A configuração de referência inicial será o **GPT-5.6 Luna** com nível de
raciocínio **high**.

Essa escolha deverá ser tratada como uma configuração do processo, e não como
uma dependência funcional do aplicativo. O modelo, o nível de raciocínio e as
ferramentas efetivamente utilizadas deverão ser registrados quando forem
relevantes para uma decisão, implementação ou resultado.

Referência: [documentação oficial do GPT-5.6 Luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna).

### Configuração inicial registrada

| Componente | Referência inicial | Finalidade |
| --- | --- | --- |
| Interface de trabalho | OpenCode CLI | Inspeção, alterações locais e validações no repositório |
| Ambiente de coordenação | ChatGPT app | Contexto, planejamento, decisões e revisão |
| Modelo | GPT-5.6 Luna | Execução de tarefas por agentes |
| Raciocínio | `high` | Atividades que exigem análise e verificação mais cuidadosas |

Essa tabela representa um snapshot do processo. A configuração poderá mudar e
deverá ser atualizada quando uma alteração for relevante para a reprodução ou
para a interpretação dos resultados.

## 3. Papéis

### Desenvolvedor humano

O desenvolvedor humano será responsável por:

- definir a visão e as prioridades do produto;
- fornecer contexto e restrições;
- tomar decisões de produto e arquitetura;
- aprovar especificações antes da implementação;
- avaliar trade-offs de qualidade, custo, prazo e complexidade;
- revisar resultados e aceitar ou rejeitar mudanças;
- manter a coerência do projeto ao longo do tempo.

### Agentes de IA

Os agentes poderão ser responsáveis por:

- analisar o contexto e as especificações;
- decompor o trabalho em tarefas menores;
- propor soluções e alternativas;
- implementar mudanças aprovadas;
- criar e executar testes;
- revisar código e documentação;
- identificar riscos, inconsistências e casos-limite;
- registrar evidências e resultados do trabalho.

Os agentes não substituem a responsabilidade de decisão do desenvolvedor
humano. O resultado de um agente deverá ser considerado uma proposta ou uma
execução sujeita aos critérios, limites e aprovações definidos no processo.

## 4. Fluxo orientado por especificações

Cada mudança relevante deverá seguir, tanto quanto possível, este fluxo:

1. registrar a intenção e o problema a ser resolvido;
2. analisar o contexto existente e as restrições;
3. escrever ou atualizar a especificação;
4. definir regras, casos-limite e critérios de aceitação;
5. revisar e aprovar a especificação;
6. delegar a implementação aos agentes;
7. executar testes e validações;
8. revisar o resultado em relação à especificação;
9. registrar decisões, desvios e aprendizados;
10. atualizar a documentação afetada.

O fluxo poderá ser adaptado para mudanças exploratórias ou de baixo risco,
mas a intenção, o resultado esperado e os critérios de conclusão deverão
permanecer claros.

## 5. Registro de cada execução relevante

Quando uma ferramenta ou modelo influenciar uma decisão ou entrega
importante, o registro deverá incluir:

- data da execução;
- ferramenta utilizada;
- modelo e configuração de raciocínio;
- agente ou papel desempenhado;
- especificação ou tarefa relacionada;
- resultado obtido;
- validações realizadas;
- intervenção ou decisão humana;
- limitações, falhas ou desvios observados.

Não é necessário registrar cada interação trivial. O nível de detalhe deverá
ser suficiente para explicar decisões importantes e permitir que a comunidade
entenda como o resultado foi produzido.

### 5.1 Retrospectiva de tokens e custo

Ao encerrar um marco ou o desenvolvimento, quando houver métricas disponíveis,
registrar o total de tokens por modelo e o custo correspondente. Separar dados
medidos pelo provedor de estimativas calculadas; informar o período, a origem
das métricas, o modelo, a tabela de preços e sua data de referência. Não
apresentar custo estimado por token como valor efetivamente cobrado em uma
assinatura. Quando o histórico não expuser uso suficiente para uma soma exata,
explicitar a lacuna e apresentar a estimativa com suas premissas.

## 6. Evolução do ambiente

Ferramentas, modelos e configurações de IA evoluem rapidamente. Por isso, este
documento não deve ser interpretado como uma exigência permanente de uso de
uma ferramenta específica.

Ao alterar o ambiente de desenvolvimento, deverá ser registrada uma breve
comparação contendo:

- motivo da mudança;
- escopo afetado;
- ganhos esperados;
- limitações ou riscos;
- impacto na reprodução de tarefas anteriores.

O objetivo é preservar a transparência histórica do projeto sem transformar
uma escolha momentânea de ferramenta em uma regra arquitetural do aplicativo.

## 7. Estratégia de validação multiplataforma

A Web será a plataforma principal para desenvolvimento, validação e
verificação contínua. Análise estática, testes automatizados, build Web e
smoke test automatizado no Chrome Stable formarão o conjunto bloqueante do
fluxo normal.

Android, iOS, Linux, macOS e Windows continuarão fazendo parte do escopo do
produto. Suas validações serão não bloqueantes no fluxo normal e realizadas
manualmente em marcos importantes, com um resultado registrado para cada
plataforma.

Essa estratégia equilibra o custo de manter uma matriz multiplataforma com a
necessidade de preservar a compatibilidade e registrar evidências reais de
execução em cada sistema. O formato da matriz e os critérios de cada rodada
estão na [especificação de validação multiplataforma](specs/10-validacao-multiplataforma.md).
