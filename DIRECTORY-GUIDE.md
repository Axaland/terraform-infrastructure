# Guida alle Directory

## Scopo
Questa guida centralizza l'elenco delle directory che compongono il progetto, così che ogni documento o script possa fare riferimento a un'unica fonte autorevole. Tutti i percorsi sono relativi alla radice del repository, salvo diversa indicazione.

## Convenzioni sui percorsi
- Preferisci i separatori POSIX (`/`) quando documenti i percorsi: gli strumenti su Windows li interpretano correttamente e la documentazione resta coerente con le convenzioni di Terraform, Flutter e Node.js.
- Quando crei nuovi script, risolvi i percorsi relativamente alla radice del repository per evitare problemi legati a directory home specifiche dell'utente o cartelle sincronizzate (ad esempio OneDrive).

## Struttura principale
| Percorso | Descrizione |
| --- | --- |
| `/infra/` | Asset di infrastructure-as-code per tutti gli ambienti. |
| `/infra/terraform/README.md` | Note di onboarding e istruzioni d'uso specifiche per Terraform. |
| `/infra/terraform/bootstrap/` | Stack di bootstrap che crea bucket S3 e tabella DynamoDB per lo state. |
| `/infra/terraform/dev/` | Configurazione Terraform dell'ambiente di sviluppo (backend + stack principale). |
| `/infra/terraform/stage/` | Configurazione Terraform dell'ambiente di staging (backend + stack principale). |
| `/infra/terraform/prod/` | Configurazione Terraform dell'ambiente di produzione (backend + stack principale). |
| `/infra/terraform/modules/` | Moduli Terraform riusabili consumati dagli stack di ambiente. |
| `/infra/terraform/modules/vpc/` | Primitive per VPC e networking. |
| `/infra/terraform/modules/ecs_fargate_service/` | Definizione del servizio ECS per i workload applicativi. |
| `/infra/terraform/modules/rds_postgres/` | Provisioning dell'istanza RDS PostgreSQL. |
| `/infra/terraform/modules/rds_backup/` | Job di backup RDS e utilità per la retention automatica. |
| `/infra/terraform/modules/cloudwatch_alarms/` | Allarmi CloudWatch condivisi tra gli ambienti. |
| `/infra/terraform/modules/cloudwatch_dashboard/` | Dashboard CloudWatch per l'osservabilità. |
| `/infra/terraform/modules/cloudwatch_synthetics_canary/` | Canary sintetici per monitorare gli endpoint di salute. |
| `/infra/terraform/modules/iam_github_oidc/` | Ruolo e policy IAM per la federazione OIDC con GitHub Actions. |
| `/infra/terraform/modules/security_baseline/` | Controlli di sicurezza di base (guardrail, logging, ecc.). |
| `/infra/terraform/modules/waf_alb/` | Configurazione AWS WAF per l'Application Load Balancer. |
| `/infra/terraform/modules/budgets/` | Budget di costo e alert per il controllo della spesa. |
| `/minimal-dev/` | Impronta infrastrutturale minima (bootstrap OIDC) usata in fase iniziale. |
| `/phase0/` | Monorepo di bootstrap applicativo con shell dei servizi e tooling. |
| `/phase1/` | Deliverable dell'applicazione fase 1 (registrazione/login) con Flutter, BFF e servizi backend. |
| `/backups/` | Backup dello state e della configurazione Terraform (archivi zip). |
| `/add-rds-tags.ps1`, `/deploy-infrastructure.ps1`, ecc. | Script PowerShell di supporto per deploy e verifiche. |

## Monorepo applicativo (`/phase0/`)
| Percorso | Descrizione |
| --- | --- |
| `/phase0/package.json` | Definizione del workspace PNPM e script di automazione. |
| `/phase0/apps/admin/` | Frontend amministrativo (Next.js). |
| `/phase0/apps/mobile/` | Shell Flutter con smoke test e runner di piattaforma. |
| `/phase0/services/bff/` | Servizio backend-for-frontend basato su Fastify con Vitest ed ESLint. |
| `/phase0/services/go-template/` | Template di servizio Go con router chi e logging zerolog. |
| `/phase0/test/` | Test trasversali (es. widget test Flutter). |
| `/phase0/README.md` | Flusso di lavoro per gli sviluppatori con lint/test. |

## Deliverable Fase 1 (`/phase1/`)
| Percorso | Descrizione |
| --- | --- |
| `/phase1/pubspec.yaml` | Dipendenze Flutter per le funzionalità della fase 1. |
| `/phase1/apps/mobile/` | Implementazione principale dell'app mobile Flutter. |
| `/phase1/services/bff/` | Servizio backend-for-frontend per l'ambito della fase 1. |
| `/phase1/services/` | Ulteriori servizi applicativi (da estendere man mano che le feature arrivano in produzione). |
| `/phase1/docs/` | Documentazione della fase 1 (test plan, ADR, runbook, specifiche OpenAPI). |
| `/phase1/infra/` | Asset infrastrutturali della fase 1 (Docker compose, migrazioni, ecc.). |
| `/phase1/README.md` | Panoramica e istruzioni di setup per la fase 1. |

## Backup infrastrutturali (`/backups/`)
- I file seguono il pattern `terraform-infrastructure-YYYYMMDD-HHmmss.zip`.
- Ogni archivio cattura lo stato della configurazione Terraform in un dato momento; quando si ripristina partire da un backup, annotare note aggiuntive in `DEPLOYMENT-SUMMARY.md`.

## Documentazione
| Percorso | Descrizione |
| --- | --- |
| `/DEPLOYMENT-GUIDE.md` | Istruzioni passo-passo per il deploy dell'infrastruttura. |
| `/DEPLOYMENT-SUMMARY.md` | Registro di ogni esecuzione di deploy. |
| `/BACKUP-RESTORE-GUIDE.md` | Procedure per il ripristino dai backup. |
| `/APP-XXX-IMPLEMENTATION-PLAN.md` | Roadmap di implementazione del progetto. |
| `/REQUISITI-FUNZIONALI-APP-XXX.md` | Riferimento ai requisiti funzionali. |
| `/SESSION-LOG-YYYY-MM-DD.md` | Log di sessione con note operative. |
| `/DESCRIZIONE-ARCHITETTURA.md` | Panoramica architetturale e topologia corrente dei componenti. |

## Note d'uso
- Quando aggiungi una nuova directory, aggiorna questa guida nella sezione appropriata includendo una descrizione sintetica.
- Nei nuovi documenti fai riferimento a questo file (`DIRECTORY-GUIDE.md`) invece di duplicare gli elenchi dei percorsi; quando possibile usa ancore Markdown per rimandare alla sezione pertinente.
- Gli script che dipendono da directory specifiche dovrebbero includere controlli di validazione (ad esempio `Test-Path`) e indirizzare i maintainer a questa guida quando una directory manca.
