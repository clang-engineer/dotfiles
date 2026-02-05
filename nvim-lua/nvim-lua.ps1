# Create .nvim.lua link in current directory (Windows version)

$SourceFile = "$env:USERPROFILE\dotfiles\nvim-lua\windows.lua"
$TargetFile = Join-Path (Get-Location) ".nvim.lua"

if (-not (Test-Path $SourceFile)) {
    Write-Error "Source not found: $SourceFile"
    exit 1
}

if (Test-Path $TargetFile) {
    Remove-Item $TargetFile -Force
}

cmd /c mklink /H "$TargetFile" "$SourceFile" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Created: $TargetFile" -ForegroundColor Green
} else {
    Write-Error "Failed to create link"
    exit 1
}
