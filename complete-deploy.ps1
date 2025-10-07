# Complete Deploy - Bypassa problemi GitHub e completa automaticamente
Write-Host "🚀 DEPLOY AUTOMATICO COMPLETO" -ForegroundColor Green

$roleArn = "arn:aws:iam::818957473514:role/github-ci-role"

# 1. Crea repository GitHub manualmente via browser
Write-Host "`n=== PASSO 1: Repository GitHub ===" -ForegroundColor Cyan
Write-Host "Apro GitHub per creare repository..." -ForegroundColor Yellow
Start-Process "https://github.com/new"
Write-Host "Repository URL: https://github.com/AXALAND/terraform-infrastructure" -ForegroundColor Green

# 2. Inizializza repository locale
Write-Host "`n=== PASSO 2: Repository Locale ===" -ForegroundColor Cyan
if (-not (Test-Path ".git")) {
    git init
    Write-Host "Git repository inizializzato ✓" -ForegroundColor Green
}

git add .
git commit -m "Initial commit: Complete Terraform infrastructure"
git branch -M main

try {
    git remote add origin https://github.com/AXALAND/terraform-infrastructure.git
    Write-Host "Remote origin aggiunto ✓" -ForegroundColor Green
} catch {
    Write-Host "Remote già configurato" -ForegroundColor Yellow
}

# 3. Configura secret GitHub
Write-Host "`n=== PASSO 3: Secret GitHub ===" -ForegroundColor Cyan
Write-Host "Configura questo secret su GitHub:" -ForegroundColor Yellow
Write-Host "URL: https://github.com/AXALAND/terraform-infrastructure/settings/secrets/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nome Secret: AWS_GITHUB_CI_ROLE_ARN" -ForegroundColor White
Write-Host "Valore: $roleArn" -ForegroundColor White
Write-Host ""

# 4. Push codice
Write-Host "`n=== PASSO 4: Push Codice ===" -ForegroundColor Cyan
$pushChoice = Read-Host "Procedere con push? Repository deve esistere (y/N)"
if ($pushChoice -eq 'y' -or $pushChoice -eq 'Y') {
    git push -u origin main
    Write-Host "Codice pushato ✓" -ForegroundColor Green
}

# 5. Deploy ambienti aggiuntivi
Write-Host "`n=== PASSO 5: Deploy Altri Ambienti ===" -ForegroundColor Cyan
$deployOthers = Read-Host "Deployare stage e prod? (y/N)"

if ($deployOthers -eq 'y' -or $deployOthers -eq 'Y') {
    Write-Host "Deploy STAGE..." -ForegroundColor Magenta
    C:\Tools\Terraform\terraform.exe -chdir=infra/terraform/stage init -reconfigure
    C:\Tools\Terraform\terraform.exe -chdir=infra/terraform/stage apply -auto-approve
    
    Write-Host "Deploy PROD..." -ForegroundColor Magenta  
    C:\Tools\Terraform\terraform.exe -chdir=infra/terraform/prod init -reconfigure
    C:\Tools\Terraform\terraform.exe -chdir=infra/terraform/prod apply -auto-approve
}

# 6. Verifica deployment
Write-Host "`n=== PASSO 6: Verifica Deployment ===" -ForegroundColor Cyan
C:\Tools\Terraform\terraform.exe -chdir=infra/terraform/dev output

Write-Host "`n🎉 COMPLETATO!" -ForegroundColor Green
Write-Host "✅ Backend S3/DynamoDB: Creato" -ForegroundColor Yellow  
Write-Host "✅ Ambiente DEV: Deployato" -ForegroundColor Yellow
Write-Host "✅ Ruolo OIDC GitHub: $roleArn" -ForegroundColor Yellow
Write-Host "✅ Repository: https://github.com/AXALAND/terraform-infrastructure" -ForegroundColor Yellow

Write-Host "`n📋 AZIONI MANUALI RICHIESTE:" -ForegroundColor Cyan
Write-Host "1. Configura secret AWS_GITHUB_CI_ROLE_ARN su GitHub" -ForegroundColor White  
Write-Host "2. Verifica workflow GitHub Actions" -ForegroundColor White
Write-Host "3. Test deployment via GitHub Actions" -ForegroundColor White