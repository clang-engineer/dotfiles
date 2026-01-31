# Windows native setup using Scoop (no WSL)
# Usage: Run in PowerShell

param(
    [switch]$Force,
    [ValidateSet("lazy","classic")]
    [string]$NvimFlavor = "lazy",
    [string]$FontName = "CascadiaCode-NF"
)

$ErrorActionPreference = "Stop"

Write-Host "==> Windows setup (Scoop)" -ForegroundColor Cyan

# Ensure Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Scoop not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    irm get.scoop.sh | iex
}

# Buckets
$Buckets = @(
    "main",
    "extras",
    "versions",
    "nerd-fonts"
)

foreach ($b in $Buckets) {
    if (-not (scoop bucket list | Select-String -SimpleMatch $b)) {
        scoop bucket add $b | Out-Null
    }
}

# Core packages (Windows native equivalents)
$PackagesFile = Join-Path $PSScriptRoot "scoop-packages.txt"
$Packages = @()
if (Test-Path $PackagesFile) {
    $Packages = Get-Content $PackagesFile | Where-Object { $_ -and -not $_.StartsWith("#") }
} else {
    $Packages = @(
        "git",
        "neovim",
        "ripgrep",
        "fd",
        "fzf",
        "lazygit",
        "nodejs",
        "python",
        "llvm",
        "make",
        "7zip",
        "curl"
    )
}

Write-Host "==> Installing packages" -ForegroundColor Cyan
foreach ($pkg in $Packages) {
    if ($Force) {
        scoop install $pkg --force
    } else {
        scoop install $pkg
    }
}

# Nerd font (Windows Terminal)
if ($FontName) {
    Write-Host "==> Installing Nerd Font: $FontName" -ForegroundColor Cyan
    if ($Force) {
        scoop install $FontName --force
    } else {
        scoop install $FontName
    }
}

# Windows Terminal settings update (best effort)
Write-Host "==> Updating Windows Terminal settings" -ForegroundColor Cyan
$TerminalSettingsCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\\Windows Terminal\\settings.json")
)

$TerminalSettingsPath = $TerminalSettingsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($TerminalSettingsPath) {
    $settingsRaw = Get-Content $TerminalSettingsPath -Raw
    $settings = $settingsRaw | ConvertFrom-Json

    if (-not $settings.defaults) {
        $settings | Add-Member -MemberType NoteProperty -Name defaults -Value ([pscustomobject]@{})
    }

    if ($FontName) {
        if (-not $settings.defaults.font) {
            $settings.defaults | Add-Member -MemberType NoteProperty -Name font -Value ([pscustomobject]@{})
        }
        $settings.defaults.font.face = $FontName
    }

    $settings.defaults.useAcrylic = $true
    $settings.defaults.opacity = 85

    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $TerminalSettingsPath -Encoding UTF8
    Write-Host "Updated Windows Terminal defaults: $TerminalSettingsPath" -ForegroundColor Green
} else {
    Write-Host "Windows Terminal settings.json not found; skipped." -ForegroundColor Yellow
}

# Link Neovim config
Write-Host "==> Linking Neovim config ($NvimFlavor)" -ForegroundColor Cyan
$SourceConfig = "C:\Users\$env:USERNAME\dotfiles\configs\nvim-$NvimFlavor"
$NvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"

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

Write-Host "==> Done" -ForegroundColor Green
Write-Host "Open a new PowerShell/Terminal and run: nvim" -ForegroundColor Green
