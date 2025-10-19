# Servizio Go Template — Fase 0

Skeleton per i microservizi hot-path in Go. Espone esclusivamente l'endpoint `/healthz` ed è pensato come base per servizi come scoreboard, ads orchestrator e ledger.

## Requisiti

- Go 1.22+

## Sviluppo

```powershell
cd phase0/services/go-template
go run ./cmd/server
```

Il servizio sarà disponibile su `http://localhost:8080/healthz`.

## Struttura

```
go-template/
├── cmd/server/main.go   # entrypoint HTTP
├── go.mod               # modulo Go
└── README.md
```

## Prossimi passi

- Aggiungere middleware per logging/telemetria
- Integrare configurazione tramite file `.env`
- Preparare Dockerfile e pipeline di build
