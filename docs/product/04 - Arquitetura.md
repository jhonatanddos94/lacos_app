# Projeto Laços

> **Documento 04 — Arquitetura**
>
> **Versão:** 1.0
> **Status:** Em desenvolvimento
> **Última atualização:** Julho/2026

---

# Objetivo

Este documento define a arquitetura técnica do projeto Laços.

Seu objetivo é estabelecer padrões para organização do código, comunicação entre camadas, utilização das tecnologias escolhidas e princípios arquiteturais que deverão ser respeitados durante toda a evolução do sistema.

Toda decisão técnica deverá preservar o domínio da aplicação, permitindo crescimento sustentável e facilidade de manutenção.

---

# Filosofia da Arquitetura

O Laços será desenvolvido priorizando:

- Escalabilidade.
- Baixo acoplamento.
- Alta coesão.
- Facilidade de manutenção.
- Testabilidade.
- Evolução contínua.
- Independência de infraestrutura.

O domínio do sistema representa o coração da aplicação.

Nenhuma regra de negócio deverá depender diretamente de frameworks, banco de dados ou serviços externos.

Toda tecnologia deverá ser considerada um detalhe de implementação.

---

# Stack Tecnológica

## Front-end

- Flutter

## Design System

- Material Design 3

## Gerenciamento de Estado

- Riverpod

## Injeção de Dependência

- Riverpod

## Navegação

- GoRouter

## Arquitetura

- Clean Architecture
- Feature First

## Autenticação

- Firebase Authentication

## Backend

- Back4App (Parse Server)

## Banco de Dados

- MongoDB (gerenciado pelo Back4App)

---

# Decisão Arquitetural Principal

A arquitetura do Laços será baseada em separação de responsabilidades.

Cada tecnologia será utilizada apenas para aquilo em que oferece melhor custo-benefício e simplicidade.

O Firebase Authentication será responsável exclusivamente pela autenticação dos usuários.

O Back4App será responsável pelo armazenamento e gerenciamento dos dados da aplicação.

Ambos serão tratados como detalhes de infraestrutura.

Caso futuramente seja necessário substituir qualquer uma dessas tecnologias, a mudança deverá ocorrer apenas na camada de infraestrutura, preservando o domínio da aplicação.

---

# Princípios Arquiteturais

## Responsabilidade Única (SRP)

Cada classe deverá possuir apenas uma responsabilidade.

Exemplos:

- Tela apresenta informações.
- Controller gerencia estado.
- Use Case executa uma regra de negócio.
- Repository define contratos.
- Data Source comunica-se com serviços externos.

---

## Aberto para Extensão (OCP)

Novas funcionalidades deverão ser adicionadas sem modificar comportamentos já consolidados.

A arquitetura deverá favorecer evolução por extensão.

---

## Inversão de Dependência (DIP)

As camadas internas nunca deverão depender das externas.

O domínio dependerá apenas de contratos.

Nunca de implementações.

---

# Organização da Aplicação

O projeto seguirá a arquitetura Feature First.

Cada funcionalidade possuirá todas as suas camadas agrupadas.

Exemplo:

lib/

- core/
- shared/
- features/
    - auth/
    - clients/
    - memories/
    - appointments/
    - service_records/
    - services/
    - professionals/
    - salon/

Essa organização reduz acoplamento entre módulos e facilita evolução futura.

---

# Camadas da Aplicação

Cada feature seguirá a estrutura da Clean Architecture.

Presentation

Responsável pela interface e interação com o usuário.

Contém:

- Pages
- Widgets
- Controllers / Notifiers
- Providers

---

Application

Responsável pelos casos de uso.

Contém:

- Use Cases

Toda regra de orquestração deverá ocorrer nesta camada.

---

Domain

Representa o coração da aplicação.

Contém:

- Entities
- Repository Contracts
- Value Objects

Essa camada nunca conhecerá Flutter, Back4App ou Firebase.

---

Infrastructure

Responsável por detalhes técnicos.

Contém:

- Repository Implementations
- Data Sources
- DTOs
- Mappers

Toda comunicação com APIs externas deverá ocorrer aqui.

---

# Fluxo da Aplicação

Toda requisição deverá seguir o fluxo:

UI

↓

Controller / Notifier

↓

Use Case

↓

Repository

↓

Data Source

↓

Back4App

A interface nunca deverá acessar diretamente o banco de dados ou serviços externos.

---

# Autenticação

O Firebase Authentication será utilizado exclusivamente para autenticação.

O Firebase fornecerá toda a gestão de sessão do usuário.

O aplicativo utilizará a sessão autenticada do Firebase.

Caso seja necessário sincronizar usuários com o Back4App, essa sincronização deverá ocorrer na camada de infraestrutura.

O domínio nunca deverá conhecer detalhes dessa integração.

---

# Armazenamento de Arquivos

O Laços poderá trabalhar futuramente com fotos de clientes, procedimentos e registros de antes/depois.

As imagens nunca deverão ser armazenadas diretamente no banco de dados.

O banco armazenará apenas referências às imagens.

Na versão 1.0, caso necessário, será utilizado o sistema de arquivos do Back4App.

A arquitetura deverá manter abstração suficiente para permitir futura migração para soluções como:

- Amazon S3
- Firebase Storage
- Cloudflare R2
- Supabase Storage

Sem alterações no domínio.

---

# Convenções Gerais

- Nunca acessar Back4App diretamente pela interface.
- Nunca utilizar ParseObject dentro do domínio.
- Nunca misturar regra de negócio com widgets.
- Toda regra de negócio deverá estar em Use Cases.
- Todo acesso externo deverá ocorrer através de Repositories.
- Cada feature deverá ser independente das demais sempre que possível.

---

# Escalabilidade

A arquitetura foi projetada para permitir futuras evoluções, como:

- Login para profissionais.
- Múltiplos salões.
- Financeiro.
- Promoções.
- Programa de fidelidade.
- Upload de imagens.
- Inteligência Artificial.
- Integrações externas.

Essas funcionalidades deverão ser adicionadas preservando a arquitetura existente.

---

# Filosofia Final

O domínio do Laços representa o ativo mais importante do projeto.

Frameworks, bancos de dados, provedores de autenticação e serviços externos poderão ser substituídos ao longo da vida do sistema.

As regras de negócio, entretanto, deverão permanecer independentes dessas tecnologias.

Toda decisão arquitetural deverá priorizar a longevidade, simplicidade e evolução sustentável do projeto.