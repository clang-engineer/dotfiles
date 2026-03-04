# Install Nerd Font via Scoop

. "$PSScriptRoot\..\lib\context.ps1"

$FontName = if ($script:FontName) { $script:FontName } else { "CascadiaCode-NF" }
$Force = $script:Force -eq $true

if ($FontName) {
    Write-Host "==> Installing Nerd Font: $FontName" -ForegroundColor Cyan
    if ($Force) {
        scoop install $FontName --force
    } else {
        scoop install $FontName
    }
}
