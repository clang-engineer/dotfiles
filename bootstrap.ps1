# Windows setup orchestrator
param([switch]$Force)

$ErrorActionPreference = "Stop"
$RepoDir = $PSScriptRoot

Write-Host "==> Windows setup" -ForegroundColor Cyan

# -- packages (Nerd Font 포함) --
& "$RepoDir\packages\install-packages.ps1" -Force:$Force

# -- linking --
# Note: zsh/, tmux/ 모듈은 Unix 전용이므로 여기서는 호출하지 않음
& "$RepoDir\home\setup.ps1"
& "$RepoDir\nvim\setup.ps1"
& "$RepoDir\ssh\setup.ps1"
& "$RepoDir\git\setup.ps1"
& "$RepoDir\claude\setup.ps1"

# -- terminal (Nerd Font 적용) --
& "$RepoDir\scripts\windows\opt\update-terminal.ps1"

Write-Host ""
Write-Host "==> Done" -ForegroundColor Green
Write-Host "Open a new PowerShell/Terminal and run: nvim" -ForegroundColor Green
