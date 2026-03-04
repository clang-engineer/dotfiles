# Install packages from scoop-packages.txt

. "$PSScriptRoot\..\lib\context.ps1"

$Force = $script:Force -eq $true

Write-Host "==> Installing packages" -ForegroundColor Cyan

$PackagesFile = Join-Path $ScriptsDir "scoop-packages.txt"
$Packages = @()

if (Test-Path $PackagesFile) {
    $Packages = Get-Content $PackagesFile | Where-Object { $_ -and -not $_.StartsWith("#") }
} else {
    $Packages = @(
        "git", "neovim", "ripgrep", "fd", "fzf",
        "lazygit", "nodejs", "python", "llvm",
        "make", "7zip", "curl"
    )
}

foreach ($pkg in $Packages) {
    if ($Force) {
        scoop install $pkg --force
    } else {
        scoop install $pkg
    }
}
