# ADR-0001: Backup lógico e formato aberto

- **Status:** aceito
- **Data:** 2026-09-23
- **Especificação relacionada:** [Backup, restauração e formato aberto](../specs/07-backup-restauracao-formato-aberto.md)

## Contexto

O Urutau Tasks é local-first e deverá permitir que o usuário mantenha controle
sobre seus dados. O produto precisa oferecer recuperação fiel do estado
persistido e intercâmbio legível, sem atrelar a portabilidade ao esquema
físico do SQLite/Drift.

## Decisão

- Usar um retrato lógico versionado como base dos dois fluxos, independente do
  esquema interno do banco.
- Gerar um único arquivo de backup completo criptografado com senha. A
  restauração preserva os mesmos IDs e relações, é manual e substitui o
  conjunto local integralmente após validação e confirmação.
- Não oferecer recuperação da senha por conta, servidor ou código alternativo.
- Gerar um único arquivo JSON UTF-8 versão 1, legível e não criptografado,
  para exportação e importação do conjunto completo.
- Manter a versão dos arquivos independente da versão do banco. Formatos
  antigos só serão aceitos quando houver conversor suportado; versões
  desconhecidas ou mais novas serão rejeitadas sem alterar dados locais.
- Permitir o uso dos arquivos em qualquer plataforma suportada quando a
  versão do formato for compatível.
- Não incluir mesclagem, importação parcial, anexos, backup automático ou
  sincronização no MVP.

O contrato funcional e os critérios de aceitação estão detalhados na
[especificação SDD](../specs/07-backup-restauracao-formato-aberto.md).

## Alternativas consideradas

### Cópia física do banco SQLite criptografada

Rejeitada para o arquivo de backup do usuário. Embora represente diretamente
o banco em uso, ela acoplaria a portabilidade à estrutura interna do SQLite e
às migrações do Drift. O retrato lógico permite validar e converter dados sem
expor essa representação física.

### Um único arquivo JSON para os dois fluxos

Rejeitada porque o backup completo foi definido como protegido por senha,
enquanto o intercâmbio aberto precisa continuar legível para inspeção e
migração. Os dois fluxos compartilham o conjunto lógico, mas têm proteção e
finalidades diferentes.

### Mesclar arquivos com os dados locais

Adiada para uma possível evolução. Mesclar exigiria regras adicionais para
UUIDs repetidos, dados divergentes e relações. A substituição integral tem
comportamento previsível e pode ser validada antes de modificar a base.

## Consequências

- Cada formato precisa de versão própria e conversores determinísticos para
  versões antigas ainda suportadas.
- Uma senha perdida torna o backup inacessível; a interface deverá informar
  isso antes de concluir a exportação.
- O JSON aberto contém dados pessoais sem criptografia; a interface deverá
  alertar o usuário antes da exportação.
- A restauração substitui os dados locais e, por isso, exige resumo,
  confirmação explícita e gravação atômica.
- A escolha da biblioteca, do envelope e dos parâmetros criptográficos está
  registrada na [decisão técnica de implementação](0003-implementacao-backup-portabilidade.md).
