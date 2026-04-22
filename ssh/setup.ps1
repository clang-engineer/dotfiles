$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$Source = Join-Path $RepoDir "ssh"
$Dest = Join-Path $env:USERPROFILE ".ssh"

if (Test-Path $Dest) {
    $Item = Get-Item $Dest -Force
    if ($Item.LinkType -eq "Junction" -or $Item.LinkType -eq "SymbolicLink") {
        Write-Warning "$Dest is a legacy whole-dir junction. Remove it manually, then rerun to migrate to per-file links."
        exit 1
    }
} else {
    New-Item -ItemType Directory -Path $Dest | Out-Null
}

foreach ($f in @("config", "github_actions", "github_actions.pub")) {
    $srcFile = Join-Path $Source $f
    $destFile = Join-Path $Dest $f
    if (-not (Test-Path $srcFile)) { continue }
    New-FileLink -Source $srcFile -Dest $destFile | Out-Null
}

$SrcConfigD = Join-Path $Source "config.d"
$DestConfigD = Join-Path $Dest "config.d"
if (Test-Path $SrcConfigD) {
    if (-not (Test-Path $DestConfigD)) {
        New-Item -ItemType Directory -Path $DestConfigD | Out-Null
    }
    foreach ($file in Get-ChildItem -Path $SrcConfigD -File) {
        if ($file.Name -like "*.example") { continue }
        New-FileLink -Source $file.FullName -Dest (Join-Path $DestConfigD $file.Name) | Out-Null
    }
}
