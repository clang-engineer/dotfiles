# Link Neovim config via Junction

. "$PSScriptRoot\..\lib\context.ps1"
. "$PSScriptRoot\..\lib\common.ps1"

$NvimFlavor = if ($script:NvimFlavor) { $script:NvimFlavor } else { "lazy" }

Write-Host "==> Linking Neovim config ($NvimFlavor)" -ForegroundColor Cyan

$SourceConfig = Join-Path $NvimDir $NvimFlavor
$NvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"

$result = New-Junction -Source $SourceConfig -Dest $NvimConfigPath
if (-not $result) { exit 1 }

Write-Host "Neovim config linked successfully." -ForegroundColor Green
