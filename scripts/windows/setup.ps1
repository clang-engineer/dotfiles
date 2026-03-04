# Windows setup orchestrator (Scoop)
# Usage: setup.ps1 [-Force] [-NvimFlavor lazy|classic] [-FontName CascadiaCode-NF]

param(
    [switch]$Force,
    [ValidateSet("lazy","classic")]
    [string]$NvimFlavor = "lazy",
    [string]$FontName = "CascadiaCode-NF"
)

$ErrorActionPreference = "Stop"

# Share parameters with tasks via script-scope variables
$script:Force      = $Force
$script:NvimFlavor = $NvimFlavor
$script:FontName   = $FontName

. "$PSScriptRoot\lib\context.ps1"

Write-Host "==> Windows setup (Scoop)" -ForegroundColor Cyan

$TasksDir = Join-Path $ScriptsDir "tasks"

function Run-Task {
    param([string]$TaskFile)
    $TaskPath = Join-Path $TasksDir $TaskFile
    if (Test-Path $TaskPath) {
        Write-Host ""
        . $TaskPath
    } else {
        Write-Host "Missing task: $TaskPath" -ForegroundColor Yellow
    }
}

Run-Task "01-ensure-scoop.ps1"
Run-Task "02-install-packages.ps1"
Run-Task "03-install-font.ps1"
Run-Task "04-update-terminal.ps1"
Run-Task "05-link-nvim.ps1"

Write-Host ""
Write-Host "==> Done" -ForegroundColor Green
Write-Host "Open a new PowerShell/Terminal and run: nvim" -ForegroundColor Green
