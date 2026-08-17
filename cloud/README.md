# Laços Cloud Code

Fundação e autenticação server-side do backend Parse / Back4App do **Laços**.

- **T1.3.1:** estrutura, `ping`, `health`
- **T1.3.2:** `exchangeSession` (Firebase ID Token → Parse `sessionToken`)

O app Flutter **ainda não** consome `exchangeSession` (dual-run / T1.3.3). O login legado com senha derivável permanece no app até a migração.

## Estrutura

```text
cloud/
  main.js
  config/                 # env, feature flags, firebase credentials loader
  shared/                 # errors, logging, validation, result, utils
  security/guards/        # skeletons
  services/               # FirebaseAuth, ParseUser, Session (+ skeletons)
  domain/                 # placeholders por bounded context
  functions/              # ping, health, exchangeSession
  triggers/ jobs/         # stubs
  tests/
```

## Pré-requisitos

- Node.js **18+** recomendado para deploy Back4App (`.nvmrc`). Testes locais: Node 16+.
- Projeto Firebase com Service Account (Firebase Admin).
- App Back4App **staging** com Cloud Code habilitado.

## Comandos locais

```bash
cd cloud
npm install
npm run lint
npm test
npm run validate
```

## Environment variables

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `LACOS_ENV` | Não (default `development`) | `development` \| `staging` \| `production` |
| `LACOS_SECURITY_MODE` | Não (default `permissive`) | `permissive` \| `enforcing` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Uma das duas* | JSON da service account |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Uma das duas* | Mesmo JSON em Base64 |
| `FIREBASE_PROJECT_ID` | Não | Override do `project_id` |

\*Obrigatória para `exchangeSession`. Preferência de leitura: JSON, depois Base64.

### Estratégia de credenciais (justificativa)

Back4App Cloud Code não monta arquivos de service account de forma portável. **Base64 do JSON** é a opção mais segura/prática em dashboards (evita quebra de `\n` na `private_key`). JSON direto também é suportado.

**Nunca** versionar: private key, service account real, Master Key, session tokens, ID tokens.

A Master Key **não** é configurada pelo app: o runtime Parse Cloud Code já a expõe em `Parse.masterKey` apenas no servidor.

## Functions

### `ping` / `health`

Smoke / readiness (T1.3.1).

### `exchangeSession` (T1.3.2)

```text
Firebase ID Token
  → FirebaseAuthService.verifyIdToken (Admin SDK)
  → exige emailVerified
  → ParseUserService.findOrCreateFromFirebaseIdentity
  → SessionService.createSessionForUser (POST /loginAs + Master Key)
  → { sessionToken, parseUserId, firebaseUid, email, expiresAt?, securityMode, isNewUser }
```

#### Entrada (`params`)

| Campo | Obrigatório | Notas |
|-------|-------------|-------|
| `idToken` | Sim | Firebase ID Token |
| `appVersion` | Não | Telemetria |
| `platform` | Não | Telemetria |
| `requestId` | Não | Correlação de logs |

**Ignorados / não autoridade:** `firebaseUid`, `email`, `parseUserId`, `salonId`, `ownerId`, senha Parse.

#### Saída (sucesso)

| Campo | Tipo |
|-------|------|
| `sessionToken` | string |
| `parseUserId` | string |
| `firebaseUid` | string |
| `email` | string \| null |
| `expiresAt` | string \| null |
| `securityMode` | `permissive` \| `enforcing` |
| `isNewUser` | boolean |

#### Códigos de erro (corpo JSON em `Parse.Error.message`)

| Código | Quando |
|--------|--------|
| `VALIDATION` | `idToken` ausente/inválido |
| `UNAUTHORIZED` | Token inválido/expirado/revogado; usuário disabled |
| `EMAIL_UNVERIFIED` | `email_verified !== true` |
| `CONFIGURATION_ERROR` | Credenciais Firebase / runtime Parse ausentes |
| `CONFLICT` | Mapeamento ambíguo `_User` |
| `TEMPORARY` | Falha transitória (Auth/DB/loginAs) |
| `INTERNAL` | Erro inesperado sanitizado |

#### Emissão de sessão (estratégia real)

API oficial Parse REST: **`POST /loginAs?userId=<objectId>`** com headers `X-Parse-Application-Id`, `X-Parse-Master-Key`, `X-Parse-Revocable-Session: 1`.

Documentação: [Parse REST — Logging in as a user](https://docs.parseplatform.org/rest/guide/#logging-in-as-a-user).

**Não** usamos login com senha derivável. **Não** enviamos Master Key ao Flutter.

#### Compatibilidade `_User` legado

1. Busca por `firebaseUid == <uid>`.
2. Senão, busca por `username == <uid>` (legado Flutter).
3. Se ambos existirem e forem usuários diferentes → `CONFLICT`.
4. Legado sem `firebaseUid`: grava o campo (migração soft) e segue.
5. Novo usuário: `username = uid`, `firebaseUid = uid`, senha aleatória server-only (nunca logada/retornada).

Recomendação operacional (manual no painel): índice único em `firebaseUid` quando possível.

## Deploy

1. Configure env vars no **staging** (Firebase service account + `LACOS_*`).
2. Deploy do diretório `cloud/` (entrypoint `main.js`) via fluxo Back4App do time.
3. Smoke:
   - `ping` → `status: ok`
   - `health` → `status: ok`, `securityMode: permissive`
   - `exchangeSession` com ID Token de usuário **verificado** de teste

## Deploy & smoke staging (T1.3.2.1)

Runbook operacional completo (sem secrets):

→ [`docs/staging-exchange-session-runbook.md`](docs/staging-exchange-session-runbook.md)

Harness remoto (bloqueado por padrão; **recusa** Application ID de produção):

```bash
cd cloud
npm run test:staging            # ping/health/exchangeSession
npm run seed:staging            # T1.S0 tenants teste_a / teste_b (Master Key)
npm run test:staging:baseline   # T1.S0 REST A vs B (parse_login ou exchange_session)
npm run migrate:staging:working-hours-acl  # T1.S1 ACL+CLP WorkingHours (Master Key)
npm run test:staging:working-hours-secure  # T1.S1 prova REST pós-hardening
```

O CI/`npm test` padrão **não** chama staging.

### Seed staging (`npm run seed:staging`)

Popula o grafo falso **teste_a / teste_b** no Back4App staging (Master Key). Não cria `_User`. Não aplica ACL segura. Idempotente.

```bash
export LACOS_STAGING_SEED=1
export LACOS_STAGING_APPLICATION_ID='…'   # ou LACOS_STAGING_PARSE_APPLICATION_ID
export LACOS_STAGING_SERVER_URL='https://parseapi.back4app.com'
export LACOS_STAGING_MASTER_KEY='…'       # nunca commitar / nunca no Flutter
cd cloud && npm run seed:staging
```

Aborta (exit ≠ 0) se Application ID/URL/Master Key faltarem, se o Application ID for o de produção, ou se `LACOS_ENV=production`. Manifesto local gitignored: `tests/staging/.seed-manifest.json`. O baseline REST reutiliza esses IDs.

### Baseline REST (`npm run test:staging:baseline`)

Prova autorização cross-tenant no Parse. **Não** exige Firebase.

```bash
export LACOS_STAGING_AUTH_MODE=parse_login
export LACOS_STAGING_APPLICATION_ID='…'
export LACOS_STAGING_SERVER_URL='https://parseapi.back4app.com'
export LACOS_STAGING_CLIENT_KEY='…'
export LACOS_STAGING_USER_A_USERNAME='teste_a'
export LACOS_STAGING_USER_A_PASSWORD='…'
export LACOS_STAGING_USER_B_USERNAME='teste_b'
export LACOS_STAGING_USER_B_PASSWORD='…'
cd cloud && npm run test:staging:baseline
```

Modo opcional `exchange_session` continua disponível (`LACOS_STAGING_ID_TOKEN_A` / `B`) para testar Firebase depois. O baseline pode DELETE objetos do seed — rode `npm run seed:staging` de novo se precisar restaurar.

### Hardening WorkingHours (`npm run migrate:staging:working-hours-acl`)

T1.S1, **somente staging**. Aplica ACL owner-only nos `ProfessionalWorkingHours` existentes e CLP `requiresAuthentication` (Public OFF). Não altera outras classes. Não toca produção (gate recusa o Application ID conhecido).

Depois do deploy do Cloud Code no app staging (`beforeSave` de WorkingHours):

```bash
cd cloud
npm run seed:staging
npm run migrate:staging:working-hours-acl
npm run test:staging:working-hours-secure
```

## Smoke test staging (procedimento — sem tokens reais)

1. Criar usuário Firebase de teste; verificar e-mail.
2. Obter ID Token de forma segura (Firebase Auth no app de debug / Admin `createCustomToken` + client exchange — **não** colar tokens em docs/issues).
3. `Parse.Cloud.run('exchangeSession', { idToken })` (ou REST `/functions/exchangeSession`) no staging.
4. Confirmar `sessionToken` + `parseUserId`.
5. Chamar uma query autenticada com `X-Parse-Session-Token`.
6. Repetir `exchangeSession` → mesmo `parseUserId`, `isNewUser: false`.
7. Token inválido → `UNAUTHORIZED`.
8. Usuário sem e-mail verificado → `EMAIL_UNVERIFIED`.

## Política de logs

Registrado: `requestId`, `functionName`, resultado, `errorCode`, `durationMs`, `appVersion`, `platform`, UID mascarado, `isNewUser`.

**Nunca:** `idToken`, `sessionToken`, senhas, private keys, service account, Master Key.

## Limitações conhecidas

- `expiresAt` depende do payload de `/loginAs` (pode ser `null`).
- `disabled` no ID Token não vem no JWT; consultamos `getUser` (limitação Firebase Admin).
- Dual-run: login legado no Flutter **continua**; esta function apenas coexiste (`securityMode=permissive`).
- Staging remoto só está “validado” após deploy manual + smoke acima.

## Rollback

1. Remover/desabilitar a function no deploy anterior **ou** deixar de chamá-la.
2. Flutter legado permanece intacto nesta sprint.
3. Reverter env vars Firebase se necessário.
4. Não rotacionar senhas legadas nesta sprint.

## Troubleshooting

| Sintoma | Verificação |
|---------|-------------|
| `CONFIGURATION_ERROR` | Env Firebase no painel; JSON/Base64 válido |
| `UNAUTHORIZED` | Token expirado; relógio; projeto Firebase errado |
| `EMAIL_UNVERIFIED` | Verificar e-mail no Firebase Auth |
| `TEMPORARY` em sessão | `/loginAs` disponível na versão Parse do Back4App; Master Key no runtime |
| `CONFLICT` | Dois `_User` para o mesmo UID — corrigir dados manualmente |

## Como criar nova Function / Trigger / Service / Guard

Ver seções do README T1.3.1 (padrões obrigatórios mantidos).

## Pendências T1.3.3

**IMPLEMENTADO no app (flag OFF por padrão).** Ver `docs/audits/t1_3_3_dual_run_flutter.md`.

Pendências restantes:

- Conclusão da validação staging (T1.3.2.1) antes de ativar a flag em distribuição
- T1.3.4+: remoção controlada do legado / Roles / ACL
