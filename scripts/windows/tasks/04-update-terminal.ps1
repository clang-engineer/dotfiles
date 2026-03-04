# Update Windows Terminal settings (best effort)

. "$PSScriptRoot\..\lib\context.ps1"

$FontName = if ($script:FontName) { $script:FontName } else { "CascadiaCode-NF" }

Write-Host "==> Updating Windows Terminal settings" -ForegroundColor Cyan

$TerminalSettingsCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
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
