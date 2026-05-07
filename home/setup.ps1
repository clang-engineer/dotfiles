# Link PowerShell profile to Windows PowerShell 5.1's $PROFILE location
$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$ProfileSource = Join-Path $RepoDir "home\Microsoft.PowerShell_profile.ps1"
$ProfileDir    = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell"
$ProfileDest   = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"

if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

Link-Path -Source $ProfileSource -Dest $ProfileDest
