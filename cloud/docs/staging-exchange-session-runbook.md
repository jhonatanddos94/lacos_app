# Runbook — Deploy & Smoke Test `exchangeSession` (Staging)

**Sprint:** T1.3.2.1  
**Escopo:** validação operacional remota. Sem Flutter, Roles, ACL, CLP, beforeSave/Find.  
**Regra absoluta:** nunca executar estes passos contra o Application ID usado pelo app Flutter em produção.

---

## 0. Gate obrigatório — staging isolado

Antes de qualquer deploy, confirme **todas**:

| Check | Critério |
|-------|----------|
| App Back4App dedicado | Nome explícito contendo `staging` / `dev` / `test` |
| Application ID ≠ produção | Diferente de `gg8Q…SqhWb` (máscara do ID em `lib/core/config/app_environment.dart`) |
| Firebase project | Projeto Firebase de teste (não `app-lacos` produção, se produção tiver dados reais) |
| Secrets | Service account só desse Firebase de teste |
| `LACOS_ENV` | `staging` |
| `LACOS_SECURITY_MODE` | `permissive` |

Se **não** houver app staging separado: **PARE**. Não faça deploy no app de produção.

Variáveis locais para o harness (nunca commitar valores):

```bash
export LACOS_STAGING_APPLICATION_ID='…'   # ID do app staging
export LACOS_STAGING_SERVER_URL='https://parseapi.back4app.com'
export LACOS_STAGING_CLIENT_KEY='…'       # Client Key staging (smoke remoto)
export LACOS_STAGING_MASTER_KEY='…'       # só auditoria admin /loginAs e _User
export LACOS_PRODUCTION_APPLICATION_ID='gg8QDOwG2FI0lRFQ79cFDYxh61mRx2ECqGZSqhWb'
export LACOS_STAGING_SMOKE=1
# ID token obtido fora do shell history quando possível:
export LACOS_STAGING_ID_TOKEN_VERIFIED='…'      # User A
export LACOS_STAGING_ID_TOKEN_UNVERIFIED='…'  # User B (opcional)
```

Comando:

```bash
cd cloud
npm run test:staging
```

Sem `LACOS_STAGING_SMOKE=1` + Application ID de staging válido, o comando **falha de propósito** (não chama rede).

---

## 1. Auditoria pré-deploy (checklist)

| Item | Como confirmar | Status esperado |
|------|----------------|-----------------|
| Node alvo | `.nvmrc` = `18`; `package.json` engines `>=18` | Alinhado |
| CommonJS | `require` / `module.exports` em todo `cloud/` | OK para Back4App |
| Entrypoint | `main.js` + `"main": "main.js"` | Back4App Cloud Code usa `cloud/main.js` |
| Dependências | `firebase-admin` em `dependencies` | Deploy deve instalar npm no Cloud Code |
| Parse global | Código **não** faz `require('parse')`; usa `global.Parse` | Conforme docs Back4App |
| HTTP sessão | `Parse.Cloud.httpRequest` → `POST {serverURL}/loginAs?userId=` | API oficial Parse REST |
| Headers | App Id + Master Key + `X-Parse-Revocable-Session: 1` | Em `SessionService` |
| Secrets | Só env; `.env` gitignored; `.env.example` sem valores | OK |
| Private key newlines | Preferir `FIREBASE_SERVICE_ACCOUNT_BASE64` | Documentado |
| CLI | `b4a` / `back4app` | Instalar se for usar CLI |

**Confirmação local neste workspace (2026-07-27):** lint/test/validate verdes; **sem** CLI `b4a` instalada; **sem** env de staging; **sem** deploy remoto.

---

## 2. Configurar secrets no painel staging

Cloud Code → Environment / Config (nome exato varia no painel):

| Key | Valor |
|-----|-------|
| `LACOS_ENV` | `staging` |
| `LACOS_SECURITY_MODE` | `permissive` |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Base64 do JSON da SA de **teste** |
| `FIREBASE_PROJECT_ID` | se necessário |

Validar **sem imprimir**: variável presente; Base64 decodifica; JSON parseia; campos `project_id`, `client_email`, `private_key` existem.

---

## 3. Deploy foundation + exchangeSession

### Via Dashboard

1. App **staging** → Cloud Code → Functions & Web Hosting.  
2. Garantir árvore equivalente a este repositório (`main.js`, `package.json`, pastas).  
3. Deploy.  
4. Anotar horário + revisão Git (`git rev-parse --short HEAD`).

### Via CLI (quando configurada)

```bash
# A partir de um projeto b4a cujo cloud/ aponta para este código
b4a deploy
b4a releases   # anotar release
# rollback futuro:
# b4a rollback
```

### Smoke pós-deploy (sem exchange)

```bash
# Substituir APP_ID / CLIENT_KEY de STAGING apenas
curl -s -X POST \
  -H "X-Parse-Application-Id: $LACOS_STAGING_APPLICATION_ID" \
  -H "X-Parse-Client-Key: $LACOS_STAGING_CLIENT_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$LACOS_STAGING_SERVER_URL/functions/ping"

curl -s -X POST \
  -H "X-Parse-Application-Id: $LACOS_STAGING_APPLICATION_ID" \
  -H "X-Parse-Client-Key: $LACOS_STAGING_CLIENT_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$LACOS_STAGING_SERVER_URL/functions/health"
```

Esperado: `status: "ok"`; health com `environment: "staging"`, `securityMode: "permissive"`; **sem** secrets na resposta.

---

## 4. Usuários Firebase de teste

| User | E-mail verificado | Ativo | Uso |
|------|-------------------|-------|-----|
| A | sim | sim | sucesso + idempotência + sessão |
| B | não | sim | `EMAIL_UNVERIFIED` |
| C (opc.) | — | disabled | `UNAUTHORIZED` |

Registrar só UIDs mascarados (`abcd…wxyz`).

---

## 5. Obter ID Token com segurança

Opções aceitáveis:

1. App Flutter/debug **apontando só para Firebase de teste** → login User A → logar token em memória / clipboard (não commit).  
2. Script local one-off que faz `signInWithEmailAndPassword` e imprime token **uma vez** (não versionar script com senhas).

Não:

- colar token no README/PR;  
- exportar token em `.env` commitado;  
- usar Master Key / SA para impersonar de forma incompatível com o fluxo real se o objetivo é validar `verifyIdToken` de usuário final (custom token → client ID token é aceitável se o ID Token final for de Auth).

Descartar token após o smoke.

---

## 6. Smoke `exchangeSession` (User A)

```bash
curl -s -X POST \
  -H "X-Parse-Application-Id: $LACOS_STAGING_APPLICATION_ID" \
  -H "X-Parse-Client-Key: $LACOS_STAGING_CLIENT_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"idToken\":\"$LACOS_STAGING_ID_TOKEN_VERIFIED\",\"appVersion\":\"smoke\",\"platform\":\"cli\",\"requestId\":\"smoke-1\"}" \
  "$LACOS_STAGING_SERVER_URL/functions/exchangeSession"
```

Checagens:

- Campos presentes: `sessionToken`, `parseUserId`, `firebaseUid`, `email`, `securityMode`, `isNewUser`  
- Ausentes: password, Master Key, private key, idToken, service account  
- Usar `sessionToken` em:

```bash
curl -s -X GET \
  -H "X-Parse-Application-Id: $LACOS_STAGING_APPLICATION_ID" \
  -H "X-Parse-Client-Key: $LACOS_STAGING_CLIENT_KEY" \
  -H "X-Parse-Session-Token: $SESSION_TOKEN" \
  "$LACOS_STAGING_SERVER_URL/users/me"
```

Confirmar `objectId` == `parseUserId`. **Sem** Master Key nessa chamada.

---

## 7. Idempotência

Repetir exchange com novo ID Token do User A.

- Mesmo `parseUserId`  
- `isNewUser: false`  
- Contagem `_User` com `firebaseUid` / `username` == UID = **1** (consulta admin Master Key só em staging)

---

## 8. Usuário legado (staging only)

1. Com Master Key, criar `_User` com `username=<firebaseUid do User A'>` **sem** `firebaseUid` (ou usar UID de um User A2 de teste).  
2. Rodar exchange.  
3. Confirmar mesmo `objectId`, `firebaseUid` preenchido, sem duplicata.

Não usar dados de produção.

---

## 9. Testes negativos

| Caso | Esperado |
|------|----------|
| Sem `idToken` | `VALIDATION` |
| `idToken: ""` | `VALIDATION` |
| Token lixo | `UNAUTHORIZED` |
| Token expirado | `UNAUTHORIZED` |
| User B não verificado | `EMAIL_UNVERIFIED` |
| Params com `firebaseUid`/`parseUserId`/`salonId` falsos | Ignorados; identidade do token |
| Token de outro projeto Firebase | `UNAUTHORIZED` |

---

## 10. Validar `/loginAs`

Com Master Key **só em staging**:

```bash
curl -s -X POST \
  -H "X-Parse-Application-Id: $LACOS_STAGING_APPLICATION_ID" \
  -H "X-Parse-Master-Key: $LACOS_STAGING_MASTER_KEY" \
  -H "X-Parse-Revocable-Session: 1" \
  "$LACOS_STAGING_SERVER_URL/loginAs?userId=$PARSE_USER_ID"
```

Esperado: `sessionToken` na resposta. Se 404/405/101: **não** voltar à senha derivável; registrar status e abrir incidente (Parse/Back4App version).

---

## 11. Concorrência

Disparar N exchanges paralelos para UID **ainda sem** `_User`.

- Contagem final `_User` = 1  
- Se >1: limpar objetos de teste, corrigir estratégia, regressão, repetir  

---

## 12. Logs

Dashboard → Logs. Confirmar campos permitidos; confirmar ausência de tokens/keys/senhas.

---

## 13. Índice `firebaseUid`

1. Consultar duplicatas antes.  
2. Se o painel permitir unique index em `_User.firebaseUid`, aplicar **só staging**.  
3. Se não permitir: documentar; manter `CONFLICT` no service; não afirmar concorrência total.

---

## 14. Rollback

Como Flutter ainda não chama a function:

1. `b4a rollback` **ou** redeploy da revisão anterior.  
2. Alternativa: remover `exchangeSession` do `main.js` e redeploy (manter `ping`/`health`).  
3. Login legado Flutter permanece intacto.  
4. Confirmar que o app de **produção** não foi tocado.

---

## 15. Limpeza

Apagar `_User` / `_Session` de teste criados no staging; revogar tokens Firebase de teste se aplicável.

---

## 16. Critérios de aceite (copiar para o relatório)

Marcar cada item só com evidência remota real. Sem staging, todos os itens remotos ficam **NÃO VALIDADO**.
