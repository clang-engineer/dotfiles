# Link PowerShell profile
$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$ProfileSource = Join-Path $RepoDir "home\Microsoft.PowerShell_profile.ps1"
$ProfileDest = Join-Path $env:USERPROFILE "Microsoft.PowerShell_profile.ps1"
Link-Path -Source $ProfileSource -Dest $ProfileDest
