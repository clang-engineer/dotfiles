# Install packages from scoop-packages.txt
# Usage: .\install-packages.ps1 [-Force]
#   -Force: reinstall already-installed packages

param([switch]$Force)

Write-Host "==> Installing packages" -ForegroundColor Cyan

# Ensure scoop is installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Scoop not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    irm get.scoop.sh | iex
}

# Add buckets required by packages (e.g. extras for windows-terminal, nerd-fonts for fonts)
$Buckets = @("main", "extras", "versions", "nerd-fonts")
foreach ($b in $Buckets) {
    if (-not (scoop bucket list | Select-String -SimpleMatch $b)) {
        scoop bucket add $b | Out-Null
    }
}

$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$PackagesFile = Join-Path $RepoRoot "packages/scoop-packages.txt"
if (-not (Test-Path $PackagesFile)) {
    Write-Host "ERROR: $PackagesFile not found" -ForegroundColor Red
    exit 1
}
# Read package list, skipping blank lines and comments (#)
$Packages = Get-Content $PackagesFile | Where-Object { $_ -and -not $_.StartsWith("#") }

foreach ($pkg in $Packages) {
    if ($Force) {
        scoop install $pkg --force
    } else {
        scoop install $pkg
    }
}
