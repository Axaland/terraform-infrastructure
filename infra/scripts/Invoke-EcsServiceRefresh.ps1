param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment,

    [string]$ServiceName = "app",
    [string]$Region = "eu-west-1",
    [string]$AwsProfile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$clusterName = "{0}-{1}-cluster" -f $Environment, $ServiceName

$awsArgs = @("ecs", "update-service", "--cluster", $clusterName, "--service", $ServiceName, "--force-new-deployment")
if ($AwsProfile) { $awsArgs += @("--profile", $AwsProfile) }
if ($Region) { $awsArgs += @("--region", $Region) }

Write-Host "Triggering new deployment for ECS service '$ServiceName' on cluster '$clusterName'" -ForegroundColor Cyan
$process = Start-Process -FilePath "aws" -ArgumentList $awsArgs -NoNewWindow -PassThru -Wait -RedirectStandardOutput output.txt -RedirectStandardError error.txt

$stdout = Get-Content output.txt | Out-String
$stderr = Get-Content error.txt | Out-String
Remove-Item output.txt, error.txt -ErrorAction SilentlyContinue

if ($process.ExitCode -ne 0) {
    throw "aws ecs update-service failed: $stderr"
}

Write-Host "Deployment triggered successfully" -ForegroundColor Green
Write-Output $stdout
