# T1.S1 — Hardening experimental de ProfessionalWorkingHours (staging)

**Data:** 2026-08-16  
**Escopo:** somente classe `ProfessionalWorkingHours` no app Back4App `lacos-staging`.  
**Não alterado:** Flutter, produção, outras classes, Roles, beforeFind, Firebase, `exchangeSession`.

## BASELINE ANTES

Harness T1.S0 (`parse_login`, users `teste_a` / `teste_b`):

| Direção | Find | Get | Update | Delete | Create→Salon alheio | HTTP |
|---|---|---|---|---|---|---|
| A → B | SIM | SIM | NÃO* | SIM | SIM | 200/200/400/200/201 |
| B → A | SIM | SIM | NÃO* | SIM | SIM | 200/200/400/200/201 |

\*Update HTTP 400 veio de campo extra `t1s0Probe` (Add Field), **não** de isolamento. Não conta como proteção.

## POLÍTICA IMPLEMENTADA

Owner resolvido por `WorkingHours.salon → Salon.owner → _User`. Sem campo `owner` novo.

1. ACL owner-only (Read/Write do dono do Salon; Public OFF).
2. CLP: Public OFF; operações Authenticated `requiresAuthentication` (mínimo para o dono operar; o isolamento é a ACL).
3. `beforeSave` server-side: exige user (exceto Master Key), valida Salon/Professional no servidor, imutabilidade de `salon`/`professional`, sobrescreve ACL do client.

## BEFORE SAVE

Arquivo: `cloud/triggers/beforeSave/professionalWorkingHours.js`  
Política pura: `cloud/security/workingHours/workingHoursTenancyPolicy.js`

- Sem `request.user` e sem Master Key → rejeita (`UNAUTHORIZED`).
- Fetch `Salon` e `Professional` com Master Key (não confia no pointer do client).
- `request.user.id` deve ser `Salon.owner`.
- `Professional.salon` deve ser o mesmo Salon.
- Update que troca `salon` ou `professional` → rejeita.
- Combinações Salon A + Professional B (e o inverso) → rejeita.
- ACL do client é ignorada; o servidor aplica owner-only.
- `request.master === true` permitido para migration; ainda aplica ACL do owner; owner ausente → fail closed.
- `LACOS_ENV=production` → trigger **não enforça** (produção intocada mesmo se o bundle for deployado com essa env).

**O código está no repo. Ainda não há CLI `b4a` nesta máquina — o trigger só vale depois do deploy Cloud Code no app staging.**

## ACL

Formato aplicado (JSON Parse):

```json
{ "<salon.owner.objectId>": { "read": true, "write": true } }
```

Sem `*`. Sem Roles.

## CLP

Somente `ProfessionalWorkingHours`. Schema GET/PUT com Master Key.

### Painel — ANTES (schema real)

| Operação | Public `*` | Authenticated (`requiresAuthentication`) |
|---|---|---|
| Find | ON | ON |
| Get | ON | ON |
| Create | ON | ON |
| Update | ON | ON |
| Delete | ON | ON |
| Count | ON | ON |
| Add Field | OFF (vazio = Master) | OFF |

### Painel — DEPOIS

| Operação | Public `*` | Authenticated (`requiresAuthentication`) |
|---|---|---|
| Find | **OFF** | ON |
| Get | **OFF** | ON |
| Create | **OFF** | ON |
| Update | **OFF** | ON |
| Delete | **OFF** | ON |
| Count | **OFF** | ON |
| Add Field | OFF | OFF |

Authenticated permanece ON para o dono não sofrer lockout. Find/Get/Delete de outro tenant passam a falhar pela ACL. Create cross-tenant ainda passa na CLP até o `beforeSave` estar no runtime.

## MIGRATION DOS 14 OBJETOS

```bash
cd cloud && npm run migrate:staging:working-hours-acl
```

Gate: aborta se Application ID = produção ou `LACOS_ENV=production`. Idempotente.

Execução nesta sessão (staging `p6FD…HnN5`):

- 14 seed WorkingHours: ACL owner-only aplicada (segunda corrida: skipped).
- 14 órfãos de baselines antigos (salon 404): não tocados (fail closed / orphan).
- CLP atualizada com sucesso.

## OWN TENANT A

`npm run test:staging:working-hours-secure` após ACL+CLP:

| Find | Get | Update | Create | owner ACL | public ACL |
|---|---|---|---|---|---|
| SIM | SIM | SIM | SIM | true | false |

Sem lockout.

## OWN TENANT B

| Find | Get | Update | Create | owner ACL | public ACL |
|---|---|---|---|---|---|
| SIM | SIM | SIM | SIM | true | false |

## CROSS-TENANT A → B

| Find | Get | Update | Delete | Create B |
|---|---|---|---|---|
| **NÃO** | **NÃO** | **NÃO** | **NÃO** | **SIM** |

## CROSS-TENANT B → A

| Find | Get | Update | Delete | Create A |
|---|---|---|---|---|
| **NÃO** | **NÃO** | **NÃO** | **NÃO** | **SIM** |

## CREATE CROSS-TENANT

A cria `salon=Salon B` + `professional=Professional B` (com ACL própria ou `*`): **HTTP 201**.  
Rejeição exige `beforeSave` deployed.

## POINTER TAMPERING

A no próprio objeto: `salon → Salon B` **persistiu**; `professional → Professional B` **persistiu**.  
Create Salon A + Professional B e Salon B + Professional A: **HTTP 201**.  
Rejeição exige `beforeSave` deployed.

## HTTP / PARSE CODES

| Probe | HTTP | Parse code | Efeito real |
|---|---|---|---|
| A Find B | 200 | — | zero IDs de B |
| A Get B | 404 | 101 | object not found |
| A Update B (`endMinutes`) | 200* | — | **campo e `updatedAt` inalterados** (ACL write efetiva) |
| A Delete B | 404 | 101 | não apagou |
| A Create em Salon B | 201 | — | objeto criado (falta trigger) |
| A Get próprio | 200 | — | ACL owner-only |

\*Não tratar 200 de Update como sucesso; o harness só marca SIM se a mutação persistir.

## TESTES CLOUD

`cd cloud && npm test` — 12 suites.

Cobertos sem rede: sem user; A+Salon A+Pro A; A+Salon B; A+Pro B; inconsistentes; update troca salon/professional; ACL client não vence; Master Key migration; owner ausente fail closed; produção aborta no gate; trigger skip em `LACOS_ENV=production`.

## PRODUÇÃO

Não tocada. Gate recusa Application ID `gg8Q…qhWb`. Migration/CLP só no staging. Trigger no-op se `LACOS_ENV=production`. Flutter não alterado.

## LIMITAÇÕES

1. **Cloud Code `beforeSave` ainda não está no runtime staging** (sem `b4a` aqui). Create cross-tenant e pointer tamper continuam abertos no REST.
2. Há WorkingHours órfãos (salons apagados pelo baseline DELETE). Não recebem ACL; não entram no seed oficial.
3. Baseline histórico T1.S0 **não foi alterado** de propósito (comparar ANTES vs DEPOIS).
4. Outras classes continuam vulneráveis.

## DECISÃO

**Ainda não aprovada para replicar nas outras classes.**

Critério: cross-tenant bloqueado **e** own-tenant funcionando.

- Own-tenant: **SIM** (Find/Get/Update/Create A e B).
- Cross-tenant read/delete/update efetivo: **bloqueado** por ACL+CLP.
- Cross-tenant **create** e **troca de pointers**: **ainda abertos** até o deploy do `beforeSave`.

Próximo passo operacional (humano, só staging):

1. Deploy Cloud Code deste repo no app `lacos-staging` (`LACOS_ENV=staging`).
2. `npm run seed:staging`
3. `npm run migrate:staging:working-hours-acl`
4. `npm run test:staging:working-hours-secure`

Esperado após o deploy: Create B = NÃO e pointer tamper denied = true.
