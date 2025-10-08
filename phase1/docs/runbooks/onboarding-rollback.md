# Runbook – Rollback Onboarding/Auth

## Scenario
Una regressione in produzione dopo l'attivazione di `ff.onboarding.v1` introduce errori login (p95 > 400ms o 5xx > 0,2%).

## Pre-check
- Verificare dashboard Grafana `login_latency` e `login_5xx_rate`.
- Controllare errori crash app su Crashlytics/Sentry.

## Rollback rapido
1. **Disattivare feature flag** `ff.onboarding.v1` per tutti i segmenti (LaunchDarkly/Unleash).
2. **Verificare** calo errori (5 minuti) e arresto alert.

## Se persiste
3. Rollback BFF: `helm rollback xxx-bff <release_previous>` (namespace prod).
4. Validare health check `/healthz` e `login` in ambiente prod.

## Recover DB (ultima ratio)
5. Trigger ripristino snapshot `app_user` dal backup Aurora (guida `BACKUP-RESTORE-GUIDE.md`).
6. Comunicare allerta nel canale incidenti.

## Post-mortem
- Aprire ticket RCA.
- Documentare fix, aggiornare test e checklist DoD.
