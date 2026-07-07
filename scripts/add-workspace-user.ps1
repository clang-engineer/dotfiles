# Register a workspace-scoped Git user (name/email) via [includeIf "gitdir:..."]
# in ~/.gitconfig.local, so repos under that path use a different identity.
param(
    [string]$WorkspacePath,
    [string]$GitName,
    [string]$GitEmail
)

$ErrorActionPreference = "Stop"

if (-not $WorkspacePath) { $WorkspacePath = Read-Host "Enter workspace path (e.g. C:\Users\me\workspace\company)" }
if (-not $GitName)       { $GitName       = Read-Host "Enter Git display name" }
if (-not $GitEmail)      { $GitEmail      = Read-Host "Enter Git email" }

# Normalize path: expand ~, resolve to absolute, use forward slashes (Git config style).
if ($WorkspacePath.StartsWith("~")) {
    $WorkspacePath = Join-Path $env:USERPROFILE $WorkspacePath.Substring(1).TrimStart('\','/')
}
$WorkspacePath = $WorkspacePath -replace '\\', '/'

$ConfigFile = "$WorkspacePath/.gitconfig.inc"
$GitConfig  = (Join-Path $env:USERPROFILE ".gitconfig.local") -replace '\\', '/'

Write-Host ""
Write-Host "Configuration:"
Write-Host "  Workspace:   $WorkspacePath"
Write-Host "  Git name:    $GitName"
Write-Host "  Git email:   $GitEmail"
Write-Host "  Config file: $ConfigFile"
Write-Host "  Target:      $GitConfig"
Write-Host ""

if (-not (Test-Path $WorkspacePath)) {
    New-Item -ItemType Directory -Path $WorkspacePath -Force | Out-Null
    Write-Host "Created workspace directory: $WorkspacePath"
}

@"
[user]
    name = $GitName
    email = $GitEmail
"@ | Out-File -FilePath $ConfigFile -Encoding utf8

Write-Host "Created Git config file: $ConfigFile"

if (-not (Test-Path $GitConfig)) {
    New-Item -ItemType File -Path $GitConfig -Force | Out-Null
}

# `gitdir/i:` for case-insensitive matching on Windows.
$Marker = "gitdir/i:$WorkspacePath/"
if (Select-String -Path $GitConfig -Pattern ([regex]::Escape($Marker)) -Quiet) {
    Write-Host "includeIf entry already exists in $GitConfig"
} else {
    @"

[includeIf "$Marker"]
    path = $ConfigFile
"@ | Add-Content -Path $GitConfig -Encoding utf8
    Write-Host "Added includeIf entry to $GitConfig"
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "Any Git repository under $WorkspacePath/ will use:"
Write-Host "  name  = $GitName"
Write-Host "  email = $GitEmail"
