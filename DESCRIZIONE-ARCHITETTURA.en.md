# Architecture Description

## Objective
This document provides a concise, reasoned view of the infrastructure built with Terraform to support the XXX application. In addition to describing the main components and operational flows, it includes the complete list of files and directories in the repository, with a particular focus on the `infra/terraform` folder.

## Overview
- **Provider**: Amazon Web Services (AWS).
- **Environments**: `dev`, `stage`, `prod`, each with dedicated Terraform configurations.
- **Deployment model**: reusable modular infrastructure orchestrated through PowerShell/Bash scripts and shared Terraform modules.
- **Key technologies**: Amazon VPC, ECS Fargate, Application Load Balancer, AWS WAF, Amazon RDS for PostgreSQL, AWS Backup, CloudWatch (dashboard, alarms, synthetics), Secrets Manager, GuardDuty, AWS Config, AWS Budgets.

## Logical Architecture
1. **Networking and connectivity**
   - Dedicated VPC per environment, with public and private multi-AZ subnets.
   - Optional NAT Gateway (enabled in `dev` and `prod`), VPC Endpoint in `prod` for managed services.
2. **Application layer**
   - ECS Fargate cluster with a primary service running the application container.
   - Public Application Load Balancer with `/health` health check and HTTP listener.
   - Service auto scaling based on CPU utilization metrics.
3. **Security**
   - AWS WAF with managed rule set and IP rate limiting.
   - Dedicated Security Groups for ALB, ECS Service, and VPC endpoints.
   - AWS Secrets Manager for database credentials.
4. **Data and persistence**
   - Private Amazon RDS PostgreSQL instance with environment-specific backup retention.
   - AWS Backup with daily plan and optional cross-region copy.
5. **Observability and FinOps**
   - CloudWatch Dashboard, alarms on ALB/ECS, and synthetics canary for `/health`.
   - AWS Budgets with email notifications at 80% and 100% thresholds and daily forecast reports.
   - AWS Cost Anomaly Detection with service-level monitor, filtered by `Environment` tag, dual subscription (Actual + Forecasted), and SNS topic dedicated to FinOps.
   - GuardDuty enabled (stage/prod) and AWS Config with managed rules (S3 public access, EBS/RDS encryption, SSH ingress) and alerts via SNS/Slack (ChatOps) through AWS Chatbot.
6. **Automation and pipeline**
   - IAM OIDC module (ready to use) to federate GitHub Actions.
   - Scripts `deploy-infrastructure.ps1`, `test-deployment.ps1`, `complete-deploy.ps1` orchestrate rollouts.

## Secret Management and Sensitive Variables
- **Runtime secrets**: `module.rds.db_secret_arn` distributes username/password through AWS Secrets Manager. The secret is injected into the ECS task as an environment variable (`DB_PASSWORD`) and doesn’t appear in the Terraform state.
- **Credential rotation**: update the secret in Secrets Manager (manually or via pipeline) and force a new ECS deployment (`terraform apply`, `Invoke-EcsServiceRefresh.ps1`, or GitHub workflow with `refresh_service=true`) to propagate the new credentials.
- **Minimized IAM scope**: the ECS execution role exported by `module.service` is the only one authorized (`iam:PassRole`) by the `iam_github_oidc` module, reducing the scope available to GitHub Actions runners.
- **Override variables**: parameters such as `alert_emails`, `budget_alert_emails`, canary schedule, and GitHub repository can be overridden using `*.tfvars` files. Store configuration files in a secret store (encrypted SSM Parameter Store, Secrets Manager, or the CI vault).

## Environments and Key Differences
| Feature | dev | stage | prod |
| --- | --- | --- | --- |
| VPC CIDR | `10.10.0.0/16` | `10.20.0.0/16` | `10.30.0.0/16` |
| Desired/min/max ECS | 2 / 2 / 4 | 2 / 2 / 6 | 3 / 3 / 10 |
| NAT Gateway | Enabled | Disabled | Enabled |
| RDS Backup | 7 days + cross-region replica | 7 days | 14 days |
| Monthly budget | 200 USD | 600 USD | 2,500 USD |
| WAF rate limit | 1,500 req/5min | 1,200 req/5min | 1,000 req/5min |
| GuardDuty/Config | Config on, GuardDuty optional (off) | Config on, GuardDuty on | Config on, GuardDuty on |
| Extra observability | Alarms + canary enabled | Dashboard | Dashboard + VPC endpoint |

## Deployment Flow
1. Optional bootstrap (`infra/terraform/bootstrap`) to create the S3 bucket and DynamoDB table used as the remote Terraform backend.
2. For each environment:
   1. `cd infra/terraform/<env>`
   2. `terraform init`
   3. `terraform plan`
   4. `terraform apply`
3. PowerShell and Bash scripts simplify end-to-end automation (`deploy-infrastructure.ps1`, `test-deployment.ps1`, `github-setup.sh`, etc.).

## File and Directory Listing
Below is the complete repository structure, including individual files. For brevity, the tree representation is sorted alphabetically and includes a short description.

```
.
├── .git/                               # Local Git repository
├── .github/                            # GitHub workflows or templates (if present)
├── .gitignore
├── APP-XXX-IMPLEMENTATION-PLAN.md
├── BACKUP-RESTORE-GUIDE.md
├── DESCRIZIONE-ARCHITETTURA.md         # This document
├── DEPLOYMENT-GUIDE.md
├── DEPLOYMENT-SUMMARY.md
├── README.md                           # Project overview
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
│   │   └── rds-drill-restore.md           # RDS cross-region drill runbook
│   ├── scripts/
│   │   ├── Invoke-EcsServiceRefresh.ps1   # Force deployment after secret rotation
│   │   └── Invoke-RdsDrillRestore.ps1     # PowerShell script for RDS drill
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

> Note: directories showing `...` contain additional framework-generated files (for example, Flutter within the `windows/` folder).

## Useful References
- `DEPLOYMENT-GUIDE.md`: step-by-step operational instructions.
- `BACKUP-RESTORE-GUIDE.md`: detailed database backup and restore procedures.
- `APP-XXX-IMPLEMENTATION-PLAN.md` and `REQUISITI-FUNZIONALI-APP-XXX.md`: functional context and roadmap.

## Suggested Next Steps
1. **ChatOps compliance integration**: connect the AWS Config SNS topic to Slack / Microsoft Teams via webhook for real-time notifications.
2. **Automated post-drill testing**: add a playbook to run smoke-test queries on the restored instance and attach results to the JSON report.
3. **Secret management**: further document sensitive variables and orchestrate automatic ECS restarts after rotations.
4. **Conformance Pack**: evaluate adopting the AWS Config Conformance Pack "Operational Best Practices for CIS" to broaden controls.
5. **Data resilience**: automate post-drill application validation (already available via `-TestQuery`) by integrating it into the CI/CD pipeline with attached reports.
