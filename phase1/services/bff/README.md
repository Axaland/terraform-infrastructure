# XXX BFF – Auth & Onboarding

Backend for Frontend Node.js/TypeScript che implementa gli endpoint `/v1/auth` per la Fase 1.

## Setup

```powershell
npm install
cp .env.example .env
npm run dev
```

### Migrazioni

Le migrazioni SQL sono in `../../infra/migrations`. In sviluppo Docker Compose le applica all'avvio. Per eseguirle manualmente:

```powershell
psql postgres://postgres:postgres@localhost:5432/xxx_app -f ../../infra/migrations/0001_create_app_user.sql
```

La tabella `app_user` impone una chiave univoca (`oidc_provider`, `oidc_sub`) e campi non nulli per garantire idempotenza agli accessi federati.

### Test & Lint

```powershell
npm run lint
npm test
npm run openapi:validate
```

## Endpoint
- `POST /v1/auth/login`
- `POST /v1/auth/refresh`
- `GET /v1/auth/me`

Tutti sono documentati in `../../docs/openapi/auth-v1.yaml`.
