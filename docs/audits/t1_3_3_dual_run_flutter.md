# T1.3.3 — Dual-run Flutter: exchangeSession

**Status:** **CONCLUÍDA** (integração Flutter local)  
**Data:** 2026-07-27  
**Feature flag padrão:** `LACOS_USE_EXCHANGE_SESSION=false` (OFF)

**Dependência explícita:** T1.3.2.1 staging ainda **parcial** — **não ativar** a flag em distribuição real.

---

## Separação

| Classificação | Conteúdo |
|---------------|----------|
| **IMPLEMENTADO** | Flag, client, strategies, coordinator, become, providers, login/cadastro/logout dual-run, testes, docs |
| **PRESERVADO** | Fluxo legado com senha derivável; UI auth; regras de e-mail |
| **NÃO IMPLEMENTADO** | Ativação remota da flag; remoção do legado; Roles/ACL/beforeSave; deploy prod |
| **DEPENDENTE DE STAGING** | Validação remota de `exchangeSession` / `/loginAs` (T1.3.2.1) |
| **RISCO / LIMITAÇÃO** | Flag ON sem staging validado; revogação global de `_Session` não feita |

---

## Fluxo legado (PRESERVADO)

```
LoginForm / RegisterForm
  → AuthController
  → FirebaseAuthRepository
  → SessionRepository.syncAuthenticatedUser
  → AuthSessionCoordinator (flag OFF)
  → LegacyParseSessionStrategy
  → ParseUser.login(username=firebaseUid, password=lacos_parse_session_v1_<uid>)
```

## Fluxo exchange (IMPLEMENTADO, flag ON)

```
AuthController (e-mail verificado)
  → getIdToken() [memória apenas]
  → ExchangeSessionClient → Cloud Function exchangeSession
  → ParseUser.getCurrentUserFromServer(sessionToken)  // become
  → valida objectId == parseUserId
```

Sem fallback silencioso para o legado.

## Feature flag

| Item | Valor |
|------|-------|
| Define | `LACOS_USE_EXCHANGE_SESSION` |
| Classe | `AuthFeatureFlags.useExchangeSession` |
| Padrão | **`false`** |

```bash
# Ativar localmente
fvm flutter run --dart-define=LACOS_USE_EXCHANGE_SESSION=true

# Desativar / rollback
fvm flutter run --dart-define=LACOS_USE_EXCHANGE_SESSION=false
# ou omitir o define
```

## Login / cadastro / restore / logout

| Cenário | Flag OFF | Flag ON |
|---------|----------|---------|
| Login verificado | sync legado | exchange |
| Login não verificado | sync legado | **pula** Parse |
| Cadastro | sync legado (+ rollback) | **pula** Parse até verificação |
| Restore (`workspaceProvider`) | sync; reutiliza sessão válida | idem; `forceRefreshIdToken` se precisar sync |
| Logout | Parse → Firebase → invalidate workspace | idem (best-effort nas duas) |

Restore evita exchange duplicado após login: o coordenador **reutiliza** Parse session válida do mesmo Firebase UID.

## Erros Cloud Code → UI

| Código | Comportamento UI |
|--------|------------------|
| VALIDATION | sessão genérica |
| UNAUTHORIZED | sessão expirou (+ 1 retry com `getIdToken(true)`) |
| EMAIL_UNVERIFIED | confirme seu e-mail |
| CONFIGURATION_ERROR | tente mais tarde |
| CONFLICT | vincular / suporte |
| TEMPORARY | conexão |
| INTERNAL | sessão genérica |
| SESSION_CONFLICT / BECOME_FAILED | limpa Parse local e falha |

Logs (debug): `requestId`, strategy, duração, códigos. **Nunca:** idToken, sessionToken, senha.

## Qualidade

| Comando | Resultado |
|---------|-----------|
| `fvm flutter analyze` | **No issues found** |
| `fvm flutter test` | **440 passed** |
| Testes T1.3.3 (session + auth controller) | **33 passed** |

## Pendências

1. Concluir T1.3.2.1 (smoke staging remoto) antes de ativar a flag.
2. T1.3.4+: cutover, remoção do legado, Roles/ACL conforme ADR.

## Arquivos principais

Ver relatório final da sprint no chat / checklist abaixo no histórico da implementação.
