param(
    [switch]$SkipBackend,
    [switch]$SkipMobile,
    [switch]$NoInstall
)

$ErrorActionPreference = 'Stop'

function Invoke-Step {
    param(
        [string]$Title,
        [scriptblock]$Action
    )

    Write-Host "`n==== $Title ==== " -ForegroundColor Cyan
    & $Action
    Write-Host "==== $Title completed ==== " -ForegroundColor Green
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendPath = Join-Path $repoRoot 'phase1\services\bff'
$mobilePath = Join-Path $repoRoot 'phase1\apps\mobile'

if (-not $SkipBackend) {
    Invoke-Step -Title 'Phase1 Backend (BFF) tests' -Action {
        Push-Location $backendPath
        try {
            if (-not $NoInstall) {
                if (Test-Path 'node_modules') {
                    Write-Host 'Running npm install (dependencies already present)...'
                    npm install --no-audit --prefer-offline
                } else {
                    Write-Host 'Running npm ci (fresh install)...'
                    npm ci
                }
            }
            Write-Host 'Running npm test...'
            npm test
        }
        finally {
            Pop-Location
        }
    }
} else {
    Write-Host 'Skipping backend tests.' -ForegroundColor Yellow
}

if (-not $SkipMobile) {
    Invoke-Step -Title 'Phase1 Mobile Flutter tests' -Action {
        Push-Location $mobilePath
        try {
            if (-not $NoInstall) {
                Write-Host 'Running flutter pub get...'
                flutter pub get
            }
            Write-Host 'Running flutter test...'
            flutter test
        }
        finally {
            Pop-Location
        }
    }
} else {
    Write-Host 'Skipping mobile tests.' -ForegroundColor Yellow
}

Write-Host 'Phase1 test suite completed.' -ForegroundColor Green
