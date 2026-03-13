# Link PowerShell profile
$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
$ProfileSource = Join-Path $RepoDir "home\Microsoft.PowerShell_profile.ps1"
$ProfileDest = Join-Path $env:USERPROFILE "Microsoft.PowerShell_profile.ps1"
Copy-Item $ProfileSource $ProfileDest -Force
Write-Host "Linked PowerShell profile" -ForegroundColor Green
