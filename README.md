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
- /infra/terraform/bootstrap/ - Backend S3/DynamoDB
- /infra/terraform/modules/ - Moduli riutilizzabili  
- /infra/terraform/dev/ - Ambiente sviluppo
- /minimal-dev/ - Configurazione OIDC deployata

Deploy completato: 10/07/2025 23:07:48
