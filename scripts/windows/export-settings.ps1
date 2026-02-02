$ErrorActionPreference = "Stop"

Write-Host "==> Exporting Windows settings" -ForegroundColor Cyan

# Windows Terminal settings
$terminalCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
)

$terminalSource = $terminalCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($terminalSource) {
    $terminalDest = Join-Path $PSScriptRoot "windows-terminal-settings.json"
    Copy-Item -Path $terminalSource -Destination $terminalDest -Force
    Write-Host "Saved Windows Terminal settings to: $terminalDest" -ForegroundColor Green
} else {
    Write-Host "Windows Terminal settings.json not found; skipped." -ForegroundColor Yellow
}

# PowerShell profile (PowerShell 7+)
$psProfile = Join-Path $HOME "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $psProfile) {
    $psDest = Join-Path $PSScriptRoot "powershell-profile.ps1"
    Copy-Item -Path $psProfile -Destination $psDest -Force
    Write-Host "Saved PowerShell 7 profile to: $psDest" -ForegroundColor Green
} else {
    Write-Host "PowerShell 7 profile not found; skipped." -ForegroundColor Yellow
}

# Windows PowerShell profile (5.1)
$winPsProfile = Join-Path $HOME "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $winPsProfile) {
    $winPsDest = Join-Path $PSScriptRoot "powershell-profile-winps.ps1"
    Copy-Item -Path $winPsProfile -Destination $winPsDest -Force
    Write-Host "Saved Windows PowerShell profile to: $winPsDest" -ForegroundColor Green
} else {
    Write-Host "Windows PowerShell profile not found; skipped." -ForegroundColor Yellow
}

Write-Host "==> Done" -ForegroundColor Cyan
