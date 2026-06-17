$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$VimFlavor = "lazy"
$Source = Join-Path $RepoDir "nvim\$VimFlavor"
$Dest = Join-Path $env:LOCALAPPDATA "nvim"
New-Junction -Source $Source -Dest $Dest
