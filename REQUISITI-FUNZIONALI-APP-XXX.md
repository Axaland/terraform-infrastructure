# REQUISITI FUNZIONALI – APP XXX  
**Versione:** 1.0  
**Data:** 8 ottobre 2025  
**Ambito:** Mobile, Backend, Admin, Data & Cloud Architecture  

---

## 1. Concetto generale

XXX è una **piattaforma di marketing interattivo e loyalty gamificato** che connette utenti, sponsor e partner commerciali attraverso contenuti immersivi, giochi e reward digitali. L’esperienza è mobile-first e si fonda su quattro pilastri:

1. **Engagement ADV**: video, missioni, tornei e feed dinamico (format "Combine").
2. **Play Card** Silver/Gold: token di gioco che abilitano vincite, estrazioni e sconti.
3. **LOONS**: moneta virtuale che misura il valore generato dall’utente e può essere spesa come sconto.
4. **XXX-CARD**: carta ricaricabile in white label, elemento chiave per trasformare i LOONS in risparmio reale.

### 1.1 Posizionamento

- XXX non è un operatore fintech: tutta la complessità regolamentata (emissione carta, gestione fondi, conversioni cripto, KYC/AML) è delegata **in outsourcing white label** a partner autorizzati (EMI/banca).
- XXX governa **marketing, loyalty, gaming, adv, relazioni sponsor/merchant** e la UX complessiva.
- Obiettivo: trasformare l’attenzione e il tempo dell’utente in valore economico, mantenendo compliance e scalabilità.

### 1.2 XXX-CARD (white label)

- Carta di credito ricaricabile brandizzata XXX, emessa e gestita da partner terzo.
- Basata su **cripto-proprietario** usato solo a livello infrastrutturale; l’utente ricarica/spende **in EUR o USD** senza vedere il sottostante.
- **LOONS** utilizzabili come sconto solo su transazioni effettuate con XXX-CARD.
- Limite sconto LOONS: **max 50%** del valore dello scontrino.
- KYC/AML gestiti dal partner; XXX integra via API.

### 1.3 Ecosistema

| Attore | Valore |
| --- | --- |
| Utente | Gioca, guarda sponsor, guadagna LOONS, spende con sconto su XXX-CARD |
| Sponsor | Ottiene visibilità e metriche di engagement misurabili |
| Merchant | Accede al marketplace LOONS con protezione antifrode |
| Partner finanziario | Fornisce infrastruttura carta e compliance |
| XXX | Orchestratore di marketing, advertising, loyalty e social graph |

---

## 2. Home – Feed "Combine"

### 2.1 Formato

- Feed verticale full-screen (stile Instagram Reels/TikTok) composto da schede **Combine**.
- Ogni Combine contiene:
  - **Video Sponsor/News** (durata ~10s, autoplay, tracking ADV).
  - **Play Card associata** (Silver/Gold) visibile e caricata gradualmente.

### 2.2 Timeline interazione

| Tempo | Evento | Stato Card |
| --- | --- | --- |
| 0s | Avvio video sponsor | "loading" |
| 5–7s | Card si attiva e mostra CTA “Gioca ora” | "ready" |
| 10s | Video termina; card resta giocabile | "ready" |
| 20s | Card scade se non giocata | "expired" |
| Swipe | Cambio Combine | Stato salvato |

- Se l’utente scrolla prima dei 5s, la Card non viene caricata.
- Visualizzazione sponsor → condizione necessaria per abilitare la Card.

### 2.3 Interazioni principali

| Azione | Esito |
| --- | --- |
| Tap video | Pausa/Riprendi |
| Doppio tap video | Like sponsor |
| Tap logo sponsor | Scheda dettagli |
| Tap Card | Stato + CTA |
| CTA "Gioca ora" | Avvio minigioco & reward |
| Swipe su Card | Invia ad amico / salva nel Basket |
| Long-press su Card | Crea pacchetto / opzioni |
| Swipe up/down | Navigate Combine |
| Long-press background | Mute/unmute audio |

### 2.4 Dati Combine (API)

```json
{
  "id": "cmb_12345",
  "sponsor_id": "spn_001",
  "video_url": "https://cdn.xxx.com/videos/ad1.mp4",
  "play_card_type": "SILVER",
  "card_id": "pc_987",
  "card_status": "pending",
  "reward_probabilities": {
    "win_gold": 0.08,
    "win_loons": 0.15
  },
  "display_order": 12,
  "next_combine_id": "cmb_12346"
}
```

- API chiave: `GET /feed/combines`, `POST /combine/{id}/playcard/play`, `POST /combine/{id}/interaction`, `POST /combine/{id}/watched`.

### 2.5 UX & Animazioni

1. **Ingresso**: video fade-in, overlay sponsor, Card "ombra" con progress bar 5s.
2. **Ready**: Card si illumina, CTA "Gioca ora".
3. **Gioco**: mini gioco (spin, quiz, gratta), effetto confetti su vincita, update Basket.
4. **Scroll**: transizione parallax, preloading scheda successiva.

### 2.6 Personalizzazione feed

- Ranking basato su preferenze (giochi, sponsor, conversioni).
- Priorità: sponsor paganti > card vincenti > nuovi sponsor.
- Filtri geolocalizzati e time-based.
- A/B test su ordine e CTA.

---

## 3. Sistema Play Card & Estrazioni

### 3.1 Tipologie

| Tipo | Sorgente | Durata | Vincita potenziale | Stato post uso |
| --- | --- | --- | --- | --- |
| Silver | Sponsor, missioni, Gold | 1 partita | Gold | Consumata |
| Gold | Vittorie, missioni speciali | 1 mese / 4 estrazioni | Silver o LOONS | Attiva fino a scadenza |

### 3.2 Play Card Basket

- Tabs: **Silver | Gold | Pacchetti**.
- Stato card: nuova, attiva, giocata, in scadenza.
- Azioni: Gioca, Invia, Crea pacchetto, Auto-uso.
- Imps: impostazione "Usa automaticamente" con priorità (es. Silver > Gold).

### 3.3 Sponsor List (adv dedicata)

- Feed video scrollabile full-bleed.
- Ogni card sponsor mostra: logo, tipo Card offerta, cap residuo, requisiti.
- Azioni: "Guarda e carica", "Dettagli", "Vai al Basket".
- Tracking: viewability, anti-abuso focus/app/background.

### 3.4 Estrazioni Gold

- 4 estrazioni giornaliere; visibili agenda e countdown.
- Ticket: Gold giocate partecipano automaticamente (anche offline).
- Payout configurabile via Admin: `P(LOONS) + P(Silver) + P(None) = 1`.
- Audit: storicizzazione risultati, ricalcolo manuale con motivazione.

---

## 4. Header & Footer funzionali

### 4.1 Header (top bar)

| Elemento | Funzione |
| --- | --- |
| ← Back | goBack; nascosto in root Home |
| Titolo/Breadcrumb | Nome sezione, pill contatori |
| Messaggi | Icona campanella con badge ("99+", dot) |
| Menu completo | Drawer full height con scorciatoie |

Varianti: compatto (scroll), trasparente (su video), action contestuali (es. "Seleziona").
Accessibilità: area 44×44pt, label screen reader, haptic feedback.

### 4.2 Footer (bottom bar)

| Slot | Descrizione |
| --- | --- |
| Logo/Home | Torna alla root, long-press scroll top |
| Play Card | Badge totale card disponibili, quick action su long-press |
| Messaggi | Centro notifiche |
| Sponsor List | Accesso diretto al feed ADV |
| Profilo | Dati utente, KYC, impostazioni |

Badge dinamici: countdown estrazioni Gold, card in scadenza, sponsor nuovi.

---

## 5. Aree utente (mobile)

### 5.1 Home (Combine)

- Struttura definita sopra.
- CTA rapide: "Gioca ora", "Invia", "Basket".
- Aggiornamenti real-time (LOONS, card, missioni).

### 5.2 Sponsor List (nuova)

- Video feed, card sponsor, progress anti-abuso.
- Output: Play Card caricate nel Basket.

### 5.3 Play Card Basket (nuova)

- Tabs Silver/Gold/Pacchetti.
- Azioni: Gioca, Invia, Crea pacchetto.
- Dettaglio card: fonte, data, cronologia, scadenza.

### 5.4 Area Gioco

- Auto-uso card (configurabile).
- Selettore manuale da Basket.
- Regole Silver/Gold, estrazioni, accreditamenti.

### 5.5 Profilo Personale

- Dati utente, avatar, statistiche.
- QR personale per inviti/scambi.
- Privacy: 2FA, biometria, preferenze.

### 5.6 Portafoglio LOONS

- Saldo/movimenti, invio/richiesta LOONS.
- Bacheca offerte integrate.
- Export CSV/PDF.

### 5.7 XXX-CARD (nuova area)

- Richiesta/attivazione (KYC partner).
- Saldo EUR/USD, ricariche, limiti.
- Applicazione automatica sconto LOONS (max 50%).
- Storico transazioni e benefici.

### 5.8 Bacheca Offerte (Marketplace)

- Annunci di acquisto/vendita LOONS.
- Filtri: prezzo, quantità, rating, paese.
- Reputation: rating bidirezionale, segnalazioni.

### 5.9 Giochi

- Catalogo, preferiti, ultimi giocati.
- Classifiche globali, locali, network.
- Tornei/eventi, iscrizioni, premi.

### 5.10 Network Personale

- Lista amici, inviti pendenti.
- Feed attività network.
- Classifica network, messaggistica opzionale.

### 5.11 Missioni & Obiettivi

- Missioni daily/weekly/seasonal.
- Tracking progresso, milestone reward.
- Leveling e badge.

### 5.12 Area Premi (redemption)

- Catalogo premi virtuali/fisici.
- Riscatto con conferma e tracking spedizione.

### 5.13 Centro Notifiche

- Categorie (Giochi, Card, Estrazioni, Sponsor, Network, Sistema).
- Alert smart (Gold in scadenza, estrazioni imminenti).

### 5.14 Assistenza & FAQ

- FAQ dinamiche, chatbot AI, ticket con allegati.

### 5.15 Impostazioni

- Account & sicurezza, preferenze lingua/paese.
- Auto-uso Play Card, consensi privacy/GDPR.

---

## 6. Web Admin Panel – Sezioni principali

### 6.1 Dashboard

- KPI: DAU/WAU/MAU, LOONS circolante, ADV revenue, ARPU, retention.
- Filtri per paese/canale/device.
- Alert frodi, picchi anomali, estrazioni.

### 6.2 Gestione Utenti

- Ricerca avanzata, stato, KYC.
- Azioni: sospendi/riattiva/ban, reset fattori sicurezza.
- Log attività, transazioni, ticket.

### 6.3 Gestione Contenuti

- Giochi (publishing/versioning/rollback).
- Banner ADV, frequenza, targeting.
- FAQ, news, notifiche globali.

### 6.4 Bacheca (moderazione)

- Monitoraggio offerte, segnalazioni, azioni (oscura/warning/ban).
- Regole prezzo/quantità per paese.

### 6.5 Premi

- Catalogo, stock, costi.
- Redemption: approvazioni, tracking SLA partner.

### 6.6 Sponsor & Campagne

- Anagrafiche sponsor: asset video, CTA, segmenti target.
- Config: tipo Card offerta, cap giornalieri, geotargeting, periodo.
- Performance funnel: impression → completion → Card caricate.

### 6.7 Regole Play Card & Payout

- Parametri: limiti utente, scadenze Gold, orari estrazioni.
- Payout tables configurabili con audit e rollback.

### 6.8 Estrazioni (scheduler)

- Calendario job, stato, risultati.
- Ricalcolo d’emergenza con motivazione/log.

### 6.9 Antifrode & Sicurezza

- Heuristic: viewability sponsor, scroll velocity, emulator detection.
- Rate limit IP/device/user.
- Blacklist/whitelist, indagini, report.

### 6.10 Reportistica & Export

- Esportazioni CSV/XLSX/PDF.
- Dashboard: card acquisite, utilizzo, vincite, inventario, ADV.

### 6.11 Configurazioni di Sistema

- White-label, multilingua, valute, paesi.
- Provider esterni: Card, ADV network, analytics.
- Notifiche tecniche e webhook.

---

## 7. Area Merchant & Gestore

### 7.1 Merchant Portal

- Inserisci offerte LOONS (prezzo, quantità, periodo).
- Gestione transazioni concluse, dispute, rating.
- Statistiche: conversioni, costo medio LOONS, margini.

### 7.2 Merchant Compliance

- Dati aziendali, KYC documentale.
- Storico performance e comunicazioni admin.
- Fatturazione/payout.

### 7.3 Area Gestore (super-user)

- Monitoraggio operativo trasversale (utenti, merchant, ADV).
- KPI real-time, salute servizi (SLO/SLA).
- Log sistema e performance.
- Configurazione policy globali e provider.

### 7.4 ADV Manager

- Campagne ADV: budget, flighting, targeting.
- Partner network/SSP: revenue share, alert anomalie.
- Metriche: impressions, CTR, eCPM, revenue.

---

## 8. Backend, servizi di sistema & outsourcing

| Componente | Descrizione |
| --- | --- |
| AuthN/AuthZ | OIDC, ruoli, permessi, sessioni |
| API Gateway & BFF | Node/TS per mobile/web; rate limit; JWT |
| Ledger LOONS | Go + PostgreSQL, transazioni ACID |
| Servizi hot-path | Leaderboard, ledger, anti-frode (Go) |
| Play Card Service | Lifecycle, RNG, estrazioni, audit |
| Scheduler estrazioni | Job orchestrati (EventBridge/Cloud Scheduler) |
| Messaging & notifiche | Push, in-app, email |
| Analytics & ML | Segmentazione, LTV, churn prediction |
| Observability | Log strutturati, trace distribuite, metriche |
| Outsourcing finanziario | Carta, fondi, cripto, KYC/AML |

- Ledger LOONS ↔ ledger XXX-CARD sincronizzati via API.
- Conversioni EUR/USD ↔ cripto avvengono lato partner.
- 50% cap LOONS enforcement via motore antifrode.

---

## 9. Sicurezza & Compliance

- Comunicazioni TLS 1.3; chiavi gestite in HSM (partner) e KMS (XXX).
- PII isolata in schema `core_pii`, accesso ristretto.
- GDPR: consensi versionati, data export/download/delete.
- KYC obbligatorio per attivazione XXX-CARD.
- Anti-frode: focus adv, device fingerprint, rate limit.
- Audit trail completo per ledger, estrazioni, payout.

---

## 10. Analytics & KPI

| Area | Metriche principali |
| --- | --- |
| Feed Combine | impression, dwell time, CTR Gioca, completamento video |
| Play Card | % giocate, tasso vincite, card attive |
| ADV | CPM, CTR, revenue per sponsor |
| LOONS | volume circolante, scambi, spesa media |
| XXX-CARD | transazioni con LOONS, sconto medio, attivazioni |
| Network | inviti, conversioni, engagement |
| Retention | session time, giocatori Gold attivi |

---

## 11. Telemetria & tracciamento

Eventi consigliati (non esaustivo):

- `combine_view_start`, `combine_video_completed`, `combine_card_loaded`, `combine_card_played`, `combine_scroll_next`.
- `playcard_transfer`, `playcard_package_created`, `basket_opened`.
- `loons_balance_updated`, `card_payment_discount_applied`.
- `mission_completed`, `invite_sent`, `leaderboard_opened`.
- `adv_click`, `adv_watch_completed`, `sponsor_list_accessed`.
- `session_started`, `session_ended`, `crash_logged`.

---

## 12. Edge cases & fallback

| Scenario | Comportamento |
| --- | --- |
| Offline | Feed cacheato, giochi disattivati, messaggio "Connessione assente" |
| Video non disponibile | Fallback immagine statica + card caricabile |
| Card scaduta | CTA "Gioca" disabilitata, alert |
| Estrazione fallita | Retry + lock ottimistico, logging |
| Timeout API | Spinner + opzione "Riprova" |
| Carta non attiva | LOONS non spendibili, CTA per attivare |
| Utente underage | Sponsor List nascosta, filtri contenuti |

---

## 13. UX personalizzazione & accessibilità

- Feed, sezioni e CTA adattati con AI in base a comportamento.
- Skin/eventi (es. Gold Week) e banner tematici.
- Supporto voice-over, talkback, contrasti WCAG AA.
- Animazioni disattivabili (reduce motion); haptic feedback configurabile.
- Localizzazione: IT, EN, ES, FR, DE; layout resilienti.

---

## 14. Roadmap (prime 8 settimane)

| Periodo | Attività | Deliverable |
| --- | --- | --- |
| **W1–W2** | Repo/CI setup, OpenAPI v1, Onboarding & Auth, Telemetria base, SLO login | `ff.onboarding.v1` al 1% |
| **W3–W4** | Catalogo + game loop, leaderboard service, E2E punteggio, seed admin | `ff.catalog.v1` 5%, `ff.leaderboard.v1` 5% |
| **W5–W6** | Wallet RO, ledger, transfer P2P, reconciliation v0, anti-frode minimo | `ff.wallet.readonly` 10%, `ff.ledger.transfers` 1% |
| **W7–W8** | Inviti & social, Ads cohort, hardening sicurezza, canary internazionale | `ff.invites.v1` 5%, `ff.ads.enabled` 5%, `ff.multi.country` pilota |

### Definition of Ready / Done

- **DoR**: Contratto API approvato, mock payload, UX criteria, stima QA, flag creato, SLO definiti.
- **DoD**: Test unit/contract/E2E verdi, metriche e alert attivi, documentazione ADR/runbook aggiornata, rollout minimo in prod completato senza regressioni.

---

## 15. Modello dati & architettura (PostgreSQL)

### 15.1 Linee guida

- Naming snake_case, PK UUID v7, FK `<entity>_id`.
- Schemi separati: `app`, `finance`, `ads`, `comm`, `cfg`, `exp`, `audit`, `obs`, `risk`, `i18n`, `core_pii`.
- Multipaese: `country_code` ISO, partizionamento per paese o data.
- Event sourcing ibrido: stato normalizzato + append-only per audit.
- Partizioni: tabelle volumetriche per `occurred_at`/`created_at`.
- Concorrenza: transazioni serializzabili per ledger; row-level locking.

### 15.2 Entità principali (overview)

- **Identità**: `user`, `user_profile`, `user_device`, `auth_session`, `user_role`.
- **Privacy**: `user_consent`, `privacy_request`.
- **Social**: `invite`, `friendship`, `group`, `group_member`, `referral`.
- **Giochi**: `game`, `game_variant`, `play_session`, `score_event`, `leaderboard`, `leaderboard_entry`, `achievement`, `user_achievement`, `anti_fraud_signal`, `play_session_flag`.
- **Economia**: `wallet`, `ledger_entry`, `transfer`, `economy_rule`, `loon_token`, `loon_token_owner`.
- **ADV**: `ad_provider`, `ad_placement`, `ad_impression`, `ad_click`, `revenue_event`.
- **Notifiche**: `message_template`, `outbox_message`, `push_token`.
- **Config**: `feature_flag`, `feature_assignment`, `ab_test`, `ab_assignment`, `app_config`.
- **Osservabilità**: `audit_log`, `app_event`.
- **Sicurezza**: `rate_limit_bucket`, `ip_block`, `user_block`.

### 15.3 Schema Loon Token (tracciabilità)

```sql
CREATE TABLE finance.loon_token (
  id BIGSERIAL PRIMARY KEY,
  status SMALLINT NOT NULL CHECK (status IN (1,2,3)),
  current_wallet_id UUID NULL REFERENCES app.wallet(id),
  minted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_moved_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE finance.loon_token_owner (
  token_id BIGINT NOT NULL REFERENCES finance.loon_token(id),
  wallet_id UUID NOT NULL REFERENCES app.wallet(id),
  from_at TIMESTAMPTZ NOT NULL,
  to_at TIMESTAMPTZ NULL,
  to_reason VARCHAR(16) NULL,
  PRIMARY KEY (token_id, from_at)
);
```

- Garantiscono la riconciliazione puntuale tra ledger e token.

### 15.4 Ledger & Transfer (estratto)

```sql
CREATE TABLE finance.ledger_entry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES app.wallet(id),
  transfer_id UUID NULL,
  direction SMALLINT NOT NULL CHECK (direction IN (1,-1)),
  amount BIGINT NOT NULL CHECK (amount > 0),
  balance_after BIGINT NOT NULL,
  currency VARCHAR(8) NOT NULL DEFAULT 'LOONS',
  reason VARCHAR(24) NOT NULL,
  ref_type VARCHAR(24),
  ref_id UUID,
  occurred_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (occurred_at);

CREATE TABLE finance.transfer (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_wallet_id UUID NOT NULL REFERENCES app.wallet(id),
  to_wallet_id UUID NOT NULL REFERENCES app.wallet(id),
  amount BIGINT NOT NULL CHECK (amount > 0),
  fee BIGINT NOT NULL DEFAULT 0,
  status SMALLINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  settled_at TIMESTAMPTZ
);
```

- Trigger transactionale: crea debit/credit atomici, aggiorna token owner.

### 15.5 Indici chiave

- `idx_play_session_user_started (user_id, started_at)`.
- `idx_leaderboard_entry_score_desc (leaderboard_id, score DESC)`.
- `idx_ledger_wallet_time (wallet_id, occurred_at)`.
- `idx_ads_impr_placement_time (placement_id, served_at)`.
- `gin_idx_outbox_message_payload` su JSONB.
- `brin_idx_event_time` su `obs.app_event(occurred_at)`.
- `idx_loon_owner_wallet_from (wallet_id, from_at)`.

### 15.6 Query esempio

```sql
-- Saldo corrente dal ledger
SELECT balance_after
FROM finance.ledger_entry
WHERE wallet_id = $1
ORDER BY occurred_at DESC, id DESC
LIMIT 1;

-- Token attuali di un utente
SELECT t.id, t.minted_at, t.last_moved_at
FROM finance.loon_token t
JOIN app.wallet w ON w.id = t.current_wallet_id
WHERE w.user_id = $1 AND t.status = 1
ORDER BY t.id;
```

### 15.7 Partizionamento & housekeeping

- `play_session`, `ledger_entry`, `ad_impression`, `ad_click`, `revenue_event`, `app_event`, `loon_token_owner` partizionate per mese.
- Materialized view per KPI giornalieri/mensili.
- Export periodico in formato Parquet su data lake.

---

## 16. Cloud-native reference architecture

### 16.1 Obiettivi

- 100% managed/serverless (no VM) dove possibile.
- Region primaria Milano (AWS eu-south-1 / GCP europe-west8), DR Irlanda/Beglio.
- RPO ≤ 5 min, RTO ≤ 60 min.
- Infra as Code (Terraform) – ambienti dev/stage/prod.

### 16.2 AWS mapping

| Dominio | Servizio |
| --- | --- |
| Compute | AWS Lambda (BFF), ECS Fargate (servizi Go), EventBridge Scheduler |
| DB | Amazon Aurora PostgreSQL Serverless v2 (Global DB) |
| Cache | ElastiCache Redis |
| Messaging | SQS, SNS |
| Storage | S3 (+ Glacier) |
| CDN | CloudFront + Lambda@Edge |
| Identity | Cognito, IAM, WAF, Shield |
| API | API Gateway (HTTP) |
| Secrets | Secrets Manager, SSM Parameter Store |
| Observability | CloudWatch, X-Ray, OTel → AMP/Grafana |
| Data/ML | Kinesis Firehose, S3, Athena/Glue, Redshift Serverless, SageMaker |
| Push/Email | SNS mobile push, SES |

### 16.3 Google Cloud mapping

| Dominio | Servizio |
| --- | --- |
| Compute | Cloud Run, Cloud Functions, Cloud Scheduler |
| DB | Cloud SQL for PostgreSQL HA / AlloyDB |
| Cache | MemoryStore Redis |
| Messaging | Pub/Sub |
| Storage | Cloud Storage |
| CDN | Cloud CDN + Load Balancing |
| Identity | Identity Platform, IAM, Cloud Armor |
| API | API Gateway |
| Secrets | Secret Manager |
| Observability | Cloud Logging/Monitoring/Trace, OTel |
| Data/ML | BigQuery, Dataflow, Vertex AI |

### 16.4 Networking & sicurezza

- VPC privato, subnet dedicate, NAT controllato.
- DB in subnet private, accesso tramite SG/Firewall.
- Zero Trust per admin (IAM Identity Center / IAP).
- WAF su edge, rate limit su API.
- Backup/DR: snapshot continui, cross-region replica, DR drill trimestrali.

### 16.5 CI/CD & IaC

- Repo monorepo (app + infra); branch `main` → Terraform plan, tag release → apply prod.
- Terraform workspace per env.
- Pipeline "a semaforo" (build → contract test → docker → deploy dev → canary stage → promote prod).

### 16.6 Integrazione dati

- Job di riconciliazione ledger ↔ LOONS come serverless cron.
- Outbox `comm.outbox_message` drenata da consumer su SQS/Pub/Sub.
- Export tabelle partizionate verso S3/GCS per analytics.

---

## 17. Appendici

### 17.1 Principali feature flag (stato iniziale)

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

### 17.2 Telemetria eventi chiave

| Evento | Parametri | Scopo |
| --- | --- | --- |
| `combine_view_start` | combine_id, sponsor_id | Impression feed |
| `combine_card_played` | card_type, outcome | Engagement |
| `loons_balance_updated` | delta, total | Monitor economie |
| `mission_completed` | mission_id, reward | Progression |
| `invite_sent` | channel | Viralità |
| `card_payment_discount_applied` | amount_loons, amount_fiat | Uso XXX-CARD |
| `adv_click` | sponsor_id | Performance ADV |

### 17.3 Edge KPI guardrail

- Crash rate app < 0,5%.
- p95 login < 400 ms.
- p95 transfer LOONS < 500 ms.
- Errori 5xx BFF < 0,2%.
- Churn ▲ < 1 p.p. durante rollout.

---

**Stato repository:** tutte le modifiche sono locali (non committed).  
**File generati:** `REQUISITI-FUNZIONALI-APP-XXX.md` (presente nella root progetto).
