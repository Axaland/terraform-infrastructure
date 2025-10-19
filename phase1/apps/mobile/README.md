# XXX Mobile App – Fase 1

Shell Flutter con flow onboarding/auth federata e telemetria base.

## Setup

```powershell
flutter pub get
flutter run
```

Per usare il provider di identità locale aggiornare `assets/config/remote_config.json` con l'URL del BFF (es. `http://10.0.2.2:3000` in emulatori Android) e assicurarsi che `oidcSharedSecret` corrisponda all'ambiente backend. I flag in `featureFlags` controllano l'esperienza di onboarding.

### Test

```powershell
flutter test
```

### Lint

```powershell
flutter analyze
```

Gli widget test principali vivono in `test/widget_test.dart` e coprono onboarding, login e restore della sessione.
