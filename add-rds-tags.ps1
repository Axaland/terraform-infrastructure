# Script veloce per aggiungere tag Backup alle istanze RDS
# Uso: .\add-rds-tags.ps1

param(
    [string]$TerraformPath = "C:\Tools\Terraform\terraform.exe",
    [string]$ProjectRoot = "."
)

Write-Host "=== Aggiunta Tag RDS per Backup ===" -ForegroundColor Green

# Patch del modulo rds_postgres per aggiungere tag
$rdsMainFile = "$ProjectRoot/infra/terraform/modules/rds_postgres/main.tf"

if (Test-Path $rdsMainFile) {
    $content = Get-Content $rdsMainFile -Raw
    
    # Controlla se i tag sono già presenti
    if ($content -notmatch "tags\s*=\s*{") {
        Write-Host "Aggiungendo tag al modulo RDS..." -ForegroundColor Yellow
        
        # Trova la riga "deletion_protection     = false" e aggiungi tag dopo
        $updatedContent = $content -replace "(deletion_protection\s*=\s*false)", "`$1`n  tags = {`n    Environment = var.env`n    Backup      = `"true`"`n  }"
        
        Set-Content $rdsMainFile $updatedContent -NoNewline
        Write-Host "Tag aggiunti al modulo RDS." -ForegroundColor Green
    } else {
        Write-Host "Tag già presenti nel modulo RDS." -ForegroundColor Yellow
    }
} else {
    Write-Host "File modulo RDS non trovato: $rdsMainFile" -ForegroundColor Red
}

Write-Host "`nDopo questa modifica, esegui 'terraform plan' e 'terraform apply' per ogni ambiente per applicare i tag." -ForegroundColor Cyan