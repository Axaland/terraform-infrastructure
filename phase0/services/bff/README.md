# BFF Node.js — Fase 0

Backend for Frontend per l'APP XXX. Fornisce un endpoint di salute `/healthz` ed è pensato per crescere con le fasi successive.

## Setup

```powershell
cd phase0/services/bff
pnpm install
pnpm dev
```

Server disponibile su `http://localhost:3000`.

## Struttura

```
services/bff/
├── package.json
├── tsconfig.json
└── src/
    ├── main.ts
    ├── config.service.ts
    └── health.controller.ts
```

## Prossimi passi

- Aggiungere middleware di osservabilità (OpenTelemetry)
- Implementare moduli Auth/User (Fase 1)
- Preparare Dockerfile e definizioni Terraform per ECS
