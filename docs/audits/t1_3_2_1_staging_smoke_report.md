# T1.3.2.1 — Deploy e Smoke Test Staging — Relatório

**Data (retomada #2):** 2026-07-27T19:17:14Z  
**Revisão Git local:** `43ae274` (+ working tree com `cloud/` e T1.3.3)  
**Contexto:** T1.3.3 Flutter dual-run concluída localmente (440 testes, flag OFF por padrão).

---

## Decisão explícita

# BLOQUEADA

**Motivo:** o gate anti-produção reprovou **antes** de qualquer chamada remota. Nenhuma variável `LACOS_STAGING_*` está disponível nesta sessão; `cloud/.env` ausente; CLI `b4a` não instalada.

**Não houve deploy.**  
**Não houve smoke remoto.**  
**Não houve teste Flutter remoto.**  
**Produção não foi tocada.**

---

## 1. Validação do ambiente

| Variável | Estado nesta sessão |
|----------|---------------------|
| `LACOS_STAGING_SMOKE` | **unset** |
| `LACOS_STAGING_APPLICATION_ID` | **unset** |
| `LACOS_STAGING_SERVER_URL` | **unset** |
| `LACOS_STAGING_CLIENT_KEY` | **unset** |
| `LACOS_STAGING_MASTER_KEY` | **unset** |
| `LACOS_STAGING_ID_TOKEN_VERIFIED` | **unset** |
| `LACOS_STAGING_ID_TOKEN_UNVERIFIED` | **unset** |

| Check obrigatório | Resultado |
|-------------------|-----------|
| Application ID staging ≠ produção | **Não verificável** (staging ID ausente) |
| Produção conhecida (Flutter) | `gg8Q…qhWb` — **não usada** |
| `LACOS_ENV=staging` (painel) | **NÃO VALIDADO** |
| `LACOS_SECURITY_MODE=permissive` | **NÃO VALIDADO** |
| Firebase SA de teste (painel) | **NÃO VALIDADO** |
| Secrets versionados no Git | **Nenhum detectado** em `cloud/` (apenas `.env.example`) |
| `cloud/.env` gitignored | **Sim** (`.gitignore` linhas 39–41) |
| `cloud/.env` presente localmente | **Ausente** |
| Gate anti-produção | **Reprovou corretamente** (exit 2) |
| CLI `b4a` | **Não instalada** |

**Ação tomada:** execução interrompida conforme regra da sprint — gate reprovado, sem contornar.

---

## 2. Baseline local

| Item | Resultado |
|------|-----------|
| HEAD | `43ae274` |
| Node | `v16.20.2` |
| npm | `8.19.4` |
| `npm run validate` | **OK** (lint + 8 suites) |
| `npm run test:staging` | **Exit 2** — `STAGING_GATE` |
| Suites locais | **8 passed** |

Saída do gate (sanitizada):

```
Staging smoke aborted (safe default).
- Set LACOS_STAGING_SMOKE=1 to explicitly enable remote staging smoke.
- LACOS_STAGING_APPLICATION_ID is required.
- LACOS_STAGING_SERVER_URL is required.
- LACOS_STAGING_CLIENT_KEY is required for function calls.
Production Application ID (masked): gg8Q…qhWb
Staging Application ID (masked): [unset]
```

---

## 3. Deploy Cloud Code

| Item | Estado |
|------|--------|
| Deploy staging executado nesta sessão | **Não** |
| Cloud Code já deployado (confirmado) | **NÃO VALIDADO** |
| Método de deploy disponível | **Não** (`b4a` ausente; sem credenciais painel) |

---

## 4–11. Resultados remotos

| # | Cenário | Estado |
|---|---------|--------|
| 4 | ping | **NÃO VALIDADO** |
| 4 | health (staging + permissive) | **NÃO VALIDADO** |
| 4 | Firebase Admin init | **NÃO VALIDADO** |
| 5 | exchangeSession — usuário verificado | **NÃO VALIDADO** |
| 6 | sessionToken + `/users/me` | **NÃO VALIDADO** |
| 6 | `_Session` / revocable / expiração | **NÃO VALIDADO** |
| 6 | Flutter `getCurrentUserFromServer` (become) | **NÃO VALIDADO** |
| 7 | idempotência | **NÃO VALIDADO** |
| 8 | usuário legado | **NÃO VALIDADO** |
| 9 | testes negativos | **NÃO VALIDADO** |
| 10 | concorrência | **NÃO VALIDADO** |
| 11 | auditoria de logs remotos | **NÃO VALIDADO** |

### Nota técnica — `getCurrentUserFromServer` (Flutter)

**CONFIRMADO APENAS LOCALMENTE (código/SDK):**

`ParseUser.getCurrentUserFromServer(sessionToken)` **instala** a sessão: define `sessionToken` no objeto e chama `GET /users/me` com header `X-Parse-Session-Token`. O SDK persiste o usuário retornado como `currentUser`. **Não** depende de sessão previamente instalada — o token passado é suficiente.

Equivalente ao fluxo Flutter T1.3.3:

```
exchangeSession → sessionToken
  → ParseUser.getCurrentUserFromServer(sessionToken)
  → currentUser validado contra parseUserId
```

Validação remota deste caminho: **pendente**.

---

## 12. Teste controlado Flutter

| Item | Estado |
|------|--------|
| Pré-requisito (smoke backend) | **Não atendido** |
| `fvm flutter run --dart-define=LACOS_USE_EXCHANGE_SESSION=true` | **Não executado** |
| Login / workspace / restore / logout remoto | **NÃO VALIDADO** |

Flag permanece **OFF por padrão** no código — inalterada.

---

## 13. Rollback

Documentado em `cloud/docs/staging-exchange-session-runbook.md`.  
Nenhum deploy nesta sessão → rollback operacional **N/A**.

---

## Ajustes de código nesta retomada

**ALTERAÇÃO DE CÓDIGO REALIZADA:** nenhuma (escopo proibido nesta sprint).

---

## Separação clara

| Classificação | Conteúdo |
|---------------|----------|
| **CONFIRMADO EM STAGING** | — (zero) |
| **CONFIRMADO APENAS LOCALMENTE** | `npm run validate` (8 suites); gate anti-produção; semântica SDK `getCurrentUserFromServer`; T1.3.3 Flutter (440 testes) |
| **NÃO VALIDADO** | todo smoke remoto + teste Flutter controlado |
| **CONFIGURAÇÃO MANUAL NECESSÁRIA** | credenciais staging + deploy + tokens Firebase teste |
| **ALTERAÇÃO DE CÓDIGO REALIZADA** | nenhuma |

---

## O que desbloqueia a sprint

### Opção A — variáveis de ambiente (mesma sessão do agente)

```bash
export LACOS_STAGING_SMOKE=1
export LACOS_STAGING_APPLICATION_ID='…'   # ≠ gg8Q…qhWb
export LACOS_STAGING_SERVER_URL='https://parseapi.back4app.com'
export LACOS_STAGING_CLIENT_KEY='…'
export LACOS_STAGING_MASTER_KEY='…'       # auditoria admin / _Session
export LACOS_STAGING_ID_TOKEN_VERIFIED='…'
export LACOS_STAGING_ID_TOKEN_UNVERIFIED='…'  # opcional
cd cloud && npm run test:staging
```

### Opção B — arquivo gitignored

Criar `cloud/.env` (já ignorado pelo Git) com as mesmas variáveis e instruir o agente a carregá-lo antes do smoke.

### Pré-requisitos no painel Back4App staging

1. Cloud Code deployado (`cloud/main.js` + functions).  
2. Env: `LACOS_ENV=staging`, `LACOS_SECURITY_MODE=permissive`, `FIREBASE_SERVICE_ACCOUNT_BASE64`.  
3. Usuários Firebase de teste (verificado / não verificado).

### Após smoke backend passar

Teste Flutter controlado:

```bash
fvm flutter run --dart-define=LACOS_USE_EXCHANGE_SESSION=true
```

Depois voltar sem o define (padrão `false`).

---

## Critérios de aceite (estado atual)

| Critério | Estado |
|----------|--------|
| Gate anti-produção | ☑ |
| validate local (8 suites) | ☑ |
| Deploy staging | ☐ |
| ping / health remoto | ☐ |
| exchangeSession remoto | ☐ |
| sessionToken + `/users/me` | ☐ |
| idempotência / legado / negativos / concorrência | ☐ |
| logs sem secrets | ☐ |
| teste Flutter controlado remoto | ☐ |
| runbook + rollback documentados | ☑ |

---

## Histórico de retomadas

| Data | Status | Motivo |
|------|--------|--------|
| 2026-07-27T18:52Z | PARCIALMENTE CONCLUÍDA | Sem credenciais; gate OK |
| 2026-07-27T19:17Z | **BLOQUEADA** | Retomada #2 — credenciais ainda ausentes; gate reprovou |

**Próximo status possível:** PARCIALMENTE CONCLUÍDA (smoke parcial) ou CONCLUÍDA (todos os critérios remotos + Flutter) — somente com evidência sanitizada.
