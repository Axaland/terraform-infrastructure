param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment,

    [string]$Region = "eu-west-1",
    [string]$ReplicaRegion = "eu-central-1",
    [string]$ReplicaBackupVaultName,
    [string]$DbSubnetGroupName,

    [Parameter(Mandatory = $true)]
    [string]$SecurityGroupIds,

    [string]$RestoreSubnetIds,
    [string]$DbInstanceClass = "db.t4g.small",
    [string]$IamRoleArn,
    [switch]$KeepInstance,
    [string]$AwsProfile,
    [string]$TestQuery,
    [string]$TestUser,
    [string]$TestDatabase,
    [string]$TestSecretArn
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-AwsCli {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$RegionOverride
    )

    $processArgs = @()
    if ($AwsProfile) {
        $processArgs += @("--profile", $AwsProfile)
    }
    if ($RegionOverride) {
        $processArgs += @("--region", $RegionOverride)
    }
    $processArgs += $Arguments

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "aws"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.Arguments = $processArgs -join ' '

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        throw "AWS CLI command failed: $stderr"
    }

    return $stdout
}

if (-not $ReplicaBackupVaultName) {
    $ReplicaBackupVaultName = "rds-backup-$Environment-replica"
}

if (-not $DbSubnetGroupName) {
    $DbSubnetGroupName = "rds-$Environment-subnets"
}

if (-not $IamRoleArn) {
    $accountId = Invoke-AwsCli -Arguments @("sts", "get-caller-identity", "--query", "Account", "--output", "text") -RegionOverride $ReplicaRegion
    $IamRoleArn = "arn:aws:iam::$(($accountId.Trim())):role/aws-service-role/backup.amazonaws.com/AWSServiceRoleForBackup"
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$restoreIdentifier = "rds-$Environment-drill-$timestamp"
$drillDir = Join-Path -Path (Join-Path $PSScriptRoot "..\..\drills") -ChildPath $Environment
New-Item -ItemType Directory -Force -Path $drillDir | Out-Null

Write-Host "[1/6] Looking up latest recovery point in vault '$ReplicaBackupVaultName' ($ReplicaRegion)" -ForegroundColor Cyan
$recoveryJson = Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
    "backup", "list-recovery-points-by-backup-vault",
    "--backup-vault-name", $ReplicaBackupVaultName,
    "--by-resource-type", "RDS",
    "--query", "recoveryPoints[?Status=='COMPLETED'] | sort_by(@, &CreationDate)[-1]",
    "--output", "json"
)

if (-not $recoveryJson -or $recoveryJson -eq "null") {
    throw "Nessun recovery point COMPLETED trovato nella vault $ReplicaBackupVaultName"
}

$recoveryPoint = $recoveryJson | ConvertFrom-Json
$metadataFile = Join-Path $drillDir "$($restoreIdentifier)-recovery-point.json"
$recoveryJson | Out-File -FilePath $metadataFile -Encoding utf8
Write-Host "Recovery point ARN: $($recoveryPoint.RecoveryPointArn)" -ForegroundColor Green

if (-not $RestoreSubnetIds) {
    Write-Host "[WARN] RestoreSubnetIds non fornito. Verrà usato il DB subnet group '$DbSubnetGroupName'." -ForegroundColor Yellow
} else {
    Write-Host "[2/6] Ensuring temporary DB subnet group exists" -ForegroundColor Cyan
    $subnetGroupName = "$($Environment)-drill-subnets"
    $existingGroup = $null
    try {
        $existingGroup = Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
            "rds", "describe-db-subnet-groups",
            "--db-subnet-group-name", $subnetGroupName,
            "--query", "DBSubnetGroups[0].DBSubnetGroupName",
            "--output", "text"
        )
    } catch {
        $existingGroup = $null
    }

    if (-not $existingGroup -or $existingGroup.Trim() -eq "None") {
        Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
            "rds", "create-db-subnet-group",
            "--db-subnet-group-name", $subnetGroupName,
            "--db-subnet-group-description", "Drill subnet group",
            "--subnet-ids", $RestoreSubnetIds
        ) | Out-Null
        Write-Host "Creato DB subnet group $subnetGroupName" -ForegroundColor Green
    } else {
        Write-Host "Riutilizzo DB subnet group $subnetGroupName" -ForegroundColor Green
    }
    $DbSubnetGroupName = $subnetGroupName
}

Write-Host "[3/6] Avvio restore job" -ForegroundColor Cyan
$metadata = @{
    "DBInstanceIdentifier" = $restoreIdentifier
    "DBSubnetGroupName"     = $DbSubnetGroupName
    "DBInstanceClass"       = $DbInstanceClass
    "VpcSecurityGroupIds"   = $SecurityGroupIds
    "Engine"                = "postgres"
    "MultiAZ"               = "false"
    "PubliclyAccessible"    = "false"
}

$metadataArgs = @()
foreach ($kv in $metadata.GetEnumerator()) {
    $metadataArgs += @("--metadata", "{0}={1}" -f $kv.Key, $kv.Value)
}
$restoreArgs = @(
    "backup", "start-restore-job",
    "--iam-role-arn", $IamRoleArn,
    "--recovery-point-arn", $recoveryPoint.RecoveryPointArn,
    "--resource-type", "RDS",
    "--idempotency-token", $restoreIdentifier
) + $metadataArgs

$restoreJobJson = Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments $restoreArgs
$restoreJob = $restoreJobJson | ConvertFrom-Json
Write-Host "Restore job avviato: $($restoreJob.RestoreJobId)" -ForegroundColor Green

Write-Host "[4/6] Attesa completamento restore job" -ForegroundColor Cyan
while ($true) {
    Start-Sleep -Seconds 30
    $statusJson = Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
        "backup", "describe-restore-job",
        "--restore-job-id", $restoreJob.RestoreJobId,
        "--output", "json"
    )
    $status = $statusJson | ConvertFrom-Json
    Write-Host "Status: $($status.Status)" -ForegroundColor Gray
    if ($status.Status -eq "COMPLETED") { break }
    if ($status.Status -eq "FAILED" -or $status.Status -eq "ABORTED") {
        throw "Restore job fallito: $($status.StatusMessage)"
    }
}

Write-Host "[5/6] Verifica disponibilità istanza RDS ($restoreIdentifier)" -ForegroundColor Cyan
while ($true) {
    Start-Sleep -Seconds 20
    $dbJson = Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
        "rds", "describe-db-instances",
        "--db-instance-identifier", $restoreIdentifier,
        "--query", "DBInstances[0].DBInstanceStatus",
        "--output", "text"
    )
    if ($dbJson -eq "available") {
        break
    }
    Write-Host "Stato attuale: $dbJson" -ForegroundColor Gray
}

Write-Host "Istanza di drill pronta: $restoreIdentifier" -ForegroundColor Green

function Invoke-TestQuery {
    param(
        [string]$Endpoint,
        [string]$Database,
        [string]$Username,
        [System.Security.SecureString]$Password,
        [string]$Query
    )

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    try {
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    $env:PGPASSWORD = $plainPassword
    $psqlArgs = @("-h", $Endpoint, "-U", $Username, "-d", $Database, "-t", "-A", "-c", $Query)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "psql"
    $psi.Arguments = ($psqlArgs -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $output = $process.StandardOutput.ReadToEnd()
    $errorOutput = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

    if ($process.ExitCode -ne 0) {
        throw "psql failed: $errorOutput"
    }

    return $output.Trim()
}

$testResult = $null
if ($TestQuery -and $TestUser -and $TestDatabase -and $TestSecretArn) {
    Write-Host "[6/7] Esecuzione query di smoke test" -ForegroundColor Cyan
    $secretJson = Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
        "secretsmanager", "get-secret-value",
        "--secret-id", $TestSecretArn,
        "--query", "SecretString",
        "--output", "text"
    )
    $secretObj = $secretJson | ConvertFrom-Json
    $passwordSecure = ConvertTo-SecureString -String $secretObj.password -AsPlainText -Force
    $endpoint = Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
        "rds", "describe-db-instances",
        "--db-instance-identifier", $restoreIdentifier,
        "--query", "DBInstances[0].Endpoint.Address",
        "--output", "text"
    )
    try {
    $testOutput = Invoke-TestQuery -Endpoint $endpoint -Database $TestDatabase -Username $TestUser -Password $passwordSecure -Query $TestQuery
        $testResult = @{ status = "success"; output = $testOutput }
        Write-Host "Smoke test completato con successo" -ForegroundColor Green
    } catch {
        $testResult = @{ status = "failure"; error = $_.Exception.Message }
        Write-Warning "Smoke test fallito: $($_.Exception.Message)"
    }
} elseif ($TestQuery -or $TestUser -or $TestDatabase -or $TestSecretArn) {
    Write-Warning "Parametri smoke test incompleti: fornire TestQuery, TestUser, TestDatabase e TestSecretArn per eseguire il controllo."
}

if (-not $KeepInstance) {
    Write-Host "[7/7] Pulizia automatica (eliminazione istanza di drill)" -ForegroundColor Cyan
    Invoke-AwsCli -RegionOverride $ReplicaRegion -Arguments @(
        "rds", "delete-db-instance",
        "--db-instance-identifier", $restoreIdentifier,
        "--skip-final-snapshot"
    ) | Out-Null
    Write-Host "Eliminazione avviata. Controlla lo stato finché non diventa 'deleted'." -ForegroundColor Yellow
}

[PSCustomObject]@{
    Environment        = $Environment
    RecoveryPointArn   = $recoveryPoint.RecoveryPointArn
    RestoreJobId       = $restoreJob.RestoreJobId
    DrillInstanceId    = $restoreIdentifier
    ReplicaRegion      = $ReplicaRegion
    CleanupScheduled   = (-not $KeepInstance)
    SmokeTest          = $testResult
} | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $drillDir "${restoreIdentifier}-summary.json") -Encoding utf8

Write-Host "Drill completato. Dettagli salvati in $drillDir" -ForegroundColor Green
