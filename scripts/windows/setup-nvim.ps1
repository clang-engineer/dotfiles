# Windows Neovim setup using Junction
# Usage: Run in PowerShell

$SourceConfig = "C:\Users\$env:USERNAME\dotfiles\nvim\lazy"
$NvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"

Write-Host "Source: $SourceConfig" -ForegroundColor Cyan
Write-Host "Target: $NvimConfigPath" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SourceConfig)) {
    Write-Error "Neovim config not found: $SourceConfig"
    exit 1
}

if (Test-Path $NvimConfigPath) {
    $Item = Get-Item $NvimConfigPath

    if ($Item.LinkType -eq "Junction" -or $Item.LinkType -eq "SymbolicLink") {
        Write-Host "Removing existing link..." -ForegroundColor Yellow
        Remove-Item $NvimConfigPath -Force
    }
    else {
        $BackupPath = "$NvimConfigPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "Backing up existing config to: $BackupPath" -ForegroundColor Yellow
        Move-Item $NvimConfigPath $BackupPath -Force
    }
}

Write-Host "Creating Junction..." -ForegroundColor Green
$result = cmd /c mklink /J "$NvimConfigPath" "$SourceConfig" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Neovim config linked successfully." -ForegroundColor Green
    Get-Item $NvimConfigPath | Select-Object FullName, LinkType, Target
} else {
    Write-Error "Failed to create Junction: $result"
    exit 1
}
