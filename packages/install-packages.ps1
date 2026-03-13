# Install packages from scoop-packages.txt

param([switch]$Force)

Write-Host "==> Installing packages" -ForegroundColor Cyan

$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$PackagesFile = Join-Path $RepoRoot "packages/scoop-packages.txt"
if (-not (Test-Path $PackagesFile)) {
    Write-Host "ERROR: $PackagesFile not found" -ForegroundColor Red
    exit 1
}
$Packages = Get-Content $PackagesFile | Where-Object { $_ -and -not $_.StartsWith("#") }

foreach ($pkg in $Packages) {
    if ($Force) {
        scoop install $pkg --force
    } else {
        scoop install $pkg
    }
}
