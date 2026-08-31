# Princípios Técnicos

## 1. Propósito

Este documento define as diretrizes técnicas que orientarão a arquitetura, as
especificações e as decisões de implementação do Urutau Tasks.

Os princípios existem para proteger a clareza, a testabilidade, a evolução e
a liberdade do projeto. Eles não devem ser aplicados como cerimônia vazia:
cada abstração precisa ter uma responsabilidade compreensível e um motivo
registrado.

## 2. Arquitetura feature-first pragmática

O projeto será organizado prioritariamente por funcionalidades. Cada feature
deverá concentrar seu comportamento e seus contratos relacionados, evitando
que o código seja separado apenas por tipos técnicos globais.

A arquitetura poderá utilizar limites claros entre apresentação, aplicação,
domínio e infraestrutura, mas sem exigir uma implementação excessivamente
cerimoniosa. A complexidade deverá ser introduzida quando resolver um problema
real de manutenção, teste, evolução ou compreensão.

As regras de negócio não deverão depender diretamente de widgets Flutter, do
banco de dados, de APIs externas ou de detalhes específicos de uma plataforma.

## 3. SOLID aplicado com propósito

Os princípios SOLID serão utilizados para melhorar a responsabilidade,
testabilidade e evolução do código, e não para multiplicar classes ou
interfaces sem necessidade.

As decisões deverão buscar:

- responsabilidades coesas e compreensíveis;
- dependências direcionadas para abstrações estáveis;
- substituição segura de implementações;
- interfaces pequenas e orientadas ao consumidor;
- composição em vez de acoplamento rígido;
- separação entre regras de negócio e mecanismos externos.

Toda abstração relevante deverá ter uma justificativa relacionada a uma
variação real, a uma necessidade de teste ou a um limite arquitetural.

## 4. Estado, dependências e composição

O gerenciamento de estado e a injeção de dependências utilizarão Riverpod como
direção arquitetural inicial. O estado deverá permanecer observável,
testável e próximo da feature que o utiliza, sem transformar a interface em
responsável por regras de negócio.

As dependências externas deverão ser mínimas e justificadas. Antes de
adicionar um pacote, o projeto deverá considerar sua manutenção, estabilidade,
licença, impacto no tamanho e acoplamento criado. Uma dependência não deverá
ser adotada apenas por conveniência quando uma solução simples e sustentável
já existir no próprio Flutter ou no Dart.

## 5. Persistência local e evolução dos dados

O armazenamento principal será local e estruturado, utilizando Drift como
direção tecnológica inicial.

O banco deverá:

- funcionar sem conta, backend ou conexão com a internet;
- possuir migrações de esquema versionadas;
- manter o domínio independente dos detalhes do banco;
- permitir testes determinísticos da persistência;
- tratar evolução e recuperação de dados como preocupações explícitas.

A sincronização não fará parte do MVP. Caso seja implementada futuramente,
Google Drive será considerado uma integração opcional, isolada por um
adaptador, sem transformar o aplicativo em dependente de Firebase, de um
backend próprio ou de uma conta online.

## 6. Portabilidade e propriedade dos dados

O usuário deverá manter controle efetivo sobre seus dados.

O projeto terá dois objetivos complementares:

- oferecer backup e restauração fiéis do banco local;
- oferecer também um formato aberto de intercâmbio, independente da
  implementação interna do banco.

O backup do banco priorizará a restauração completa do estado do aplicativo.
O formato aberto priorizará interoperabilidade, inspeção e migração. O modelo,
o versionamento e os critérios de compatibilidade de ambos serão definidos em
especificações próprias antes da implementação.

## 7. Flutter multiplataforma

O projeto manterá um núcleo compartilhado para regras, estado e comportamento
do produto. Integrações, capacidades específicas e diferenças inevitáveis de
cada sistema deverão ficar isoladas em adaptadores ou limites explícitos.

A experiência visual utilizará Material 3 com comportamento adaptativo. A
interface deverá compartilhar identidade e componentes sempre que possível,
mas poderá ajustar layout, navegação e interação para respeitar as
características de cada plataforma.

As plataformas suportadas são Android, iOS, Web, Linux, macOS e Windows. A
Web será a plataforma principal de validação contínua; as demais terão
verificações opcionais ou não bloqueantes no início e rodadas manuais em
marcos importantes.

## 8. Internacionalização

A interface do aplicativo será preparada desde o início para português,
inglês e espanhol.

Textos apresentados ao usuário não deverão ficar espalhados diretamente na
interface. Recursos de tradução, formatação de datas, números e demais
comportamentos dependentes de locale deverão ser tratados de forma
centralizada e testável.

## 9. Qualidade e testes

O projeto adotará uma pirâmide de testes composta por:

- testes unitários para regras, casos-limite e transformações;
- testes de widget para componentes e fluxos de interface;
- testes de integração para cenários completos e comportamento entre camadas.

A validação Web será o conjunto bloqueante principal. As outras plataformas
serão verificadas de maneira não bloqueante durante a evolução inicial, com
execuções manuais mais amplas ao final de marcos definidos.

Uma mudança só deverá ser considerada concluída quando atender à
especificação relacionada, aos critérios de aceitação e às validações
pertinentes ao seu risco.

## 10. Open-source e liberdade para forks

O projeto deverá permanecer fácil de clonar, entender, executar e modificar.

As decisões deverão evitar dependências obrigatórias de serviços proprietários
ou de infraestrutura mantida por uma única pessoa. Configurações locais,
instruções de execução, decisões técnicas e limitações conhecidas deverão ser
documentadas para que qualquer pessoa possa fazer um fork independente.

A licença BSD 3-Clause existente deverá ser preservada, salvo decisão futura
documentada em sentido contrário.

## 11. Especificações e decisões

Nenhuma funcionalidade relevante deverá ser implementada sem uma intenção
clara, comportamento esperado e critérios de aceitação.

Decisões arquiteturais importantes deverão ser registradas separadamente,
incluindo o contexto, as alternativas consideradas, a decisão tomada e suas
consequências. Quando uma decisão deste documento for alterada, o histórico da
mudança deverá permanecer compreensível para a comunidade.
