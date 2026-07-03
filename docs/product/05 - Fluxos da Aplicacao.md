# Projeto Laços

> **Documento 05 — Fluxos da Aplicação**
>
> **Versão:** 1.0  
> **Status:** Em desenvolvimento  
> **Última atualização:** Julho/2026

---

# Objetivo

Este documento descreve os principais fluxos de uso do aplicativo Laços.

Seu objetivo é orientar a navegação, os estados da aplicação e a experiência prática da usuária dentro do app.

---

# 1. Fluxo Inicial da Aplicação

## Objetivo

Definir o comportamento do aplicativo desde sua abertura até a entrada na Home.

---

## Estados principais

A aplicação poderá iniciar em três estados:

- Usuário não autenticado
- Usuário autenticado sem salão cadastrado
- Usuário autenticado com salão cadastrado

---

## Fluxo Geral

```text
App inicia
↓
Splash
↓
Verifica autenticação Firebase
↓
Usuário autenticado?
↓
Não
→ Login / Cadastro
↓
Sim
↓
Sincroniza usuário com Back4App
↓
Verifica se existe salão cadastrado
↓
Não existe salão
→ Onboarding do Salão
↓
Existe salão
→ Home
```

---

# 2. Fluxo de Cadastro

## Objetivo

Permitir que uma nova usuária crie sua conta no Laços.

---

## Etapas

```text
Usuária acessa tela de cadastro
↓
Informa nome, e-mail e senha
↓
Firebase cria a conta
↓
App sincroniza usuário com Back4App
↓
Cadastro concluído
↓
Redireciona para tela de boas-vindas do salão
```

---

## Regra

Após criar uma conta com sucesso, a usuária não deve ser enviada diretamente para a Home.

Antes disso, ela deverá cadastrar seu salão.

---

# 3. Onboarding do Salão

## Objetivo

Conduzir a usuária de forma acolhedora na criação do primeiro salão.

O onboarding deve parecer uma conversa, e não um formulário burocrático.

---

## Tom da experiência

O Laços deve utilizar uma comunicação humana, leve e acolhedora.

Exemplo:

> Que bom ter você aqui!  
> Agora chegou o momento de adicionar o seu salão. Preparada?

---

## Fluxo

```text
Cadastro concluído
↓
Tela de boas-vindas
↓
Usuária toca em "Vamos começar"
↓
Informa nome do salão
↓
Opcionalmente informa telefone/endereço/cidade/estado
↓
Salão é criado no Back4App
↓
Usuária é direcionada para Home
```

---

## Campos obrigatórios

Na versão 1.0, apenas o nome do salão será obrigatório.

Demais informações poderão ser preenchidas posteriormente.

---

## Exemplo de telas

### Tela 1 — Boas-vindas

```text
🌸 Seja bem-vinda ao Laços!

Estamos muito felizes por ter você aqui.

A partir de agora, vamos ajudar você a criar relacionamentos ainda mais especiais com suas clientes.

Mas antes, precisamos conhecer um pouquinho do seu salão.

[Vamos começar]
```

---

### Tela 2 — Nome do Salão

```text
✨ Como se chama o seu salão?

Campo:
Nome do salão

[Continuar]
```

---

### Tela 3 — Informações opcionais

```text
Quer adicionar mais alguns detalhes?

Telefone
Endereço
Cidade
Estado

[Finalizar]
[Pular por enquanto]
```

---

### Tela 4 — Conclusão

```text
🌸 Tudo pronto!

Seu salão já está preparado no Laços.

Agora vamos começar a criar laços com suas clientes.

[Entrar no Laços]
```

---

# 4. Fluxo de Login

## Objetivo

Permitir que uma usuária já cadastrada acesse sua conta.

---

## Fluxo

```text
Usuária informa e-mail e senha
↓
Firebase autentica
↓
App sincroniza usuário com Back4App
↓
Verifica existência de salão
↓
Se não possuir salão
→ Onboarding do Salão
↓
Se possuir salão
→ Home
```

---

# 5. Fluxo de Sessão Existente

## Objetivo

Permitir que uma usuária autenticada retorne ao aplicativo sem precisar fazer login novamente.

---

## Fluxo

```text
App inicia
↓
Splash
↓
Firebase verifica sessão ativa
↓
Sessão válida?
↓
Não
→ Login
↓
Sim
↓
Sincroniza usuário com Back4App
↓
Verifica salão
↓
Não existe salão
→ Onboarding do Salão
↓
Existe salão
→ Home
```

---

# 6. Fluxo de Logout

## Objetivo

Permitir que a usuária encerre sua sessão com segurança.

---

## Fluxo

```text
Usuária solicita logout
↓
App encerra sessão no Firebase
↓
Limpa estados locais sensíveis
↓
Redireciona para Login
```

---

# 7. Regras de Navegação

## RNAV-001 — Home protegida

A Home nunca poderá ser acessada sem autenticação válida.

---

## RNAV-002 — Salão obrigatório

A Home nunca poderá ser acessada sem que exista um salão cadastrado.

---

## RNAV-003 — Firebase como fonte de autenticação

A sessão autenticada será controlada pelo Firebase Authentication.

---

## RNAV-004 — Back4App como fonte de dados

As informações do salão e demais dados do app serão consultadas no Back4App.

---

## RNAV-005 — Onboarding obrigatório após cadastro

Após criar uma conta, a usuária deverá passar pelo onboarding do salão antes de acessar a Home.

---

# 8. Filosofia da Experiência

O fluxo inicial do Laços não deve parecer um sistema burocrático.

A experiência deve transmitir acolhimento, leveza e proximidade.

O aplicativo deve conversar com a profissional, guiando-a de forma natural.

A usuária não deve sentir que está apenas preenchendo formulários, mas iniciando uma jornada para organizar seu salão e criar relacionamentos mais especiais com suas clientes.

---

# Histórico de Alterações

| Versão | Data | Descrição |
|---------|------|-----------|
| 1.0 | Julho/2026 | Criação inicial do documento com fluxo de Auth e onboarding do salão. |