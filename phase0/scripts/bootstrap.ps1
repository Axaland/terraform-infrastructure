param(
    [switch]$InstallFlutter,
    [switch]$InstallGo,
    [switch]$InstallNode
)

Write-Host "[APP XXX] Bootstrap Fase 0" -ForegroundColor Cyan

if ($InstallNode) {
    Write-Host "- Installare manualmente Node.js 20+ e pnpm 9+" -ForegroundColor Yellow
}

if ($InstallFlutter) {
    Write-Host "- Installare Flutter 3.24+ e aggiungere il canale stable" -ForegroundColor Yellow
}

if ($InstallGo) {
    Write-Host "- Installare Go 1.22+" -ForegroundColor Yellow
}

Write-Host "- Eseguo pnpm install sulle workspace registrate" -ForegroundColor Green
pnpm install --recursive

Write-Host "- Ricordo: avviare il BFF con 'pnpm --filter bff dev'" -ForegroundColor Green
Write-Host "         avviare il servizio Go con 'go run ./cmd/server'" -ForegroundColor Green
Write-Host "         avviare Flutter con 'flutter run'" -ForegroundColor Green
