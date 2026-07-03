# Projeto Laços

> **Documento 02 — Glossário do Domínio**
>
> **Versão:** 1.0
> **Status:** Aprovado
> **Última atualização:** Julho/2026

---

# Objetivo do Documento

Este documento define o significado oficial dos principais termos utilizados no projeto Laços.

Seu objetivo é eliminar ambiguidades durante o desenvolvimento e garantir que todos os envolvidos utilizem a mesma linguagem ao discutir regras de negócio, arquitetura e implementação.

As definições aqui descritas representam a linguagem oficial do domínio do sistema.

---

# Índice

1. Proprietário
2. Salão
3. Profissional
4. Cliente
5. Serviço
6. Agendamento
7. Atendimento
8. Histórico de Atendimento
9. Memória
10. Profissional Preferencial
11. Proprietário dos Dados

---

# Proprietário

Pessoa responsável pela conta do sistema.

É quem realiza o cadastro do salão e possui acesso administrativo aos dados pertencentes à sua conta.

Todo dado cadastrado no sistema pertence a um proprietário.

---

# Salão

Representa o estabelecimento onde os atendimentos são realizados.

Um salão pode possuir diversos profissionais.

Um salão pertence a um proprietário.

---

# Profissional

Pessoa responsável pela execução dos serviços oferecidos pelo salão.

Exemplos:

- Cabeleireira
- Barbeiro
- Manicure
- Esteticista

O profissional realiza atendimentos aos clientes.

---

# Cliente

Pessoa que recebe os serviços prestados pelo salão.

Cada cliente possui um histórico de relacionamento construído ao longo dos atendimentos.

Um cliente pode possuir:

- Agendamentos
- Histórico de atendimentos
- Memórias
- Profissional preferencial

---

# Serviço

Representa um procedimento oferecido pelo salão.

Exemplos:

- Corte
- Escova
- Coloração
- Hidratação

Os serviços podem ser utilizados em diversos atendimentos.

---

# Agendamento

Representa um compromisso futuro entre um cliente e um profissional.

Seu objetivo é reservar uma data e horário para realização de um serviço.

Enquanto o atendimento ainda não aconteceu, existe apenas um agendamento.

---

# Atendimento

Representa a execução efetiva de um serviço.

O atendimento acontece quando o cliente comparece ao salão e o serviço é realizado.

Após sua conclusão, passam a existir registros históricos relacionados àquele atendimento.

---

# Histórico de Atendimento

Representa a memória técnica do profissional.

Nele ficam registradas informações relacionadas ao serviço executado.

Exemplos:

- Procedimentos realizados
- Produtos utilizados
- Valor cobrado
- Observações técnicas

O histórico de atendimento nunca deve armazenar informações pessoais do cliente.

---

# Memória

Representa uma informação pessoal compartilhada espontaneamente pelo cliente durante um atendimento.

As memórias existem para fortalecer o relacionamento entre profissional e cliente.

Exemplos:

- Vai viajar em julho.
- Filho começou a faculdade.
- Está organizando o casamento.
- Gosta de café sem açúcar.

As memórias nunca representam informações técnicas.

---

# Profissional Preferencial

Representa o profissional que o cliente prefere para seus atendimentos.

Essa preferência não impede que outros profissionais atendam o cliente quando necessário.

---

# Proprietário dos Dados

É o usuário responsável pelas informações cadastradas no sistema.

Todos os registros pertencem ao proprietário da conta.

Nenhum usuário poderá visualizar dados pertencentes a outro proprietário.

---

# Conceitos Fundamentais

O Laços trabalha com dois tipos de memória.

## Memória Técnica

Representa tudo aquilo relacionado ao serviço realizado.

Exemplos:

- Produtos utilizados
- Procedimentos
- Observações técnicas
- Valor cobrado

Essa memória pertence ao Histórico de Atendimento.

---

## Memória Afetiva

Representa informações pessoais compartilhadas pelo cliente.

Exemplos:

- Família
- Trabalho
- Viagens
- Sonhos
- Gostos
- Preferências

Essa memória pertence às Memórias do Cliente.

---

# Linguagem Oficial do Produto

Sempre que os termos abaixo forem utilizados durante o desenvolvimento, deverão possuir os seguintes significados:

| Termo | Significado |
|--------|-------------|
| Cliente | Pessoa atendida pelo salão. |
| Profissional | Pessoa que executa os serviços. |
| Atendimento | Execução efetiva do serviço. |
| Agendamento | Compromisso futuro. |
| Memória | Informação pessoal do cliente. |
| Histórico | Informações técnicas do atendimento. |
| Serviço | Procedimento oferecido pelo salão. |
| Proprietário | Responsável pela conta e pelos dados. |

---

# Histórico de Alterações

| Versão | Data | Descrição |
|---------|------|-----------|
| 1.0 | Julho/2026 | Criação inicial do Glossário do Domínio. |