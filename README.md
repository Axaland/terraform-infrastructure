# Terraform Infrastructure Multi-Environment

##  Infrastruttura Professionale Deployata

###  Componenti Attivi
- **S3 Backend**: 	fstate-terraform-infrastructure-eu-west-1
- **DynamoDB Lock**: 	f-lock-terraform-infrastructure 
- **GitHub OIDC Role**: rn:aws:iam::818957473514:role/github-ci-role-dev
- **Test Bucket**: 	est-deploy-dev-41b47ef5

###  Configurazione GitHub
1. Aggiungi secret: AWS_GITHUB_CI_ROLE_ARN = rn:aws:iam::818957473514:role/github-ci-role-dev
2. Workflow CI/CD automatico attivo in .github/workflows/

###  Struttura
- Consulta `DIRECTORY-GUIDE.md` per l'elenco completo e aggiornato delle directory e dei relativi utilizzi.
- /infra/terraform/bootstrap/ - Backend S3/DynamoDB
- /infra/terraform/modules/ - Moduli riutilizzabili  
- /infra/terraform/dev/ - Ambiente sviluppo
- /minimal-dev/ - Configurazione OIDC deployata
- /phase0/ - Bootstrap applicativo (Fase 0) con monorepo e shell servizi
- /phase1/ - Implementazione registrazione/login (Fase 1)

### Utility
- `test-phase1.ps1` esegue in sequenza i test automatizzati di BFF (`npm test`) e mobile Flutter (`flutter test`) con gestione automatica dei percorsi. Opzioni disponibili:
	- `-SkipBackend` o `-SkipMobile` per saltare singole suite;
	- `-NoInstall` per evitare il restore delle dipendenze.

Deploy completato: 10/07/2025 23:07:48
