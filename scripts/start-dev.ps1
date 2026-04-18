param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Write-Host "[start-dev] Repo root: $repoRoot"
Write-Host "[start-dev] Starting Flutter app (Firebase mode)..."

Set-Location $repoRoot
flutter pub get
flutter run

