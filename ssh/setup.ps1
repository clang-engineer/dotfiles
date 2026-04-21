$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$Source = Join-Path $RepoDir "ssh"
$Dest = Join-Path $env:USERPROFILE ".ssh"
New-Junction -Source $Source -Dest $Dest
