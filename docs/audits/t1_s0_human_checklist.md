# T1.S0 — Checklist humano (staging only)

Não usar o app de produção. Não colar secrets no git.

1. Back4App → New App `lacos-staging` (database novo).
2. Copiar Application ID / Client Key / Master Key / Server URL para o secret store local.
3. Conferir Application ID ≠ `gg8Q…qhWb`.
4. Firebase **de teste** → Users A e B com e-mail verificado.
5. Cloud Code staging: env `LACOS_ENV=staging`, `LACOS_SECURITY_MODE=permissive`, `FIREBASE_SERVICE_ACCOUNT_BASE64` do projeto de teste.
6. Deploy `cloud/` (só `ping` / `health` / `exchangeSession`; triggers vazios).
7. Criar classes Parse iguais às de produção **sem** copiar dados de produção. Add Field OFF.
8. Preencher `docs/audits/t1_s0_clp_acl_worksheet.md` olhando o painel.
9. Exportar env e rodar:

```bash
cd cloud
npm run test:staging
npm run test:staging:baseline
```

10. Anexar a matriz impressa em `t1_s0_staging_inventory_report.md` (seções REST / A→B / B→A).
