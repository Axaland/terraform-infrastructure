# Mobile App Shell — Fase 0

App Flutter minimale che mostra una schermata di benvenuto e interroga il BFF `/healthz`.

## Avvio

```powershell
cd phase0/apps/mobile
flutter pub get
flutter run --dart-define=BFF_BASE_URL=http://localhost:3000
```

## Funzionalità incluse

- Splash/Welcome screen
- Chiamata HTTP al BFF
- Visualizzazione stato servizio
- Gestione errori e retry

## Prossimi passi (Fase 1)

- Routing Onboarding → Register → Login
- Gestione stato con Riverpod/Bloc
- Persistenza token e guardie di navigazione
