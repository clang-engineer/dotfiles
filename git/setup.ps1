# Link git/.gitconfig → ~/.gitconfig (existing file is backed up by New-FileLink).
$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$Source = Join-Path $RepoDir "git\.gitconfig"
$Dest = Join-Path $env:USERPROFILE ".gitconfig"

Link-Path -Source $Source -Dest $Dest | Out-Null
