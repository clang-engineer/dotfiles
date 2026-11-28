# Windows package and runtime setup.
# Invoked automatically by `chezmoi apply`; it can also be run standalone.
# UNTESTED after the chezmoi migration — verify on a real Windows machine.
param([switch]$Force)

$ErrorActionPreference = "Stop"

Write-Host "==> Windows installs" -ForegroundColor Cyan

# packages (includes Nerd Font) — reads packages/scoop-packages.txt
& "$PSScriptRoot\install-packages.ps1" -Force:$Force

# Resolve Scoop's actual installation root, including custom locations.
$ScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE "scoop" }
function Resolve-RequiredTool([string]$Name) {
    $Tool = Get-Command "$Name.exe" -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($Tool) { return $Tool.Source }
    $Shim = Join-Path $ScoopRoot "shims\$Name.exe"
    if (Test-Path -LiteralPath $Shim -PathType Leaf) { return $Shim }
    throw "Required tool not found after Scoop installation: $Name"
}

$Mise = Resolve-RequiredTool "mise"
$MiseDataDir = (Join-Path $env:LOCALAPPDATA "mise") -replace '\\', '/'
$MiseShims = "$MiseDataDir/shims"
$env:MISE_DATA_DIR = $MiseDataDir
[Environment]::SetEnvironmentVariable("MISE_DATA_DIR", $MiseDataDir, "User")
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$NormalizedShims = $MiseShims -replace '\\', '/'
$NormalizedPath = @($UserPath -split ';' | ForEach-Object { ($_ -replace '\\', '/').TrimEnd('/') })
if ($NormalizedPath -notcontains $NormalizedShims) {
    $NewUserPath = if ($UserPath) { "$MiseShims;$UserPath" } else { $MiseShims }
    [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
}
$env:PATH = "$MiseShims;$env:PATH"
& $Mise install
if ($LASTEXITCODE -ne 0) { throw "mise runtime installation failed" }

$Pwsh = Resolve-RequiredTool "pwsh"
& $Pwsh -NoProfile -Command "if (-not (Get-Module -ListAvailable PSFzf)) { Install-Module -Name PSFzf -Scope CurrentUser -Force -ErrorAction Stop }"
if ($LASTEXITCODE -ne 0) { throw "PSFzf installation failed" }

Write-Host ""
Write-Host "==> Done. Open a new terminal and run: nvim" -ForegroundColor Green
