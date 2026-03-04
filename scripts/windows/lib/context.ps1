# Path variables used across all setup scripts

$script:RepoDir    = (Resolve-Path "$PSScriptRoot\..\..\.." -ErrorAction Stop).Path
$script:ScriptsDir = Join-Path $RepoDir "scripts\windows"
$script:HomeSourceDir = Join-Path $RepoDir "home"
$script:NvimDir    = Join-Path $RepoDir "nvim"
