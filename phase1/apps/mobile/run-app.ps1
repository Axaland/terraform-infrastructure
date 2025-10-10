# Script per avviare l'app Flutter
Set-Location -Path $PSScriptRoot
Write-Host "Directory corrente: $(Get-Location)"
Write-Host "Avvio app Flutter su Edge (web)..."
flutter run -d edge --web-port=8080
