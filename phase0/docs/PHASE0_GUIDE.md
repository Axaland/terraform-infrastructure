# Guida operativa — Fase 0 (Bootstrap)

Questa guida descrive i passaggi concreti per portare online il minimo funzionante della APP XXX secondo quanto definito nella roadmap.

## Obiettivo finale

*Monorepo funzionante con:* 
- BFF Node.js che espone `GET /healthz` (ritorna `{ "status": "OK" }`).
- App Flutter che mostra una schermata welcome e chiama il BFF mostrando il valore di `status`.
- Template Next.js per la console admin (placeholder).
- Servizio Go con `/healthz` pronto a ricevere estensioni.
- Ambiente Terraform iniziale in grado di effettuare il provisioning delle risorse condivise (VPC, RDS, Redis, ECS).

## Step 1 — Setup repository

1. Posizionarsi nella cartella `phase0/`.
2. Eseguire `pnpm install` per installare le dipendenze del BFF.
3. Se necessario, installare le dipendenze Flutter (`flutter pub get` dentro `apps/mobile`).
4. Per Next.js, lanciare `pnpm install` nella cartella `apps/admin` (una volta popolata).

## Step 2 — Avvio BFF

```powershell
cd phase0/services/bff
pnpm dev
```

Endpoint disponibile su `http://localhost:3000/healthz`.

## Step 3 — Avvio App Flutter

```powershell
cd phase0/apps/mobile
flutter run
```

L'app legge `BFF_BASE_URL` da `lib/config.dart`. Aggiornare il valore in base alla rete locale (es. `http://10.0.2.2:3000`).

## Step 4 — Avvio servizio Go

```powershell
cd phase0/services/go-template
go run ./cmd/server
```

### Verifica manuale

```powershell
curl http://localhost:8080/healthz
```

## Step 5 — Terraform (dev)

1. Copiare/riusare i moduli già presenti sotto `infra/terraform` del repository radice.
2. Aggiungere eventuali nuovi moduli (es. `redis`) collegandoli al BFF.
3. Eseguire:

```powershell
cd ..\..\infra\terraform\dev
terraform init
terraform plan
```

## Step 6 — CI/CD

- Configurare GitHub Actions (file `.github/workflows/ci-phase0.yml`).
- Job suggeriti: lint (Node, Flutter, Go), unit test, build immagini.
- Setup OIDC già presente per Terraform.

## Step 7 — Feature flag

- Creare file `apps/mobile/lib/feature_flags.dart` con flag `auth_v1 = false`.
- Prevedere un provider centralizzato in BFF per abilitare/disabilitare feature.

## Output atteso

- `pnpm lint` → senza errori.
- `pnpm test` → esegue test base BFF (da completare).
- `flutter analyze` → senza errori.
- `go test ./...` nel servizio template → ok.
- Chiamata app → visualizza "OK".

## Prossimi passi (Fase 1)

- Implementare `POST /v1/auth/register`, `POST /v1/auth/login`, `GET /v1/users/me`.
- Aggiungere migrazione `0002` e repository utenti.
- Aggiornare Flutter con schermate Registrazione/Login.
- Aggiornare CI con test integration BFF.
