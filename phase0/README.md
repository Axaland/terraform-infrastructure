# Fase 0 — Bootstrap & Impalcatura

Questa cartella contiene lo scheletro minimo dell'APP XXX per la Fase 0 del piano di realizzazione graduale. L'obiettivo è predisporre un monorepo con i componenti principali (mobile shell, admin shell, BFF Node.js, servizio Go, infrastruttura Terraform condivisa) e garantire un flusso end-to-end che risponde `OK` all'endpoint `/healthz`.

## Struttura generale

```
phase0/
├── README.md
├── package.json              # workspace npm/pnpm per gestire servizi e tool condivisi
├── apps/
│   ├── mobile/               # shell Flutter minimale
│   └── admin/                # shell Next.js minimale (placeholder)
├── services/
│   ├── bff/                  # BFF Node.js/TypeScript con endpoint /healthz
│   └── go-template/          # Skeleton Go per future componenti hot-path
├── infra/
│   └── terraform/            # bootstrap per ambienti dev/stage/prod
├── scripts/                  # utility DX (lint, fmt, dev)
└── docs/                     # guida operativa Fase 0
```

Ogni fase successiva (`phase1/`, `phase2/`, …) avrà il proprio modulo nella cartella `phaseX/` per mantenere il piano modulare e incrementale.

## Requisiti

- Node.js 20+
- pnpm 9+ (consigliato) oppure npm
- Go 1.22+
- Flutter 3.24+
- Terraform 1.9+

## Cosa è incluso in Fase 0

- BFF Fastify con `/healthz` e `ConfigService`
- Shell Flutter con schermata Welcome che chiama `/healthz` e mostra lo stato
- Scaffold Next.js admin (placeholder login)
- Servizio Go con endpoint `/healthz`
- Base Terraform (riuso moduli già esistenti sotto `infra/terraform` del repository)
- Script di automazione (`bootstrap`, `lint`, `test`)
- Documentazione operativa in `docs/`

## Come procedere

1. Leggere `docs/PHASE0_GUIDE.md` per i passaggi dettagliati.
2. Eseguire `pnpm install` (o `npm install`) nella cartella `phase0/` per installare le dipendenze comuni.
3. Avviare il BFF in locale (`pnpm --filter bff dev`).
4. Avviare l'app Flutter (`flutter run` dalla cartella `apps/mobile`).
5. Verificare che l'app mostri "OK" dopo aver chiamato il BFF.

## Fasi successive

- `phase1/` gestirà la registrazione/login.
- Ogni fase aggiungerà componenti e migrazioni mantenendo la compatibilità e feature flag dedicate.
