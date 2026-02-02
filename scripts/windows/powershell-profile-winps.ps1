# zoxide (autojump 대체)
zoxide init powershell | Out-String | Invoke-Expression


# PSReadLine 자동완성 강화
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# UTF-8 기본 설정
chcp 65001 > $null
$OutputEncoding = [System.Text.Encoding]::UTF8

[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

Remove-Item Alias:curl -ErrorAction SilentlyContinue
$OutputEncoding = [System.Text.Encoding]::UTF8


# scoop shims 강제 등록
$shim = "$env:USERPROFILE\scoop\shims"
if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $shim })) {
    $env:PATH = "$shim;$env:PATH"
}

chcp 65001
$OutputEncoding = [System.Text.Encoding]::UTF8

