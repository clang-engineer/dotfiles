# Windows package and runtime setup.
# Invoked automatically by `chezmoi apply`; it can also be run standalone.
# UNTESTED after the chezmoi migration — verify on a real Windows machine.
param([switch]$Force)

$ErrorActionPreference = "Stop"

Write-Host "==> Windows installs" -ForegroundColor Cyan

# packages (includes Nerd Font) — reads packages/scoop-packages.txt
& "$PSScriptRoot\install-packages.ps1" -Force:$Force

$Mise = Join-Path $env:USERPROFILE "scoop\shims\mise.exe"
if (Test-Path $Mise) {
    $MiseDataDir = (Join-Path $env:LOCALAPPDATA "mise") -replace '\\', '/'
    $MiseShims = "$MiseDataDir/shims"
    $env:MISE_DATA_DIR = $MiseDataDir
    [Environment]::SetEnvironmentVariable("MISE_DATA_DIR", $MiseDataDir, "User")
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (($UserPath -split ';') -notcontains $MiseShims) {
        $NewUserPath = if ($UserPath) { "$MiseShims;$UserPath" } else { $MiseShims }
        [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
    }
    $env:PATH = "$MiseShims;$env:PATH"
    & $Mise install
    if ($LASTEXITCODE -ne 0) { throw "mise runtime installation failed" }
}

$Pwsh = Join-Path $env:USERPROFILE "scoop\shims\pwsh.exe"
if (Test-Path $Pwsh) {
    & $Pwsh -NoProfile -Command "if (-not (Get-Module -ListAvailable PSFzf)) { Install-Module -Name PSFzf -Scope CurrentUser -Force -ErrorAction Stop }"
    if ($LASTEXITCODE -ne 0) { throw "PSFzf installation failed" }
}

Write-Host ""
Write-Host "==> Done. Open a new terminal and run: nvim" -ForegroundColor Green
