# Install Nerd Font via Scoop

param(
    [string]$FontName = "CascadiaCode-NF",
    [switch]$Force
)

if ($FontName) {
    Write-Host "==> Installing Nerd Font: $FontName" -ForegroundColor Cyan
    if ($Force) {
        scoop install $FontName --force
    } else {
        scoop install $FontName
    }
}
