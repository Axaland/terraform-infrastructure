# Piano implementativo modulare – APP XXX

> **Obiettivo**: portare in produzione l’app XXX con un approccio graduale, sicuro e osservabile end-to-end, partendo dall’infrastruttura già pronta.

## 0. Prerequisiti trasversali

### Stack tecnologico
- **Mobile**: Flutter 3+ (Dart) – architettura modulare con Riverpod/Bloc, supporto i18n e crash analytics.
- **BFF/API**: Node.js 20 + TypeScript, framework Fastify/Express con OpenAPI first.
- **Servizi hot-path**: Go 1.22 – leaderboard, ledger, anti-fraud con focus su low-latency.
- **Admin Web**: Next.js 14 + TypeScript (App Router, SSR/ISR).
- **Database**: PostgreSQL (Aurora PostgreSQL compatibile) con replica e piani di backup.
- **CI/CD**: GitHub Actions (preferito) con pipeline multi-ambiente dev → stage → prod e canary.
- **Observability**: OpenTelemetry (trace) + Prometheus/Grafana (metriche) + CloudWatch/ELK (log strutturati).

### Pattern di delivery
- API-first: OpenAPI versionata, mock server condiviso, contract test consumer-driven (Pact).
- Trunk-based development, feature branch brevi, code owners per dominio.
- Feature flags dinamiche (LaunchDarkly/Unleash) per paese/coorte/utente, con kill-switch.
- Migrazioni DB forward-only (golang-migrate/Prisma) + rollback plan e backup periodici.
- Sicurezza by design: OIDC (Apple/Google/email optional), rate limiting, idempotency-key su POST critici, secrets manager, audit trail ledger.

### SLO iniziali
| Servizio | Indicatore | Target |
| --- | --- | --- |
| Login | p95 latency | < 400 ms |
| BFF errori | 5xx rate | < 0,2 % |
| App stabilità | Crash rate | < 0,5 % |
| Transfer LOONS | p95 latency | < 500 ms |

### Telemetria/eventi core
`app_launch`, `signup_start/success`, `login_success`, `game_start/end`, `score_submit`, `wallet_view`, `transfer_initiated/success/failed`, `ad_impression/click/reward`.

### Feature flags iniziali
```json
{
  "ff.onboarding.v1": true,
  "ff.catalog.v1": false,
  "ff.leaderboard.v1": false,
  "ff.wallet.readonly": false,
  "ff.ledger.transfers": false,
  "ff.invites.v1": false,
  "ff.ads.enabled": false,
  "ff.antifraud.v1": false,
  "ff.admin.web": false,
  "ff.multi.country": false
}
```

### Convenzioni
- UUID v7 per tutte le entità primarie, `Idempotency-Key` obbligatoria sui POST idempotenti.
- Timestamp in UTC, sincronizzazione NTP (Chrony) su ogni pod/VM.

## 1. Shell App + Onboarding & Auth (MVP)
**Obiettivi**: shell Flutter stabile (routing, i18n, error boundary), onboarding federato OIDC, profilo minimo.

### Deliverable tecnici
- Mobile: moduli core, auth, profile, telemetry; gestione permessi e remote config; crash reporting.
- BFF: endpoint `/v1/auth/login`, `/v1/auth/refresh`, `/v1/users/me`; integrazione OIDC Apple/Google; JWT short-lived + refresh token.
- DB schema (Aurora):
```sql
CREATE TABLE app_user (
  id uuid PRIMARY KEY,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  email text UNIQUE,
  oidc_provider text,
  oidc_sub text,
  nickname text,
  country char(2),
  lang char(2),
  status text DEFAULT 'active' CHECK (status IN ('active','banned'))
);
```
- OpenAPI estratto per `/v1/auth/login` con contract test Pact mobile↔BFF.

### QA & DoD
- Coverage unit test ≥70%, contract test BFF/mobile, E2E onboarding.
- Dashboard SLO login p95 + error rate.
- DoD: `ff.onboarding.v1` attivo al 1% in produzione, rollback plan documentato.

## 2. Catalogo giochi & Game Loop base
**Obiettivi**: lista giochi (anche stub), avvio sessione, tracking game events.

### Deliverable
- Mobile: schermata catalogo, game engine semplice (ready → running → ended), telemetria `game_start/end`.
- BFF: `GET /v1/games`, `POST /v1/games/{id}/session` per generare ID sessione.
- DB:
```sql
CREATE TABLE game (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  slug text UNIQUE,
  min_version text,
  enabled boolean DEFAULT true
);
CREATE TABLE game_session (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES app_user(id),
  game_id uuid REFERENCES game(id),
  started_at timestamptz DEFAULT now(),
  status text CHECK (status IN ('running','ended'))
);
```

### QA & DoD
- E2E "catalogo → start → end".
- DoD: `ff.catalog.v1` al 5% utenti.

## 3. Punteggi & Leaderboard (Microservizio Go)
**Obiettivi**: ingest punteggi con idempotency, leaderboard daily/global, anti-cheat v0.

### API
- `POST /v1/scores` (`session_id`, `score`, `idempotency-key`).
- `GET /v1/leaderboard?game_id=...&scope=daily|global&limit=100`.

### DB e regole
```sql
CREATE TABLE score (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL,
  game_id uuid NOT NULL,
  session_id uuid NOT NULL,
  value int NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, game_id, session_id)
);
```
- Anti-cheat v0: rate limit per user/session, score monotonic, soglie max per gioco, durata minima partita.

### QA & DoD
- Test concorrenza/idempotency, load test (GET leaderboard p95 < 150ms).
- DoD: `ff.leaderboard.v1` al 5% + alert su spike punteggi.

## 4. Wallet “read-only”
**Obiettivi**: UI wallet con saldo (mock/real) e telemetria.

- BFF: `GET /v1/wallet` restituisce `{ balance, last_update }`.
- UI: skeleton/loading, empty state, offline resilience.
- DoD: `ff.wallet.readonly` al 10% utenti.

## 5. Ledger LOONS & Transazioni
**Obiettivi**: ledger ACID doppia scrittura, transfer P2P con idempotency.

### Schema semplificato
```sql
CREATE TABLE account (
  id uuid PRIMARY KEY,
  user_id uuid UNIQUE REFERENCES app_user(id),
  created_at timestamptz DEFAULT now()
);
CREATE TABLE journal_entry (
  id uuid PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  tx_id uuid,
  metadata jsonb
);
CREATE TABLE posting (
  id uuid PRIMARY KEY,
  entry_id uuid REFERENCES journal_entry(id),
  account_id uuid REFERENCES account(id),
  amount bigint NOT NULL,
  currency text DEFAULT 'LOONS' CHECK (currency = 'LOONS')
);
CREATE TABLE transfer (
  id uuid PRIMARY KEY,
  from_account uuid REFERENCES account(id),
  to_account uuid REFERENCES account(id),
  amount bigint NOT NULL CHECK (amount > 0),
  status text CHECK (status IN ('pending','committed','failed')),
  idempotency_key text UNIQUE,
  created_at timestamptz DEFAULT now()
);
```

### Flusso transfer
1. Mobile → BFF `POST /v1/ledger/transfer` con Idempotency-Key.
2. BFF → Ledger service (Go) che esegue transazione DB con doppia scrittura (posting debit/credit).
3. Stato `committed`; audit trail + evento CDC per analytics.

### QA & DoD
- Test di proprietà (somma saldi invariata), chaos test (kill pod) → nessun double debit.
- Errori standard: `INSUFFICIENT_FUNDS`, `RATE_LIMITED`, `IDEMPOTENCY_CONFLICT`, `ACCOUNT_LOCKED`.
- DoD: `ff.ledger.transfers` al 1% (interni) + alert su saldo negativo.

## 6. Inviti & Social Graph
- Tabelle `invite`, `user_relation`, link deep `app://invite?token=` valido 72h.
- Workflow: generazione token → onboarding → relazione bidirezionale → evento `invite_accepted` → reward ledger.
- DoD: `ff.invites.v1` al 5% utenti.

## 7. Ads & Monetizzazione
- SDK ads (interstitial + rewarded) dietro adapter; telemetry `ad_request`, `ad_impression`, `ad_click`, `ad_reward`.
- Frequency cap, cooldown post rewarded, esclusione onboarding.
- Privacy: CMP GDPR, limit tracking per minori/paesi.
- DoD: `ff.ads.enabled` al 5%, cohort >13 anni.

## 8. Anti-Fraud v1
- Segnali: device fingerprint, velocity transfer, win rate anomala, multi-account, emulator detection.
- Azioni: throttling, re-verifica, shadow-ban, esclusione leaderboard.
- DoD: `ff.antifraud.v1` al 10% (modalità monitor), successivo enforce.

## 9. Admin Web (Next.js)
- Funzioni: login SAML/OIDC, RBAC (viewer|operator|admin), pagine Feature Flags, Games, Users, Ledger, Abuse.
- Audit log per azioni sensibili, IP allowlist.
- DoD: `ff.admin.web` on per gruppo ristretto.

## 10. Localizzazione & Paesi
- Bundle lingue (ARB/JSON) + fallback, formati locali, terms/privacy per paese.
- Config rollout per fasce orarie, compliance store.
- DoD: `ff.multi.country` per mercato pilota → roll-out graduale.

## CI/CD – Pipeline a semaforo (esempio GitHub Actions)
```yaml
name: ci-cd
on: [push]
jobs:
  build_test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci && npm run lint && npm run test
      - run: npm run openapi:validate
  contract_tests:
    needs: build_test
    runs-on: ubuntu-latest
    steps:
      - run: npm run pact:verify
  docker_build_push:
    needs: contract_tests
    steps:
      - run: docker build -t registry/leaderboard:${{ github.sha }} . && docker push registry/leaderboard:${{ github.sha }}
  deploy_dev:
    needs: docker_build_push
    steps:
      - run: helm upgrade --install app-dev charts/app --namespace dev
  canary_stage:
    needs: deploy_dev
    steps:
      - run: helm upgrade --install app-stage charts/app --set canary=true --namespace stage
  promote_prod:
    if: ${{ success() && github.ref == 'refs/heads/main' }}
    needs: canary_stage
    steps:
      - run: helm upgrade --install app-prod charts/app --namespace prod
```

## Observability: dashboard & alerting
- Dashboard per servizio: RPS, p50/p95/p99, errori 4xx/5xx, CPU/mem, connessioni DB.
- Dashboard business: DAU, sessioni/utente, ARPDAU, inviti accettati, tasso transfer.
- Alert primari: login p95 > 400 ms (5m), 5xx > 0,2% (5m), job reconciliation fallito, saldo negativo.

## Test matrix
| Step | Unit | Contract | E2E | Load/Chaos |
| --- | --- | --- | --- | --- |
| 1 Onboarding | ✓ | ✓ | ✓ | – |
| 2 Catalogo/Gioco | ✓ | ✓ | ✓ | – |
| 3 Leaderboard | ✓ | ✓ | ✓ | ✓ |
| 4 Wallet RO | ✓ | ✓ | ✓ | – |
| 5 Ledger | ✓ | ✓ | ✓ | ✓ |
| 6 Inviti | ✓ | ✓ | ✓ | – |
| 7 Ads | ✓ | – | ✓ | – |
| 8 Anti-fraud | ✓ | – | ✓ (sim) | ✓ (sim) |
| 9 Admin | ✓ | – | ✓ | – |
| 10 Localizzazione | ✓ | – | ✓ | – |

## Rilascio graduale & guardrail
- Dark launch → 1% → 5% → 25% → 100%.
- Guardrail: crash <0,5%, login p95 <400ms, 5xx <0,2%, churn ↑ <1pp.
- Kill-switch rapidi per ads e transfer.
- Runbook rollback: ripristino flag, rollback versione (Helm), eventuale restore DB da snapshot.

## Rischi principali & mitigazioni
| Rischio | Mitigazione |
| --- | --- |
| Frodi/abusi | Regole conservative, shadow-ban, revisione manuale in Admin |
| Accoppiamento eccessivo | BFF unico con contratti versionati, layering chiaro |
| Migrazioni DB | Test in stage con dati sintetici, backup + restore DR drills |
| UX Ads aggressiva | Frequency cap, esclusione flussi critici, AB testing |
| Performance Ledger | Indici dedicati, lock ottimistici, coda eventi asincroni |

## Roadmap prime 8 settimane
| Periodo | Attività principali | Deliverable |
| --- | --- | --- |
| **W1–W2** | Setup repo mono/multi, pipeline CI, OpenAPI v1, Onboarding/Auth, telemetria base, dashboard SLO | App interna con `ff.onboarding.v1` → 1% |
| **W3–W4** | Catalogo + game loop, servizio leaderboard (Go), E2E punteggio, seed admin | `ff.catalog.v1` 5%, `ff.leaderboard.v1` 5% |
| **W5–W6** | Wallet RO, ledger accrual, transfer P2P flagged, reconciliation v0, anti-cheat minimo | `ff.wallet.readonly` 10%, `ff.ledger.transfers` 1% (interni) |
| **W7–W8** | Inviti & social, Ads cohort, hardening security, canary internazionale | `ff.invites.v1` 5%, `ff.ads.enabled` 5%, `ff.multi.country` mercato pilota |

## Definition of Ready / Done
- **DoR**: contratto API approvato, mock + payload esempio, criteri UX pronti, stima QA, flag creato, metriche SLO definite.
- **DoD**: test unit/contract green, E2E critici green, tracce/metriche live, alert configurati, ADR/runbook aggiornati, rollout minimo in prod completato senza regressioni.

---
**Prossimi passi consigliati**
1. Creare repo mono (turbo/lerna) o multi con GitHub Actions pipeline condivisa.
2. Definire `openapi.yaml` v1 e contract test stub (Pact) per onboarding.
3. Implementare feature flag base (LaunchDarkly/Unleash) con guardrail.
4. Preparare dashboard SLO login + errori BFF in Grafana.
5. Avviare sviluppo Step 1 seguendo DoR/DoD e matrice test.
