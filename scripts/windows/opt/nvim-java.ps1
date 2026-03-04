# Create .nvim.lua for Java project in current directory
# Usage: nvim-java.ps1 [jdtls_version] [gradle_version]

param(
    [string]$Jdtls = "21",
    [string]$Gradle = "11"
)

$TargetFile = Join-Path (Get-Location) ".nvim.lua"

if ($Jdtls -eq "21" -and $Gradle -eq "11") {
    $Content = 'require("config.java-env").setup()'
} else {
    $Content = "require(`"config.java-env`").setup({ jdtls = `"$Jdtls`", gradle = `"$Gradle`" })"
}

Set-Content -Path $TargetFile -Value $Content -Encoding UTF8
Write-Host "Created: $TargetFile" -ForegroundColor Green
Write-Host "Content: $Content" -ForegroundColor Cyan
