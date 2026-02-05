# Link .nvim.lua to current directory
# Usage: link-nvim.ps1 [target-directory]

param(
    [string]$TargetDir = (Get-Location).Path
)

$SourceFile = "$env:USERPROFILE\dotfiles\.nvim.lua"
$TargetFile = Join-Path $TargetDir ".nvim.lua"

if (-not (Test-Path $SourceFile)) {
    Write-Error "Source file not found: $SourceFile"
    exit 1
}

if (Test-Path $TargetFile) {
    Write-Host "Removing existing .nvim.lua..." -ForegroundColor Yellow
    Remove-Item $TargetFile -Force
}

# Try symbolic link first (requires admin), fallback to hard link
try {
    New-Item -ItemType SymbolicLink -Path $TargetFile -Target $SourceFile -ErrorAction Stop | Out-Null
    Write-Host "Symbolic link created: $TargetFile -> $SourceFile" -ForegroundColor Green
} catch {
    cmd /c mklink /H "$TargetFile" "$SourceFile" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Hard link created: $TargetFile -> $SourceFile" -ForegroundColor Green
    } else {
        Write-Error "Failed to create link. Try running as Administrator."
        exit 1
    }
}
