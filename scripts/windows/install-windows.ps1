# Windows installs that chezmoi does not handle (packages, Nerd Font, terminal).
# Linking is now done by chezmoi: run `chezmoi apply` first, then this script.
# UNTESTED after the chezmoi migration — verify on a real Windows machine.
param([switch]$Force)

$ErrorActionPreference = "Stop"

Write-Host "==> Windows installs" -ForegroundColor Cyan

# packages (includes Nerd Font) — reads packages/scoop-packages.txt
& "$PSScriptRoot\install-packages.ps1" -Force:$Force

# terminal (apply Nerd Font)
& "$PSScriptRoot\opt\update-terminal.ps1"

Write-Host ""
Write-Host "==> Done. Open a new terminal and run: nvim" -ForegroundColor Green
Write-Host "Manual: Node (nvm install lts), Java (jenv add <jdk>)" -ForegroundColor Yellow
