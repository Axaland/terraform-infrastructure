# ADR 0001 – Gestione dello stato in Flutter

## Contesto

La Fase 1 richiede un'app Flutter modulare con routing, feature flag e gestione sessione utente. Servono:
- Iniezione di configurazione (remote config, API base URL).
- Stato reattivo per sessione di autenticazione.
- Supporto a test unitari/widget.

## Decisione

Usiamo **Riverpod 2** come libreria di gestione stato e dipendenze:
- Provider globali con override per test/mocking.
- Compatibile con `go_router` per redirect basati su sessione.
- Integrazione con `AsyncValue` per gestire stati loading/error.

Router: `go_router` per sfruttare declarative routing + deep link nativi.

## Conseguenze

- Richiede `flutter_riverpod` e `go_router` nel `pubspec`.
- I provider principali (`authSessionProvider`, `appConfigProvider`) vanno definiti in moduli dedicati.
- I test devono usare `ProviderScope` e override.
- Documentare pattern per evitare cicli dipendenze.
