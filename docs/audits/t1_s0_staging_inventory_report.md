# T1.S0 — Staging e Inventário de Segurança

**Data:** 2026-08-15  
**Regra:** nenhuma alteração em produção, CLP, ACL, schema, Flutter funcional ou triggers.

**Estado desta sessão:** **BLOQUEADA para evidência REST.**  
Não há app staging configurado, nem keys, nem tokens Firebase A/B, nem CLI `b4a`.

O que esta sprint entregou:

- gate anti-produção revalidado;
- harness REST `npm run test:staging:baseline`;
- planilha de inventário para o painel;
- proposta de dart-define Flutter (não implementada);
- relatório com o que é fato vs o que falta evidência.

---

## STAGING BACK4APP

| Item | Estado |
|---|---|
| App Back4App separado | **NÃO CRIADO / NÃO VALIDADO** nesta sessão |
| Application ID próprio | unset |
| Client Key própria | unset |
| Master Key própria | unset |
| Server URL própria | unset |
| Database próprio | **NÃO VALIDADO** |
| Keys de produção reutilizadas | **Não** — gate recusa `gg8Q…qhWb` |

Produção conhecida (Flutter `AppEnvironment`, mascarada): `gg8Q…qhWb`.

Para criar (humano, painel Back4App — **não produção**):

1. New App → nome `lacos-staging`.
2. Copiar Application ID, Client Key, Master Key, Server URL para env local / secret store.
3. Nunca colar no git.
4. Conferir que Application ID ≠ produção.

```bash
export LACOS_STAGING_SMOKE=1
export LACOS_STAGING_APPLICATION_ID='…'   # ≠ gg8Q…qhWb
export LACOS_STAGING_SERVER_URL='https://parseapi.back4app.com'
export LACOS_STAGING_CLIENT_KEY='…'
# Master Key só para auditoria admin / loginAs — nunca no Flutter
```

---

## FIREBASE STAGING

| Item | Estado |
|---|---|
| Projeto Firebase separado | **NÃO VALIDADO** |
| User A (e-mail verificado) | **NÃO CRIADO** |
| User B (e-mail verificado) | **NÃO CRIADO** |
| Independentes de produção | **NÃO VALIDADO** |

Criar no projeto Firebase de **teste** (não produção):

- `user-a-t1s0@example.test` — verificar e-mail
- `user-b-t1s0@example.test` — verificar e-mail

Obter ID Tokens de forma segura (app debug / Auth emulator). **Não** colar tokens em issues.

Service account do Firebase de teste → env Cloud Code staging (`FIREBASE_SERVICE_ACCOUNT_BASE64`). **Não** usar SA de produção.

---

## EXCHANGE SESSION

| Check | Estado |
|---|---|
| Cloud Code no repo (`ping`, `health`, `exchangeSession`) | **CONFIRMADO NO CÓDIGO** |
| `registerTriggers` vazio | **CONFIRMADO NO CÓDIGO** |
| Deploy no staging | **NÃO VALIDADO** |
| User A → sessionToken A | **NÃO TESTADO** |
| User B → sessionToken B | **NÃO TESTADO** |
| Senha derivável como caminho principal | **Não usada no harness** (só `exchangeSession`) |

Harness existente: `cd cloud && npm run test:staging`  
Harness T1.S0: `cd cloud && npm run test:staging:baseline`

Gate local nesta sessão:

```
LACOS_STAGING_SMOKE=unset
LACOS_STAGING_APPLICATION_ID=unset
cloud/.env absent
b4a not installed
```

---

## USERS A/B

| User | Firebase | Parse _User | sessionToken |
|---|---|---|---|
| A | **NÃO CRIADO** | **NÃO TESTADO** | **NÃO TESTADO** |
| B | **NÃO CRIADO** | **NÃO TESTADO** | **NÃO TESTADO** |

O harness falha se A e B resolverem o mesmo `parseUserId`.

---

## TENANTS A/B

Seed oficial (dados falsos, Master Key, staging only):

```bash
cd cloud && npm run seed:staging
```

```
USER teste_a → Salon A → Profissional A → Cliente A → Corte A → Appointment A → 7 WorkingHours
USER teste_b → Salon B → Profissional B → Cliente B → Corte B → Appointment B → 7 WorkingHours
```

Idempotente. Não cria `_User`. Não aplica ACL segura. Manifesto gitignored: `cloud/tests/staging/.seed-manifest.json`. O baseline REST reutiliza esses IDs (GET/find A→B). Re-rodar o seed após o baseline se o harness apagar objetos.

AppointmentService / ServiceRecord / ClientMemory: criar pelo app Flutter apontando staging **depois** do dart-define, ou estender o harness na S1. Nesta sessão o baseline cobre as 6 classes do critério §8.

---

## INVENTÁRIO CLP

Fonte: **somente painel**. Sem acesso ao dashboard nesta sessão.

| Classe | Public * | Authenticated * | Roles | Pointer Perms | Protected Fields |
|---|---|---|---|---|---|
| Salon | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| Professional | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| Client | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| Service | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| Appointment | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| AppointmentService | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| ServiceRecord | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| ServiceRecordService | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| ClientMemory | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |
| ProfessionalWorkingHours | **NÃO CONFIRMADO no staging** | **NÃO CONFIRMADO no staging** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** | **NÃO CONFIRMADO** |

**Fato de produção (auditoria anterior, painel humano — não revalidado aqui):**  
ProfessionalWorkingHours produção: Public R/W OFF, Authenticated R/W ON, Add Field OFF.

Planilha: `docs/audits/t1_s0_clp_acl_worksheet.md`.

---

## INVENTÁRIO ACL

Nenhum objeto staging inspecionado.

| Classe | ACL observada | Public R | Public W | User ACL | Role ACL |
|---|---|---|---|---|---|
| Todas as classes privadas | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** |

**Fato de produção (não staging):** ProfessionalWorkingHours criados pelo Flutter = Public R + Public W.

O harness imprime `ACL=` + `publicR`/`publicW` após o seed, sem tokens.

---

## DEFAULT ACL

| Pergunta | Evidência |
|---|---|
| Default ACL por classe no painel | **NÃO CONFIRMADO** (precisa dashboard) |
| Default app-wide | **NÃO CONFIRMADO** |
| Create Flutter/harness sem `setACL` | **CONFIRMADO NO CÓDIGO** — omitido |
| Como Parse preenche | **Hipótese Parse default `*`** — só confirmar no painel/GET do objeto |

Não alterado.

---

## OWNERSHIP

**Confirmado no código Flutter (create):**

| Classe | owner | salon | professional |
|---|---|---|---|
| Salon | Sim (`_User` sessão) | — | — |
| Professional | **Não** | Sim | — |
| Client | Sim | Sim | — |
| Service | Sim | Sim | — |
| Appointment | Sim | Sim | Sim |
| AppointmentService | Sim | Sim | — |
| ServiceRecord | Sim | Sim | via mapper |
| ServiceRecordService | Sim | Sim | — |
| ClientMemory | Sim | Sim | opcional |
| ProfessionalWorkingHours | **Não** | Sim | Sim |

**Objetos reais staging:** **NÃO TESTADO**.

---

## TENANT GRAPH

Factual no código; **não** confirmado em objetos staging.

```text
_User
 └── Salon.owner → _User
      ├── Professional.salon
      ├── Client.salon (+ owner)
      ├── Service.salon (+ owner)
      ├── Appointment.salon (+ owner, client, professional)
      ├── AppointmentService.salon (+ owner)
      ├── ServiceRecord.salon (+ owner)
      ├── ServiceRecordService.salon (+ owner)
      ├── ClientMemory.salon (+ owner)
      └── ProfessionalWorkingHours.salon + professional
```

---

## POINTER PERMISSIONS

| Item | Estado |
|---|---|
| Uso no código / Cloud | **Nenhuma evidência** |
| Ativadas no staging | **NÃO CONFIRMADO** |
| Não ativar nesta sprint | **Cumprido** |

Candidatos futuros (não implementar):

- `owner` Pointer<_User> — Parse entende.
- `salon` Pointer<Salon> — **não** autoriza membros; o pointer não é `_User`.

---

## CLOUD CODE

| Function / trigger | Repo | Staging deploy |
|---|---|---|
| `ping` | Sim | **NÃO VALIDADO** |
| `health` | Sim | **NÃO VALIDADO** |
| `exchangeSession` | Sim | **NÃO VALIDADO** |
| `registerTriggers` | **vazio** | não deve ganhar beforeSave nesta sprint |

Nenhum trigger de autorização foi implementado.

---

## REST BASELINE

Script: `cloud/tests/staging/cross_tenant_baseline.staging.js`  
Comando: `cd cloud && npm run test:staging:baseline`  
Auth: `LACOS_STAGING_AUTH_MODE=parse_login` (username/password `teste_a` / `teste_b`). Firebase ID tokens são opcionais (`exchange_session`).

Nesta sessão: **não executado contra rede** (gate).

O script, quando as env existirem:

1. recusa Application ID de produção;
2. autentica A e B via `parse_login` (`POST /login`) ou `exchangeSession`;
3. localiza o seed oficial (ou cria tenants efêmeros);
4. Find / Get / Update / Delete / Create→Salon alheio;
5. imprime matriz A→B e B→A.

---

## CROSS-TENANT A → B

| Classe | A lê B? | A altera B? | A apaga B? | A cria apontando B? |
|---|---|---|---|---|
| ProfessionalWorkingHours | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** |
| Client | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** |
| Appointment | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** |
| Salon | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** |
| Professional | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** |
| Service | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** | **NÃO TESTADO** |

---

## CROSS-TENANT B → A

Simétrico: **NÃO TESTADO** em todas as classes.

---

## MATRIZ DE ATAQUE

Sem evidência REST staging, a matriz oficial é **NÃO TESTADO**.  
Não usar “provavelmente”.

**Única evidência humana prévia (produção, fora desta sprint):**  
ProfessionalWorkingHours com ACL Public R/W + CLP Authenticated R/W. Isso **não** substitui o baseline staging.

---

## VULNERABILIDADES CONFIRMADAS

| ID | Evidência | Ambiente |
|---|---|---|
| Create sem `ParseACL` no Flutter | grep / repositories | código |
| Cloud triggers vazios | `cloud/triggers/index.js` | código |
| WorkingHours produção Public ACL | painel humano, sprint anterior | **produção** — não retestado |
| Staging isolado operacional | keys/CLI ausentes | esta sessão |

Nenhuma classe staging marcada **CONFIRMADO** para cross-tenant REST.

---

## HIPÓTESES DESCARTADAS

Nenhuma hipótese de ataque foi descartada — faltou REST.

Hipótese **não usada como fato:** “todas as classes staging têm CLP Authenticated R/W”.

---

## SECRETS

| Segredo | Onde pode estar | Flutter | Git |
|---|---|---|---|
| Master Key | só Cloud / env local staging | **Nunca** | ignorado (`cloud/.env`) |
| Client Key | client Parse + env smoke | permitida como client key | **não commitar staging** |
| Firebase Admin | só Cloud Code | **Nunca** | **Nunca** |
| ID Token / sessionToken | env local temporário | sessão do SDK | **Nunca** |
| Produção vs staging | IDs distintos + gate | hoje hardcoded produção | produção já versionada (dívida) |

---

## FLUTTER STAGING CONFIG

**Hoje:** `AppEnvironment` tem Application ID + Client Key + URL de **produção** hardcoded.  
Só dart-define existente para backend: `LACOS_USE_EXCHANGE_SESSION` e `APP_VERSION`.

**Proposta mínima (NÃO implementada — precisa aprovação):**

```bash
fvm flutter run \
  --dart-define=LACOS_USE_EXCHANGE_SESSION=true \
  --dart-define=PARSE_APPLICATION_ID="$LACOS_STAGING_APPLICATION_ID" \
  --dart-define=PARSE_CLIENT_KEY="$LACOS_STAGING_CLIENT_KEY" \
  --dart-define=PARSE_SERVER_URL="$LACOS_STAGING_SERVER_URL"
```

`AppEnvironment` leria `String.fromEnvironment` com default = valores atuais de produção (compat) **ou** falharia se `LACOS_PARSE_ENV=staging` sem defines.

Não alterar fluxo funcional nesta sprint.

---

## P0

**P0 confirmado (código / produção prévia):**

- Flutter não é trust boundary.
- Create omite ACL.
- WorkingHours em produção já nasceu Public R/W (evidência humana anterior).
- Sem staging isolado validado → não endurecer produção.

**P0 potencial (falta REST staging):**

- Client / Appointment / Salon / Professional / Service cross-tenant.

## P1

- Appointment `getObject(id)` sem query de salon.
- Professional / WorkingHours sem campo `owner`.
- ParseFile URL pública.
- Produção hardcoded no Flutter.

## P2

- Security mode permissive sem efeito em dados.
- Seed REST pode divergir do create Flutter (AppointmentService etc.).

---

## RELEASE GATE

**Não.**  
Não há inventário CLP/ACL staging. Não há prova REST A vs B. Produção não foi (e não deve ser) endurecida.

---

## PRÓXIMA SPRINT T1.S1

Só depois de:

1. humano criar app `lacos-staging` + Firebase teste + Users A/B;
2. deploy Cloud (`ping` / `health` / `exchangeSession` apenas);
3. preencher `t1_s0_clp_acl_worksheet.md`;
4. `npm run test:staging` e `npm run test:staging:baseline`;
5. colar a matriz SIM/NÃO neste relatório.

Aí sim T1.S1: Default ACL + CLP apertada **só em staging**.

---

## ANALYZE

Ver execução local da sprint.

## TEST

Ver execução local da sprint. Baseline Flutter não deve mudar se o app não mudar.
