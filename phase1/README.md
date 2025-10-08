# Fase 1 – Shell App & Onboarding/Auth

Questo pacchetto raccoglie il codice e gli asset necessari per completare la Fase 1 del piano implementativo di XXX:

- bootstrap dell'app mobile Flutter con routing, gestione stato, feature flag client e telemetria di base;
- Backend For Frontend (Node.js + TypeScript) con endpoint `/v1/auth/login`, `/v1/auth/refresh` e `/v1/users/me` aderenti al contratto OpenAPI;
- migrazione database per la tabella `app_user` e strumenti di delivery locali (Docker Compose) e CI/CD (GitHub Actions);
- documentazione di supporto (OpenAPI, ADR, runbook rollback).

Ogni sottocartella è autonoma:

- `apps/mobile`: codice Flutter (shell + onboarding/auth flow);
- `services/bff`: servizio Node/TS con test, lint e OpenAPI;
- `infra`: migrazioni SQL, Docker Compose e manifest Helm per ambienti dev/stage;
- `docs`: specifiche API, runbook e decision log.

## Prerequisiti

- Node.js >= 20
- pnpm o npm >= 9 (il progetto usa npm di default)
- Docker + Docker Compose
- Flutter SDK >= 3.24 (per build mobile)
- PostgreSQL 15 (locale o containerized)

## Getting started

### 1. Variabili d'ambiente (BFF)

Creare un file `.env` in `services/bff`:

```
PORT=3000
DATABASE_URL=postgres://postgres:postgres@localhost:5432/xxx_app
JWT_ACCESS_SECRET=dev-access-secret
JWT_REFRESH_SECRET=dev-refresh-secret
ID_TOKEN_SHARED_SECRET=dev-oidc-secret
TOKEN_TTL_SECONDS=900
REFRESH_TOKEN_TTL_SECONDS=2592000
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=30
```

> `ID_TOKEN_SHARED_SECRET` rappresenta una chiave condivisa usata in sviluppo per validare token firmati internamente. In produzione va sostituita con la verifica delle firme OIDC reali tramite JWKS.

### 2. Avvio infrastruttura di sviluppo

Portarsi in `infra/` e lanciare:

```powershell
cd infra
docker compose up --build
```

Il compose avvia PostgreSQL e il BFF (in watch mode). La migrazione SQL viene applicata automaticamente al bootstrap del servizio.

### 3. Avvio app mobile

```powershell
cd ..\apps\mobile
flutter pub get
flutter run
```

Nel file `lib/services/auth/mock_auth_service.dart` sono presenti token mock generati firmando un payload con `ID_TOKEN_SHARED_SECRET`.

### 4. Quality gates

```powershell
cd ..\services\bff
npm install
npm run lint
npm test
npm run openapi:validate
```

I test usano `pg-mem` per simulare PostgreSQL e garantire isolamento.

## Struttura
dir principale:

```
phase1/
├── README.md
├── apps/
│   └── mobile/
├── docs/
│   ├── adr/
│   ├── openapi/
│   └── runbooks/
├── infra/
│   ├── docker-compose.dev.yml
│   └── migrations/
└── services/
    └── bff/
```

Ogni directory contiene un README specifico con ulteriori istruzioni.

## Rollout strategy

- Eseguire `npm run seed` (opzionale) per creare account seed in `app_user`.
- Abilitare il flag `ff.onboarding.v1` al 1% da LaunchDarkly/Unleash.
- Monitorare dashboard Grafana (`login_latency`, `login_5xx_rate`) e crash reporting Flutter.
- In caso di regressione, seguire il runbook `docs/runbooks/onboarding-rollback.md`.
