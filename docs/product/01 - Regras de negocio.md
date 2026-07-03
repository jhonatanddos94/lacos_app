
# Projeto Laços

> **Documento 01 — Regras de Negócio**
>
> **Versão:** 1.0
> **Status:** Aprovado
> **Última atualização:** Julho/2026

---

# Objetivo do Documento

Este documento define as regras de negócio do projeto **Laços**.

As regras aqui descritas representam o comportamento esperado do sistema independentemente da tecnologia utilizada.

Sempre que houver conflito entre implementação e este documento, as regras aqui descritas deverão prevalecer até que uma nova versão seja aprovada.

---

# Índice

1. Usuários
2. Salões
3. Profissionais
4. Clientes
5. Serviços
6. Agendamentos
7. Histórico de Atendimento
8. Memórias do Cliente
9. Exclusão de Dados
10. Princípios do Produto
11. Premissas da Versão 1.0

---

# 1. Usuários

## RN-001 — Conta Individual

Todo usuário deve possuir uma conta individual para acessar o sistema.

---

## RN-002 — Propriedade dos Dados

Todo dado cadastrado pertence exclusivamente ao proprietário da conta.

Nenhum usuário poderá visualizar ou alterar informações pertencentes a outro usuário.

---

## RN-003 — Autenticação

A autenticação é obrigatória para utilização do sistema.

---

## RN-004 — Escalabilidade

O sistema deverá ser preparado para permitir que um mesmo usuário possa administrar mais de um salão futuramente.

---

# 2. Salões

## RN-005 — Proprietário

Todo salão deve possuir um proprietário.

---

## RN-006 — Profissionais

Um salão poderá possuir um ou mais profissionais cadastrados.

---

## RN-007 — Histórico

A desativação de um salão nunca deverá remover seu histórico.

---

# 3. Profissionais

## RN-008 — Atendimentos

Um profissional poderá atender diversos clientes.

---

## RN-009 — Histórico

Profissionais poderão ser desativados sem perda do histórico de atendimentos.

---

# 4. Clientes

## RN-010 — Propriedade

Todo cliente pertence ao proprietário da conta.

---

## RN-011 — Histórico

Um cliente poderá possuir diversos atendimentos ao longo do tempo.

Todo histórico deverá permanecer disponível.

---

## RN-012 — Memórias

Um cliente poderá possuir diversas memórias cadastradas.

---

## RN-013 — Profissional Preferencial

Um cliente poderá possuir um profissional preferencial.

Entretanto, poderá ser atendido por qualquer profissional do salão.

---

## RN-014 — Desativação

Clientes desativados não poderão receber novos agendamentos.

Todo histórico deverá permanecer preservado.

---

# 5. Serviços

## RN-015 — Cadastro

Serviços poderão ser cadastrados pelo proprietário.

---

## RN-016 — Disponibilidade

Serviços poderão ser desativados.

Sua utilização permanecerá registrada no histórico.

---

# 6. Agendamentos

## RN-017 — Informações Obrigatórias

Todo agendamento deverá possuir:

- Cliente
- Profissional
- Serviço
- Data e hora
- Status

---

## RN-018 — Status

Os seguintes estados deverão ser suportados:

- Agendado
- Confirmado
- Em atendimento
- Finalizado
- Cancelado
- Não compareceu

Novos estados poderão ser adicionados futuramente.

---

## RN-019 — Atendimento

Após sua conclusão, um agendamento poderá gerar um registro de atendimento.

---

# 7. Histórico de Atendimento

## RN-020 — Registro

Todo atendimento pertence a um cliente.

---

## RN-021 — Serviço

Todo atendimento deverá registrar o serviço realizado.

---

## RN-022 — Informações Técnicas

As observações técnicas pertencem exclusivamente ao histórico de atendimento.

Informações técnicas nunca deverão ser registradas como memórias do cliente.

---

# 8. Memórias do Cliente

> **Este é o principal diferencial do Laços.**

## RN-023 — Objetivo

As memórias representam informações pessoais compartilhadas espontaneamente pelo cliente durante os atendimentos.

---

## RN-024 — Conteúdo

As memórias poderão registrar informações como:

- Família
- Viagens
- Trabalho
- Estudos
- Preferências
- Objetivos
- Datas importantes
- Gostos pessoais

---

## RN-025 — Consulta

As memórias poderão ser consultadas em qualquer atendimento futuro.

---

## RN-026 — Independência

As memórias não alteram o histórico técnico dos atendimentos.

Elas existem exclusivamente para fortalecer o relacionamento entre profissional e cliente.

---

## RN-027 — Finalidade

O objetivo das memórias é proporcionar um atendimento mais humano, personalizado e acolhedor.

---

# 9. Exclusão de Dados

## RN-028 — Desativação

Sempre que possível o sistema deverá utilizar desativação lógica em vez da exclusão permanente.

---

## RN-029 — Preservação do Histórico

Nenhum registro histórico deverá ser removido quando existir relacionamento com outras entidades.

---

# 10. Princípios do Produto

## PN-001

O relacionamento entre profissional e cliente é o principal valor entregue pelo Laços.

---

## PN-002

A tecnologia deve facilitar o relacionamento humano, nunca substituí-lo.

---

## PN-003

O sistema deve ser simples, intuitivo e agradável de utilizar.

---

## PN-004

A gestão do negócio deve complementar o relacionamento com o cliente.

---

## PN-005

A privacidade das informações dos clientes deve ser respeitada em todas as funcionalidades do sistema.

---

## PN-006

O histórico de atendimentos representa a memória técnica do profissional.

As memórias representam a memória afetiva do relacionamento.

Esses dois conceitos nunca devem ser misturados.

---

# 11. Premissas da Versão 1.0

As premissas abaixo representam decisões adotadas para simplificar o MVP.

Elas **não representam limitações permanentes do domínio** e poderão ser revistas em versões futuras do sistema.

---

## PV-001 — Um salão por usuário

Na versão 1.0, cada usuário administrará apenas um salão.

A arquitetura deverá permitir evolução futura para múltiplos salões por usuário.

---

## PV-002 — Um salão por profissional

Na versão 1.0, cada profissional estará vinculado a apenas um salão.

Em versões futuras, um mesmo profissional poderá atuar em múltiplos salões.

---

## PV-003 — Agenda Individual

Inicialmente, os agendamentos serão organizados por profissional.

A arquitetura deverá permitir futuramente agendas compartilhadas e outros modelos de visualização.

---

# Histórico de Alterações

| Versão | Data | Descrição |
|---------|------|-----------|
| 1.0 | Julho/2026 | Criação inicial do documento de Regras de Negócio. |