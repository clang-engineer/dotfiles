# Windows setup orchestrator
# Usage: setup.ps1 [-Force] [-NvimFlavor lazy|classic] [-FontName CascadiaCode-NF]

param(
    [switch]$Force,
    [ValidateSet("lazy","classic")]
    [string]$NvimFlavor = "lazy",
    [string]$FontName = "CascadiaCode-NF"
)

$ErrorActionPreference = "Stop"
$env:VIM_FLAVOR = $NvimFlavor

$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path

Write-Host "==> Windows setup" -ForegroundColor Cyan

# -- linking --
& "$RepoDir\home\setup.ps1"
& "$RepoDir\nvim\setup.ps1"

# -- install --
& "$RepoDir\scripts\windows\install-scoop.ps1"
& "$RepoDir\scripts\windows\install-packages.ps1" -Force:$Force
& "$RepoDir\scripts\windows\install-font.ps1" -FontName $FontName -Force:$Force
& "$RepoDir\scripts\windows\update-terminal.ps1" -FontName $FontName

Write-Host ""
Write-Host "==> Done" -ForegroundColor Green
Write-Host "Open a new PowerShell/Terminal and run: nvim" -ForegroundColor Green
