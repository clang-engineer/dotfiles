# Ensure Scoop is installed and buckets are configured

. "$PSScriptRoot\..\lib\context.ps1"

Write-Host "==> Ensuring Scoop" -ForegroundColor Cyan

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Scoop not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    irm get.scoop.sh | iex
}

$Buckets = @("main", "extras", "versions", "nerd-fonts")

foreach ($b in $Buckets) {
    if (-not (scoop bucket list | Select-String -SimpleMatch $b)) {
        scoop bucket add $b | Out-Null
    }
}

Write-Host "Scoop ready." -ForegroundColor Green
