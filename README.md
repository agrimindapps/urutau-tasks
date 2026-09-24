# Urutau Tasks

O Urutau Tasks é um gerenciador de tarefas local-first, privado e open-source,
desenvolvido com Flutter para Android, iOS, Web, Linux, macOS e Windows.

O projeto também é uma demonstração pública de desenvolvimento de software
conduzido por agentes de IA. O desenvolvedor humano atua como arquiteto e
tomador de decisões, enquanto o trabalho é orientado por Vibe Coding,
Spec-Driven Development (SDD), princípios SOLID, testes e documentação.

O aplicativo prioriza simplicidade, privacidade e controle local dos dados,
sem dependência obrigatória de conta, Firebase ou backend próprio. A base
deverá permanecer aberta para estudo, colaboração e criação de forks.

## Documentação

- [Visão do projeto](docs/01-visao-do-projeto.md)
- [Processo e ferramentas de desenvolvimento](docs/02-processo-e-ferramentas.md)
- [Princípios técnicos](docs/03-principios-tecnicos.md)
- [Escopo do MVP](docs/04-escopo-do-mvp.md)
- [Índice das especificações SDD](docs/04-escopo-do-mvp.md#6-especificacoes-sdd-do-mvp)
- [ADR-0001: Backup lógico e formato aberto](docs/decisoes/0001-backup-e-formato-aberto.md)
- [ADR-0002: Notificações locais por plataforma](docs/decisoes/0002-notificacoes-locais.md)
- [ADR-0003: Implementação de backup e portabilidade](docs/decisoes/0003-implementacao-backup-portabilidade.md)
- [ADR-0004: Implementação de notificações](docs/decisoes/0004-implementacao-notificacoes.md)

## Estado do desenvolvimento

O MVP está em implementação guiada pelas especificações SDD e pelos ADRs. A
base atual inclui tarefas e subtarefas, organização, visões inteligentes e My
Day, recorrência, busca e filtros, preferências de idioma, portabilidade de
dados e lembretes locais. A matriz de builds e verificações manuais fica na
[especificação de validação multiplataforma](docs/specs/10-validacao-multiplataforma.md).

## Executar localmente

Com Flutter instalado, instale as dependências e inicie o aplicativo:

```sh
flutter pub get
flutter run
```

Para executar a versão Web, use `flutter run -d chrome`. A compatibilidade de
execução em cada sistema deve ser consultada na matriz de validação; build
concluída não substitui smoke test manual.

Em um ambiente Windows, gere o pacote instalado com identidade MSIX usando
`dart run msix:create`. A configuração está no ADR de implementação de
notificações; distribuição pública requer definir e usar um certificado de
assinatura próprio.
