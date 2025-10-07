# GitHub Setup Script - Completa configurazione
# Da eseguire dopo aver creato il repository GitHub

echo " GitHub Setup Automatico"

# 1. Crea repository (se non esiste)
gh repo create terraform-infrastructure --public --description "Enterprise Terraform Infrastructure"

# 2. Configura remote
git remote set-url origin https://github.com/AXALAND/terraform-infrastructure.git

# 3. Push codice  
git push -u origin master

# 4. Configura secret
gh secret set AWS_GITHUB_CI_ROLE_ARN --body "arn:aws:iam::818957473514:role/github-ci-role-dev"

echo " Setup GitHub completato!"
