# Session Log – 08/10/2025

## Aggiornamenti 19/10/2025 – Rotazione credenziali AWS
- Creato nuovo access key pair IAM (`AKIA35LNLK3VI337KQN2`) per l'utente `AXALAND-1` tramite console con caso d'uso *Interfaccia a riga di comando (CLI)*.
- Aggiornati i file locali `C:\Users\axala\.aws\credentials` e `C:\Users\axala\.aws\config`; verificato l'accesso con `aws sts get-caller-identity --no-cli-pager`.
- Confermato che in IAM non risultano altre chiavi attive per l'utente (rotazione completata, nessuna chiave legacy da dismettere).
- Verificati i segreti GitHub Actions: il repository usa esclusivamente l'ARN di ruolo OIDC (`AWS_GITHUB_CI_ROLE_ARN`), quindi non è necessario salvare la nuova chiave.
- Prossimi passi: monitorare le pipeline CI al prossimo run e programmare la prossima rotazione entro 90 giorni.

## Aggiornamenti 24/10/2025 – Fix trust policy GitHub Actions
- Individuato errore `sts:AssumeRoleWithWebIdentity` nei workflow dovuto al cambio di casing dell'organizzazione GitHub (`Axaland`).
- Aggiornato `minimal-dev/main.tf` per allineare il subject OIDC a `repo:Axaland/terraform-infrastructure:*` e committato su `master` (`4edb8fe`).
- Concesso permessi IAM ad `AXALAND-1` e modificata manualmente la trust policy del ruolo `github-ci-role-dev` nella console IAM con il nuovo subject.
- Verificata l'assenza di ruoli stage/prod analoghi; nessuna ulteriore modifica necessaria.
- Rilanciato il workflow Terraform CI/CD su GitHub Actions: esecuzione completata con successo dopo l'aggiornamento.

## Contesto operativo
- **Data/Ora locale**: 08/10/2025 11:56 CEST
- **Root progetto**: `C:\Users\axala\OneDrive\Desktop\Backup_Infrastruttura_2025-10-05_18-09\new`
- **Binario Terraform**: `C:\Tools\Terraform\terraform.exe`
- **Backend remoto**:
  - S3 bucket: `tfstate-terraform-infrastructure-eu-west-1`
  - DynamoDB table: `tf-lock-terraform-infrastructure`
- **Account AWS**: `818957473514`
- **Regione primaria**: `eu-west-1`
- **Variabili d'ambiente AWS**: nessuna variabile `AWS_PROFILE`, `AWS_DEFAULT_REGION` o `AWS_REGION` impostata nella sessione corrente.

## Operazioni Terraform
- Comandi eseguiti:
  1. `terraform init`
  2. `terraform plan`
  3. `terraform apply -auto-approve`
- Esito apply: **SUCCESSO** – 23 risorse create, 0 modificate, 0 distrutte.
- `terraform output`: nessun output definito nello stato corrente.
- Stato file locali: modulo `infra/terraform/prod` senza `terraform.tfstate` locale (state gestito via backend remoto).

## Inventario risorse chiave (post-apply)
- **VPC produzione**: `vpc-038d6a4449d057471` (`10.30.0.0/16`) – stato `available`.
  - Subnet pubbliche: `subnet-0bcd0cdbf89647ab3` (eu-west-1a), `subnet-047a7d73c33c9da26` (eu-west-1b).
  - Subnet private: `subnet-013fde28c07cdd5ed` (eu-west-1a), `subnet-0741aa1b90e2f98b4` (eu-west-1b).
  - Internet Gateway: `igw-0866194de4657a61b`.
- **Application Load Balancer**: `prod-alb`
  - ARN: `arn:aws:elasticloadbalancing:eu-west-1:818957473514:loadbalancer/app/prod-alb/3b4d5809d8bce1ca`
  - DNS: `prod-alb-56043609.eu-west-1.elb.amazonaws.com`
  - Security group: `sg-0f3cbf2f35a69ac37`.
- **Target Group**: `arn:aws:elasticloadbalancing:eu-west-1:818957473514:targetgroup/tg-prod-app/61efb992e15f5cb5` (port 3000, tipo `ip`).
- **ECS Cluster**: `prod-app-cluster`.
  - Servizio `app`: desired count 3, running count 0, pending 0, rollout `IN_PROGRESS`.
  - Task definition: `arn:aws:ecs:eu-west-1:818957473514:task-definition/prod-app:1`.
  - Eventi recenti indicano errori `ResourceInitializationError` durante il recupero del secret `arn:aws:secretsmanager:eu-west-1:818957473514:secret:rds-prod-credentials-ShXtv6` (timeout rete). Necessaria diagnostica su connettività Secrets Manager/VPC (NACL, security group, route).
  - Fallimenti registrati: 2 task.
- **RDS PostgreSQL**: `rds-prod`
  - Classe `db.t4g.micro`, engine `postgres 15.14`, stato `available`.
  - Endpoint: `rds-prod.creasagywbh6.eu-west-1.rds.amazonaws.com:5432`.
  - Subnet group: `rds-prod-subnets` (subnet private eu-west-1a/b).
  - Security group RDS: `sg-0c935a055c56e8a6b` (ingresso `10.30.0.0/16` porta 5432).
  - KMS key: `arn:aws:kms:eu-west-1:818957473514:key/7323551f-40e9-4ef4-b433-ac66c6506110`.
- **Backup**: vault `rds-backup-prod` + piano `756cd038-45ba-455e-a721-669246b588c5`.
- **WAF ACL**: `prod-web-acl` associata all'ALB.
- **Secrets Manager**: secret `rds-prod-credentials` aggiornato da Terraform; verificare accesso dalle task ECS.

## Backup creati
- Archivio: `backups\terraform-infrastructure-20251008-115407.zip`
  - Percorso assoluto: `C:\Users\axala\OneDrive\Desktop\Backup_Infrastruttura_2025-10-05_18-09\new\backups\terraform-infrastructure-20251008-115407.zip`
  - Dimensione: ~505 MB (506.4 MB raw)
  - Contenuto: intero repository al momento della compressione (cartella `backups` esclusa dall'input per evitare ricorsione; l'archivio finale va comunque eseguito fuori dal percorso di origine prima di un restore).
- Istruzioni per restore:
  1. Estrarre l'archivio in una nuova directory.
  2. Ripristinare eventuali file sensibili non inclusi (es. credenziali locali).
  3. Reimpostare backend e variabili AWS secondo `DEPLOYMENT-GUIDE.md`.

## Cronologia comandi rilevanti (PowerShell)
| #  | Comando |
|----|---------|
|197 | `& 'C:\Tools\Terraform\terraform.exe' plan` |
|198 | `& 'C:\Tools\Terraform\terraform.exe' apply -auto-approve` |
|199 | `& 'C:\Tools\Terraform\terraform.exe' output` |
|200 | `& 'C:\Tools\Terraform\terraform.exe' output` |
|201 | `aws ec2 describe-vpcs --filters Name=tag:Name,Values=prod-vpc --region eu-west-1` |
|202 | `aws rds describe-db-instances --db-instance-identifier rds-prod --region eu-west-1` |
|203 | `aws elbv2 describe-load-balancers --names prod-alb --region eu-west-1` |
|204 | `aws elbv2 describe-load-balancers --names prod-alb --region eu-west-1` |
|205 | `aws ecs describe-services --cluster prod-app-cluster --services app --region eu-west-1` |
|206 | `aws ecs describe-services --cluster prod-app-cluster --services app --region eu-west-1` |
|207 | `aws ecs list-services --cluster prod-app-cluster --region eu-west-1` |
|208 | `aws ecs describe-services --cluster prod-app-cluster --services app --region eu-west-1` |
|209 | `Set-Location ...\new` |
|210 | `Set-Location ...\new` |
|211 | `if (-not (Test-Path .\backups)) { New-Item -ItemType Directory -Path .\backups | Out-Null }` |
|212 | `$timestamp = Get-Date ... Compress-Archive ...` (prima esecuzione, completata parzialmente) |
|213 | `Remove-Item .\backups\terraform-infrastructure-20251008-115147.zip -ErrorAction SilentlyContinue` |
|214 | `$timestamp = Get-Date ... Compress-Archive ...` (backup riuscito) |
|215 | `Get-ChildItem .\backups | Sort-Object ...` |
|216 | `Get-ChildItem Env:AWS_PROFILE,Env:AWS_DEFAULT_REGION,Env:AWS_REGION | Format-Table` |

## Attività pendenti / note per prossima sessione
1. **ECS Task failures**: indagare la mancata reachability verso Secrets Manager (controllare route table private, NAT gateway, endpoint VPC per Secrets Manager o configurare assegnazione IP pubblico/endpoint privato).
2. **Outputs Terraform**: valutare l'aggiunta di output utili (es. ALB DNS, RDS endpoint, security group IDs) per consultazioni future.
3. **Verifica applicativa**: una volta risolta la connettività, eseguire `verify-deployment.ps1` o test end-to-end.
4. **Documentazione**: mantenere aggiornati `DEPLOYMENT-GUIDE.md` e `DEPLOYMENT-SUMMARY.md` con gli sviluppi futuri.

---
_Log creato automaticamente per facilitare la ricostruzione dello stato nella prossima sessione._
