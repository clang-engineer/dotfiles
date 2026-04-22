$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$VimFlavor = "lazy"
$Source = Join-Path $RepoDir "nvim\$VimFlavor"
$Dest = Join-Path $env:LOCALAPPDATA "nvim"
New-Junction -Source $Source -Dest $Dest

# exrc
$ExrcSource = Join-Path $RepoDir "nvim\exrc\exrc-windows.lua"
$ExrcDest = Join-Path $env:USERPROFILE ".exrc.lua"
New-FileLink -Source $ExrcSource -Dest $ExrcDest | Out-Null
