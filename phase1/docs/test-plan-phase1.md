# Test Plan – Fase 1

| Tipo            | Scenario                                         | Strumento           | Note |
|-----------------|--------------------------------------------------|---------------------|------|
| Unit            | Validazione payload login                        | Jest + supertest    | mock id_token |
| Unit            | AuthRepository persiste token                    | Flutter test        | usare SharedPreferences.setMockInitialValues |
| Contract        | Mobile ↔ BFF (`/v1/auth/login`)                  | Pact                | provider state: utente esistente |
| E2E             | “Install → Onboarding → Login → Profilo”         | Flutter integration | device real/simulator |
| Load            | Login burst (p95 < 400ms)                        | k6/Gatling          | 50 RPS 1 min |
| Chaos (manual)  | Kill pod BFF durante login                       | kubectl delete pod  | verificare retry client |

## DoD Checklist
- [ ] Test unitari >= 70%
- [ ] Contract test passano in CI
- [ ] E2E onboarding verde su device pulito
- [ ] Dashboard login aggiornata con p95/errori
- [ ] Runbook rollback validato
