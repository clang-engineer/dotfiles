# Windows setup orchestrator
param([switch]$Force)

$ErrorActionPreference = "Stop"
$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path

Write-Host "==> Windows setup" -ForegroundColor Cyan

# -- linking --
# Note: zsh/, tmux/, git/ 모듈은 Unix 전용이므로 여기서는 호출하지 않음
& "$RepoDir\home\setup.ps1"
& "$RepoDir\nvim\setup.ps1"
& "$RepoDir\ssh\setup.ps1"
& "$RepoDir\claude\setup.ps1"

Write-Host ""
Write-Host "==> Done" -ForegroundColor Green
Write-Host "Open a new PowerShell/Terminal and run: nvim" -ForegroundColor Green
