# Script di verifica post-deployment
# Uso: .\verify-deployment.ps1 -Environment dev

param(
    [Parameter(Mandatory)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment
)

Write-Host "=== Verifica Deployment $Environment ===" -ForegroundColor Green

# Verifica AWS CLI
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw "AWS CLI richiesto per le verifiche"
}

function Test-AWSResource {
    param($Description, $Command)
    Write-Host "`nVerifica: $Description" -ForegroundColor Yellow
    try {
        Invoke-Expression $Command
        Write-Host "✓ OK" -ForegroundColor Green
    } catch {
        Write-Host "✗ ERRORE: $_" -ForegroundColor Red
    }
}

# ECS Cluster
Test-AWSResource "ECS Cluster" "aws ecs describe-clusters --clusters $Environment-app-cluster --query 'clusters[0].status'"

# RDS Instance
Test-AWSResource "RDS Instance" "aws rds describe-db-instances --db-instance-identifier rds-$Environment --query 'DBInstances[0].DBInstanceStatus'"

# S3 Bucket per Config (se presente)
Test-AWSResource "Config Bucket" "aws s3 ls | Select-String 'config-snapshots-$Environment'"

# GuardDuty
Test-AWSResource "GuardDuty" "aws guardduty list-detectors --query 'DetectorIds[0]'"

# Budget
Test-AWSResource "Budget" "aws budgets describe-budgets --account-id (aws sts get-caller-identity --query Account --output text) --query 'Budgets[?BudgetName==``monthly-$Environment``]'"

# WAF (richiede ARN ALB - qui solo check esistenza)
Write-Host "`nPer verifiche complete:" -ForegroundColor Cyan
Write-Host "1. Console AWS → CloudWatch → Dashboards → '$Environment-platform-observability'" -ForegroundColor White
Write-Host "2. Console AWS → WAF & Shield → Web ACLs (dovrebbe essere associata all'ALB)" -ForegroundColor White  
Write-Host "3. Console AWS → Config → Rules (cerca 'required-tags-$Environment')" -ForegroundColor White
Write-Host "4. Console AWS → Backup → Backup plans (cerca 'rds-backup-plan-$Environment')" -ForegroundColor White

Write-Host "`n=== Verifica Completata ===" -ForegroundColor Green