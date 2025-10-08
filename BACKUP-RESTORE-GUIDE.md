# Guida al backup e al ripristino

## Snapshot corrente
- **Data creazione backup**: 8 ottobre 2025, 14:10 UTC+02 (file `backups/terraform-infrastructure-20251008-141011.zip`)
- **Commit di riferimento**: `94344182657b44f8e4185f4c2e066bd93e75d919`
- **Stato repository**: numerose modifiche locali e file non tracciati (inclusi `.terraform.lock.hcl` per più ambienti e `SESSION-LOG-2025-10-08.md`).
- **Immagine Docker attualmente in produzione**: `818957473514.dkr.ecr.eu-west-1.amazonaws.com/app:2430acc-20251008` (task definition `prod-app:5`).
- **Servizio ECS**: `app` sul cluster `prod-app-cluster`, desired count 3, health check ALB su `/health` con ingress SG aggiornato.

## Contenuto dell'archivio
Il file zip contiene l'intera directory del progetto (script PowerShell, moduli Terraform per `prod`, `stage`, `dev`, cartella `minimal-dev`, documentazione, ecc.), ad eccezione della cartella `backups/` stessa per evitare ricorsioni. Tutti i file modificati e non tracciati risultano inclusi.

## Come ripristinare in una nuova sessione
1. **Estrarre l'archivio**
   ```powershell
   Expand-Archive -Path .\backups\terraform-infrastructure-20251008-141011.zip -DestinationPath C:\percorso\di\lavoro
   ```
2. **Preparare l'ambiente**
   - Configurare le credenziali AWS con permessi su ECR, ECS, ALB, RDS, Secrets Manager e sul backend Terraform.
   - Installare Docker (con Buildx abilitato), Terraform >= 1.5.x e Node.js 18 per eventuali rebuild dell'immagine.
3. **Rigenerare l'immagine applicativa (se serve)**
   ```powershell
   docker buildx build --platform linux/amd64 -t 818957473514.dkr.ecr.eu-west-1.amazonaws.com/app:2430acc-20251008 .
   docker push 818957473514.dkr.ecr.eu-west-1.amazonaws.com/app:2430acc-20251008
   ```
4. **Eseguire Terraform** (esempio ambiente production)
   ```powershell
   cd infra/terraform/prod
   terraform init
   terraform plan
   terraform apply
   ```
5. **Verifiche post-ripristino**
   - `aws ecs describe-services --cluster prod-app-cluster --services app`
   - `aws elbv2 describe-target-health --target-group-arn <target-group-arn>`
   - Consultare i log applicativi in CloudWatch (`/ecs/app/prod-app`).

## Note aggiuntive
- Nella cartella `backups/` restano disponibili anche `terraform-infrastructure-20251008-115407.zip` e `terraform-infrastructure-20251008-140722.zip` come snapshot precedenti.
- Aggiornare `DEPLOYMENT-SUMMARY.md` dopo eventuali nuovi cambiamenti infrastrutturali.
- Il ruolo `prod-app-exec-role` deve mantenere l'accesso al secret `arn:aws:secretsmanager:eu-west-1:818957473514:secret:rds-prod-credentials-ShXtv6`; verificare le policy se vengono introdotte modifiche IAM.
