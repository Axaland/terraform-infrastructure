# Terraform Infrastructure Deployment Script
# Prerequisiti: AWS CLI configurato, Terraform installato
# Uso: .\deploy-infrastructure.ps1

param(
    [string]$TerraformPath = "C:\Tools\Terraform\terraform.exe",
    [switch]$SkipBootstrap,
    [switch]$DevOnly,
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"

Write-Host "=== Terraform Infrastructure Deployment ===" -ForegroundColor Green
Write-Host "Terraform Path: $TerraformPath" -ForegroundColor Yellow
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Yellow

# Verifica prerequisiti
if (-not (Test-Path $TerraformPath)) {
    throw "Terraform non trovato in: $TerraformPath"
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw "AWS CLI non trovato. Esegui 'aws configure' prima di continuare."
}

# Test credenziali AWS
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "AWS Account: $($identity.Account) - User: $($identity.Arn)" -ForegroundColor Green
} catch {
    throw "Credenziali AWS non valide. Esegui 'aws configure' per impostarle."
}

# Funzione per eseguire Terraform
function Invoke-Terraform {
    param($WorkDir, $Command, $TerraformArgs = @())
    
    $fullPath = Join-Path $ProjectRoot $WorkDir
    if (-not (Test-Path $fullPath)) {
        throw "Directory non trovata: $fullPath"
    }
    
    Write-Host "`n--- Terraform $Command in $WorkDir ---" -ForegroundColor Cyan
    $argString = ($TerraformArgs -join " ")
    $cmd = "& '$TerraformPath' -chdir='$fullPath' $Command $argString"
    Write-Host "Eseguo: $cmd" -ForegroundColor Gray
    
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform $Command fallito in $WorkDir"
    }
}

# STEP 1: Bootstrap (se non saltato)
if (-not $SkipBootstrap) {
    Write-Host "`n=== STEP 1: Bootstrap Backend Remoto ===" -ForegroundColor Green
    Invoke-Terraform "infra/terraform/bootstrap" "init"
    Invoke-Terraform "infra/terraform/bootstrap" "apply" @("-auto-approve")
    
    # Ottieni outputs
    $outputs = & $TerraformPath -chdir="$ProjectRoot/infra/terraform/bootstrap" output -json | ConvertFrom-Json
    $bucket = $outputs.backend_bucket.value
    $table = $outputs.backend_dynamodb_table.value
    
    Write-Host "`nBootstrap completato:" -ForegroundColor Green
    Write-Host "Bucket: $bucket" -ForegroundColor Yellow
    Write-Host "DynamoDB Table: $table" -ForegroundColor Yellow
    
    # STEP 2: Sostituisci placeholders
    Write-Host "`n=== STEP 2: Aggiorna Backend Configurations ===" -ForegroundColor Green
    
    $environments = @("dev", "stage", "prod")
    foreach ($env in $environments) {
        $backendFile = "$ProjectRoot/infra/terraform/$env/backend.tf"
        if (Test-Path $backendFile) {
            $content = Get-Content $backendFile -Raw
            $content = $content -replace '<REPLACE_BUCKET>', $bucket
            $content = $content -replace '<REPLACE_DYNAMODB_TABLE>', $table
            Set-Content $backendFile $content -NoNewline
            Write-Host "Aggiornato: $backendFile" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Bootstrap saltato (flag -SkipBootstrap)" -ForegroundColor Yellow
}

# STEP 3: Deploy ambienti
Write-Host "`n=== STEP 3: Deploy Environments ===" -ForegroundColor Green

$environments = if ($DevOnly) { @("dev") } else { @("dev", "stage", "prod") }

foreach ($env in $environments) {
    Write-Host "`n--- Deploying $env ---" -ForegroundColor Magenta
    
    # Init con backend remoto
    Invoke-Terraform "infra/terraform/$env" "init" @("-reconfigure")
    
    # Plan per review
    Write-Host "Eseguo plan per $env..." -ForegroundColor Yellow
    Invoke-Terraform "infra/terraform/$env" "plan"
    
    # Conferma per apply
    $confirm = Read-Host "Continuare con apply per $env? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        Invoke-Terraform "infra/terraform/$env" "apply" @("-auto-approve")
        
        # Mostra outputs importanti
        Write-Host "`nOutputs principali per ${env}:" -ForegroundColor Green
        try {
            $envOutputs = & $TerraformPath -chdir="$ProjectRoot/infra/terraform/$env" output -json | ConvertFrom-Json
            if ($envOutputs.PSObject.Properties.Name -contains "ci_role_arn") {
                Write-Host "CI Role ARN: $($envOutputs.ci_role_arn.value)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Impossibile ottenere outputs (normale se non definiti)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Apply saltato per $env" -ForegroundColor Yellow
    }
}

# STEP 4: Post-deployment tasks
Write-Host "`n=== STEP 4: Post-Deployment Tasks ===" -ForegroundColor Green

Write-Host @"

TASKS MANUALI RIMANENTI:

1. GitHub Secret (se hai GitHub repo):
   - Vai su GitHub repo → Settings → Secrets → Actions
   - Crea secret: AWS_GITHUB_CI_ROLE_ARN
   - Valore: [CI Role ARN mostrato sopra]

2. Email Budget:
   - Controlla le email configurate per eventuali conferme SNS
   - Se necessario, abbassa temporaneamente threshold per testare

3. Tag RDS per Backup:
   - Le istanze RDS dovrebbero già avere tag 'Backup=true' 
   - Verifica in AWS Console → RDS → istanze

4. Verifiche:
   - CloudWatch Dashboard: $($environments -join ', ')
   - WAF Web ACLs associati agli ALB
   - Config rules attive
   - GuardDuty enabled

"@ -ForegroundColor Cyan

Write-Host "`n=== DEPLOYMENT COMPLETATO ===" -ForegroundColor Green
Write-Host "Consulta il README per dettagli sui moduli e configurazioni." -ForegroundColor Yellow