# T1.S0 — Planilha de inventário (preencher no painel staging)

App: **somente staging**. Não abrir o app de produção.

Data: _______________  
Application ID (mascarado, 4…4): _______________

## CLP por classe

Marcar ON/OFF. Não inferir.

| Classe | Pub Find | Pub Get | Pub Create | Pub Update | Pub Delete | Pub AddField | Auth Find | Auth Get | Auth Create | Auth Update | Auth Delete | Auth AddField | Roles | Pointer Perms | Protected Fields |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Salon | | | | | | | | | | | | | | | |
| Professional | | | | | | | | | | | | | | | |
| Client | | | | | | | | | | | | | | | |
| Service | | | | | | | | | | | | | | | |
| Appointment | | | | | | | | | | | | | | | |
| AppointmentService | | | | | | | | | | | | | | | |
| ServiceRecord | | | | | | | | | | | | | | | |
| ServiceRecordService | | | | | | | | | | | | | | | |
| ClientMemory | | | | | | | | | | | | | | | |
| ProfessionalWorkingHours | | | | | | | | | | | | | | | |
| _User | | | | | | | | | | | | | | | |

## ACL de objetos (3–5 por classe, criados pelo app ou pelo harness)

| Classe | objectId mascarado | ACL observada | Public R | Public W | User ACL | Role ACL |
|---|---|---|---|---|---|---|
| Salon | | | | | | |
| Professional | | | | | | |
| Client | | | | | | |
| Service | | | | | | |
| Appointment | | | | | | |
| AppointmentService | | | | | | |
| ServiceRecord | | | | | | |
| ServiceRecordService | | | | | | |
| ClientMemory | | | | | | |
| ProfessionalWorkingHours | | | | | | |

## Default ACL

| Pergunta | Resposta factual |
|---|---|
| Existe Default ACL por classe? | |
| Existe default app-wide? | |
| Onde fica no painel? | |
| Objeto criado sem setACL herda o quê? | |
| Há diferença entre classes? | |

## Pointer Permissions

| Pergunta | Resposta factual |
|---|---|
| UI de Pointer Permissions visível? | |
| Alguma ativada hoje? | |
| Campos Pointer<_User> candidatos | owner |
| Limitação Pointer<Salon> | não autoriza membros do salão |

## Ownership observada no objeto

| Classe | owner presente? | salon presente? | professional presente? |
|---|---|---|---|
| Salon | | — | — |
| Professional | | | — |
| Client | | | — |
| Service | | | — |
| Appointment | | | |
| AppointmentService | | | — |
| ServiceRecord | | | |
| ServiceRecordService | | | — |
| ClientMemory | | | |
| ProfessionalWorkingHours | | | |
