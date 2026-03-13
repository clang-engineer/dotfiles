# Windows setup orchestrator
param([switch]$Force)

$ErrorActionPreference = "Stop"
$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path

Write-Host "==> Windows setup" -ForegroundColor Cyan

# -- linking --
& "$RepoDir\home\setup.ps1"
& "$RepoDir\nvim\setup.ps1"

Write-Host ""
Write-Host "==> Done" -ForegroundColor Green
Write-Host "Open a new PowerShell/Terminal and run: nvim" -ForegroundColor Green
