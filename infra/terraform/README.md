# Infrastruttura Terraform Multi-Environment

Questo repository definisce un'infrastruttura AWS modulare per ambienti `dev`, `stage` e `prod`, focalizzata su applicazione container (ECS Fargate), database PostgreSQL, sicurezza, osservabilità e governance dei costi.

## Struttura
```
infra/terraform/
  modules/
    vpc/
    rds_postgres/
    ecr/
    ecs_fargate_service/
    waf_alb/
    budgets/
    chatops_notifications/
    cost_anomaly_detection/
    iam_github_oidc/
    security_baseline/
  dev/
  stage/
  prod/
```

## Moduli
| Modulo | Scopo | Output principali |
|--------|-------|-------------------|
| vpc | Rete VPC + subnets + NAT | vpc_id, private_subnet_ids |
| rds_postgres | DB Postgres con secret credenziali | db_endpoint, db_secret_arn |
| ecr | Repositories immutabili ECR | repository_urls |
| ecs_fargate_service | Cluster, Service, Target Group, Autoscaling | service_name, cluster_arn |
| waf_alb | WAF WebACL + rate limit IP | web_acl_arn |
| budgets | Budget mensile con notifiche | budget_name |
| cost_anomaly_detection | AWS Cost Anomaly Detection (Actual + Forecast) + SNS | sns_topic_arn, forecast_subscription_arn |
| chatops_notifications | Configura AWS Chatbot verso Slack/Teams | chatops_configuration_name |
| iam_github_oidc | Ruolo IAM federato GitHub Actions | ci_role_arn |
| security_baseline | GuardDuty + AWS Config + regole gestite + SNS compliance | guardduty_detector_id, config_bucket_name, config_sns_topic_arn |

## Secrets nel Task ECS
I secrets sono passati come mappa `ENV_VAR => ARN` al modulo `ecs_fargate_service` e tradotti in `secrets` della container definition (ECS). Esempio:
```hcl
module "service" {
  source            = "../modules/ecs_fargate_service"
  env               = var.env_name
  service_name      = "app"
  image             = var.service_image
  private_subnet_ids= module.vpc.private_subnet_ids
  vpc_id            = module.vpc.vpc_id
  secrets = {
    DB_PASSWORD = module.rds.db_secret_arn
  }
}
```

### Rotazione secret
- Aggiorna il secret in AWS Secrets Manager (manualmente o tramite pipeline) senza modificare lo state Terraform.
- Esegui `terraform apply` o un restart controllato del servizio ECS per forzare l'uso del nuovo secret.
- Per restart controllati è disponibile lo script `infra/scripts/Invoke-EcsServiceRefresh.ps1` oppure il workflow GitHub `terraform-ci` con input `refresh_service=true`.
- Ricorda di includere eventuali nuovi secret in `allowed_secrets_arns` quando estendi il ruolo CI creato dal modulo `iam_github_oidc`.

## WAF e Rate Limiting
Il modulo `waf_alb` applica regole gestite AWS + una regola rate-based configurabile tramite `waf_rate_limit` (richieste / 5 minuti per IP).

## Budget
Il modulo `budgets` crea un budget mensile con due notifiche: 80% ACTUAL, 100% FORECASTED.

## Security Baseline
Abilita GuardDuty e AWS Config con controlli aggiuntivi:
- Bucket cifrato + versioning per snapshot.
- Recorder + delivery channel con SNS notifiche (`config_notification_emails`) e collegamento opzionale a Slack tramite modulo `chatops_notifications`.
- Detector GuardDuty con S3 logs.
- Regole gestite AWS Config: S3 public access, EBS/RDS encryption, Required Tags, SSH ingress.

## Differenze Ambiente
| Ambiente | Scaling ECS | Backup RDS | Budget USD | Rate Limit |
|----------|-------------|-----------|------------|------------|
| dev | 1-4 (desired 1) | 7 giorni | 200 | 1500 |
| stage | 2-6 (desired 2) | 7 giorni | 600 | 1200 |
| prod | 3-10 (desired 3) | 14 giorni | 2500 | 1000 |

## Variabili Principali (dev esempio)
```hcl
variable "vpc_cidr" { default = "10.10.0.0/16" }
variable "public_subnets" { default = ["10.10.1.0/24","10.10.2.0/24"] }
variable "private_subnets" { default = ["10.10.101.0/24","10.10.102.0/24"] }
variable "monthly_budget_amount" { default = 200 }
variable "waf_rate_limit" { default = 1500 }
```

## Backend remoto & Flusso di Deploy
Lo stato Terraform è centralizzato in un bucket S3 (`tfstate-terraform-infrastructure-eu-west-1`) con locking su DynamoDB (`tf-lock-terraform-infrastructure`), creati tramite il modulo `bootstrap/`.

1. **Bootstrap (una tantum)**
  ```bash
  cd infra/terraform/bootstrap
  terraform init
  terraform apply
  ```
2. **Deploy ambiente**
  ```bash
  cd infra/terraform/<env>
  terraform init
  terraform plan
  terraform apply
  ```

Ripetere il comando per `dev`, `stage` e `prod` in base alle necessità.

## Miglioramenti Futuri
- Automatizzare il riavvio ECS (o deploy controllato) dopo rotazione secret.
- Adottare un AWS Config Conformance Pack allineato allo standard CIS.
- Collegare il report del drill RDS a pipeline CI/CD con pubblicazione automatica.

## Note Sicurezza
- Il ruolo OIDC GitHub limita `iam:PassRole` ai ruoli specificati.
- Secrets non sono in chiaro nei task; ECS recupera gli ARNs in runtime.

---
## Differenze Ambiente
| Ambiente | Scaling ECS (desired/min/max) | Backup RDS | Budget USD | Rate Limit |
|----------|------------------------------|-----------|------------|------------|
| dev | 2 / 2 / 4 | 7 giorni + replica cross-region | 200 | 1500 |
| stage | 2 / 2 / 6 | 7 giorni | 600 | 1200 |
| prod | 3 / 3 / 10 | 14 giorni | 2500 | 1000 |
README generato automaticamente.
