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
| iam_github_oidc | Ruolo IAM federato GitHub Actions | ci_role_arn |
| security_baseline | GuardDuty + AWS Config + bucket snapshot | guardduty_detector_id, config_bucket_name |

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

## WAF e Rate Limiting
Il modulo `waf_alb` applica regole gestite AWS + una regola rate-based configurabile tramite `waf_rate_limit` (richieste / 5 minuti per IP).

## Budget
Il modulo `budgets` crea un budget mensile con due notifiche: 80% ACTUAL, 100% FORECASTED.

## Security Baseline
Abilita GuardDuty e AWS Config:
- Bucket cifrato + versioning per snapshot.
- Recorder + delivery channel.
- Detector GuardDuty con S3 logs.

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

## Flusso di Deploy Locale
1. `cd infra/terraform/dev`
2. `terraform init`
3. `terraform plan`
4. `terraform apply`

Ripetere per `stage` e `prod` con attenzione ai parametri (in futuro backend remoto consigliato: S3 + DynamoDB).

## Miglioramenti Futuri
- Backend remoto Terraform (S3 + DynamoDB state locking)
- Aggiunta CloudWatch dashboard e allarmi
- Integrazione AWS Backup per RDS
- Tag governance e regole AWS Config addizionali (es: required-tags)

## Note Sicurezza
- Il ruolo OIDC GitHub limita `iam:PassRole` ai ruoli specificati.
- Secrets non sono in chiaro nei task; ECS recupera gli ARNs in runtime.

---
README generato automaticamente.
