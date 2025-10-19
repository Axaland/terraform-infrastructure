# Infrastruttura — Fase 0

La Fase 0 riutilizza l'impianto Terraform del repository principale (`infra/terraform`). Questa cartella fornisce una vista semplificata dei moduli minimi necessari per il bootstrap degli ambienti.

## Componenti principali

- **VPC + networking**: modulo `modules/vpc`
- **PostgreSQL**: modulo `modules/rds_postgres`
- **Redis (placeholder)**: da introdurre nelle fasi successive (`modules/redis`)
- **ECS Fargate**: modulo `modules/ecs_fargate_service`
- **Budget/Monitoring**: `modules/budgets`, `modules/cloudwatch_dashboard`

## File di riferimento

- `../../infra/terraform/dev/main.tf` — Ambiente di sviluppo
- `../../infra/terraform/stage/main.tf` — Ambiente di stage
- `../../infra/terraform/prod/main.tf` — Ambiente di produzione

## Setup ambiente dev

```powershell
cd ..\..\infra\terraform\dev
terraform init
terraform plan
```

Valori sensibili (es. segreti JWT) vanno gestiti tramite AWS Secrets Manager e passati al servizio ECS.

## Prossimi passi

- Creare modulo `modules/redis`
- Collegare ECS service del BFF con secret `JWT_SECRET`
- Definire pipeline CD (GitHub Actions) per deploy automatico
