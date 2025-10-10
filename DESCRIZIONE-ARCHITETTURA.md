# Descrizione Architettura

## Obiettivo
Questo documento fornisce una vista sintetica e ragionata dell'infrastruttura realizzata con Terraform per supportare l'applicazione XXX. Oltre a descrivere i componenti principali e i flussi operativi, include l'elenco completo dei file e delle directory presenti nel repository, con particolare attenzione alla cartella `infra/terraform`.

## Visione d'insieme
- **Provider**: Amazon Web Services (AWS).
- **Ambienti**: `dev`, `stage`, `prod`, ciascuno con configurazioni Terraform dedicate.
- **Deployment model**: infrastruttura modulare riusabile, orchestrata tramite script PowerShell/Bash e moduli Terraform condivisi.
- **Tecnologie chiave**: Amazon VPC, ECS Fargate, Application Load Balancer, AWS WAF, Amazon RDS for PostgreSQL, AWS Backup, CloudWatch (dashboard, allarmi, synthetics), Secrets Manager, GuardDuty, AWS Config, AWS Budgets.

## Architettura logica
1. **Networking e connettività**
   - VPC dedicata per ambiente, con subnet pubbliche e private multi-AZ.
   - NAT Gateway opzionale (abilitato in `dev` e `prod`), VPC Endpoint in `prod` per servizi gestiti.
2. **Layer applicativo**
   - Cluster ECS Fargate con un servizio principale che esegue il container applicativo.
   - Application Load Balancer pubblico con health check di `/health` e listener HTTP.
   - Auto scaling del servizio basato su metriche di utilizzo CPU.
3. **Sicurezza**
   - AWS WAF con rule set gestito e rate limiting per IP.
   - Security Group dedicati per ALB, ECS Service e VPC endpoint.
   - AWS Secrets Manager per le credenziali del database.
4. **Dati e persistenza**
   - Amazon RDS PostgreSQL privato, con retention backup configurata per ambiente.
   - AWS Backup con piano giornaliero e copia cross-region opzionale.
5. **Osservabilità e FinOps**
   - CloudWatch Dashboard, allarmi su ALB/ECS e canary synthetics per `/health`.
   - AWS Budgets con notifiche email su soglie 80% e 100% e report giornalieri di forecast.
   - AWS Cost Anomaly Detection con monitor per servizio, filtro per tag `Environment`, doppio abbonamento (Actual + Forecasted) e topic SNS dedicato a FinOps.
   - GuardDuty attivo (stage/prod) e AWS Config con regole gestite (S3 public access, EBS/RDS encryption, SSH ingress) e alert via SNS/Slack (ChatOps) grazie a AWS Chatbot.
6. **Automazione e pipeline**
   - Modulo IAM OIDC (pronto all'uso) per federare GitHub Actions.
   - Script `deploy-infrastructure.ps1`, `test-deployment.ps1`, `complete-deploy.ps1` per orchestrare i rollout.

## Gestione secret e variabili sensibili
- **Segreti runtime**: `module.rds.db_secret_arn` distribuisce username/password tramite AWS Secrets Manager. Il secret viene iniettato nel task ECS come variabile d'ambiente (`DB_PASSWORD`) e non compare nello state Terraform.
- **Rotazione credenziali**: aggiornare il secret in Secrets Manager (manualmente o via pipeline) e forzare un nuovo deploy ECS (`terraform apply`, `Invoke-EcsServiceRefresh.ps1` o workflow GitHub con `refresh_service=true`) per propagare le nuove credenziali.
- **Scope IAM minimizzato**: l'execution role ECS esportato da `module.service` è l'unico autorizzato (`iam:PassRole`) dal modulo `iam_github_oidc`, riducendo lo scope dei GitHub Actions runner.
- **Variabili override**: parametri come `alert_emails`, `budget_alert_emails`, schedule dei canary e repository GitHub possono essere sovrascritti tramite file `*.tfvars`. Conservare i file di configurazione in un secret store (SSM Parameter Store cifrato, Secrets Manager o vault del CI).

## Ambienti e differenze principali
| Caratteristica | dev | stage | prod |
| --- | --- | --- | --- |
| CIDR VPC | `10.10.0.0/16` | `10.20.0.0/16` | `10.30.0.0/16` |
| Desired/min/max ECS | 2 / 2 / 4 | 2 / 2 / 6 | 3 / 3 / 10 |
| NAT Gateway | Abilitato | Disabilitato | Abilitato |
| Backup RDS | 7 giorni + replica cross-region | 7 giorni | 14 giorni |
| Budget mensile | 200 USD | 600 USD | 2.500 USD |
| WAF rate limit | 1.500 req/5min | 1.200 req/5min | 1.000 req/5min |
| GuardDuty/Config | Config on, GuardDuty opzionale (off) | Config on, GuardDuty on | Config on, GuardDuty on |
| Osservabilità extra | Allarmi + canary abilitati | Dashboard | Dashboard + VPC endpoint |

## Flusso operativo di deploy
1. Bootstrap opzionale (`infra/terraform/bootstrap`) per creare bucket S3 e tabella DynamoDB utilizzabili come backend remoto Terraform.
2. Per ciascun ambiente:
   1. `cd infra/terraform/<env>`
   2. `terraform init`
   3. `terraform plan`
   4. `terraform apply`
3. Script PowerShell e Bash facilitano l'automazione end-to-end (`deploy-infrastructure.ps1`, `test-deployment.ps1`, `github-setup.sh`, ecc.).

## Elenco file e directory
Di seguito la struttura completa del repository, comprensiva di file singoli. Per brevità adottiamo una rappresentazione ad albero (ordinata alfabeticamente) con una breve descrizione.

```
.
├── .git/                               # Repository Git locale
├── .github/                            # Workflow o template GitHub (se presenti)
├── .gitignore
├── APP-XXX-IMPLEMENTATION-PLAN.md
├── BACKUP-RESTORE-GUIDE.md
├── DESCRIZIONE-ARCHITETTURA.md         # Questo documento
├── DEPLOYMENT-GUIDE.md
├── DEPLOYMENT-SUMMARY.md
├── README.md                           # Panoramica generale progetto
├── REQUISITI-FUNZIONALI-APP-XXX.md
├── SESSION-LOG-2025-10-08.md
├── add-rds-tags.ps1
├── complete-deploy.ps1
├── deploy-infrastructure.ps1
├── github-setup-clean.sh
├── github-setup.sh
├── test-deployment.ps1
├── verify-deployment.ps1
├── backups/
│   ├── terraform-infrastructure-20251008-115407.zip
│   ├── terraform-infrastructure-20251008-140722.zip
│   └── terraform-infrastructure-20251008-141011.zip
├── infra/
│   ├── runbooks/
│   │   └── rds-drill-restore.md           # Runbook drill RDS cross-region
│   ├── scripts/
│   │   ├── Invoke-EcsServiceRefresh.ps1   # Force deployment post-rotazione secret
│   │   └── Invoke-RdsDrillRestore.ps1     # Script PowerShell per drill RDS
│   └── terraform/
│       ├── README.md
│       ├── bootstrap/
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   ├── providers.tf
│       │   ├── variables.tf
│       │   └── versions.tf
│       ├── dev/
│       │   ├── backend.tf
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   ├── providers.tf
│       │   ├── variables.tf
│       │   └── versions.tf
│       ├── modules/
│       │   ├── budgets/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── chatops_notifications/
│       │   │   └── main.tf
│       │   ├── cost_anomaly_detection/
│       │   │   └── main.tf
│       │   ├── cloudwatch_alarms/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── cloudwatch_dashboard/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── cloudwatch_synthetics_canary/
│       │   │   ├── main.tf
│       │   │   ├── templates/
│       │   │   │   └── canary.js.tpl
│       │   │   └── variables.tf
│       │   ├── ecr/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── ecs_fargate_service/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── iam_github_oidc/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── rds_backup/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── rds_postgres/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── security_baseline/
│       │   │   ├── main.tf
│       │   │   └── variables.tf
│       │   ├── vpc/
│       │   │   ├── main.tf
│       │   │   ├── outputs.tf
│       │   │   └── variables.tf
│       │   └── waf_alb/
│       │       ├── main.tf
│       │       └── variables.tf
│       ├── prod/
│       │   ├── backend.tf
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   ├── providers.tf
│       │   ├── variables.tf
│       │   └── versions.tf
│       └── stage/
│           ├── backend.tf
│           ├── main.tf
│           ├── outputs.tf
│           ├── providers.tf
│           ├── variables.tf
│           └── versions.tf
├── minimal-dev/
│   └── main.tf
└── phase1/
    ├── README.md
    ├── analysis_options.yaml
    ├── phase1.iml
    ├── pubspec.lock
    ├── pubspec.yaml
    ├── apps/
    │   └── mobile/
    │       ├── README.md
    │       ├── analysis_options.yaml
    │       ├── assets/
    │       ├── build/
    │       ├── codemagic.yaml
    │       ├── devtools_options.yaml
    │       ├── lib/
    │       ├── pubspec.lock
    │       ├── pubspec.yaml
    │       ├── run-app.ps1
    │       ├── test/
    │       ├── web/
    │       └── windows/
    ├── docs/
    │   ├── adr/
    │   │   └── 0001-flutter-state-management.md
    │   ├── openapi/
    │   │   └── auth-v1.yaml
    │   ├── runbooks/
    │   │   └── onboarding-rollback.md
    │   └── test-plan-phase1.md
    ├── infra/
    │   ├── docker-compose.dev.yml
    │   └── migrations/
    │       └── 0001_create_app_user.sql
    ├── lib/
    │   └── main.dart
    ├── services/
    │   └── bff/
    │       ├── Dockerfile
    │       ├── README.md
    │       ├── jest.config.ts
    │       ├── package.json
    │       ├── src/
    │       └── test/
    ├── test/
    │   └── widget_test.dart
    └── windows/
        ├── CMakeLists.txt
        └── ...
```

> Nota: all'interno delle directory dove compare `...` sono presenti ulteriori file generati da framework (ad esempio Flutter per cartella `windows/`).

## Collegamenti utili
- `DEPLOYMENT-GUIDE.md`: istruzioni operative passo-passo.
- `BACKUP-RESTORE-GUIDE.md`: procedure dettagliate per backup e ripristino database.
- `APP-XXX-IMPLEMENTATION-PLAN.md` e `REQUISITI-FUNZIONALI-APP-XXX.md`: contesto funzionale e roadmap.

## Prossimi passi suggeriti
1. **Integrazione ChatOps compliance**: collegare il topic SNS di AWS Config a Slack / Microsoft Teams via webhook per notifiche in tempo reale.
2. **Test automatico post-drill**: aggiungere un playbook che esegua query di smoke test sull'istanza ripristinata e alleghi i risultati al report JSON.
3. **Secret management**: documentare ulteriormente le variabili sensibili e orchestrare il riavvio ECS automatico dopo le rotazioni.
4. **Conformance Pack**: valutare l'adozione di AWS Config Conformance Pack "Operational Best Practices for CIS" per ampliare i controlli.
5. **Resilienza dati**: automatizzare la validazione applicativa post-drill (già disponibile via `-TestQuery`) integrandola nella pipeline CI/CD con report allegati.
