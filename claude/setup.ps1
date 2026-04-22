$RepoDir = (Resolve-Path "$PSScriptRoot\..").Path
. "$RepoDir\scripts\lib\common.ps1"

$Source = Join-Path $RepoDir "claude"
$Dest = Join-Path $env:USERPROFILE ".claude"

if (Test-Path $Dest) {
    $Item = Get-Item $Dest -Force
    if ($Item.LinkType -eq "Junction" -or $Item.LinkType -eq "SymbolicLink") {
        Write-Warning "$Dest is a legacy whole-dir junction. Remove it manually, then rerun to migrate to per-file links."
        exit 1
    }
} else {
    New-Item -ItemType Directory -Path $Dest | Out-Null
}

foreach ($item in @("CLAUDE.md", "settings.json", "commands", "hooks")) {
    $src = Join-Path $Source $item
    $dst = Join-Path $Dest $item
    if (-not (Test-Path $src)) { continue }
    Link-Path -Source $src -Dest $dst | Out-Null
}
