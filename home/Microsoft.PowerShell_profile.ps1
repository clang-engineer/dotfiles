# PowerShell Profile (Windows PowerShell 5.1)
# Linked to: $HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

# ──────────────────────────────────────────────────────────────────
# Encoding (UTF-8) — 콘솔/리다이렉트 모두
# ──────────────────────────────────────────────────────────────────
chcp 65001 > $null
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Windows의 curl alias 제거 → 실제 curl.exe 사용
Remove-Item Alias:curl -ErrorAction SilentlyContinue

# scoop shims를 PATH 앞쪽에 강제 등록
$shim = "$env:USERPROFILE\scoop\shims"
if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $shim })) {
    $env:PATH = "$shim;$env:PATH"
}

# ──────────────────────────────────────────────────────────────────
# 프롬프트 — starship
# ──────────────────────────────────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ──────────────────────────────────────────────────────────────────
# 디렉터리 점프 — zoxide (z / zi)
# ──────────────────────────────────────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init powershell | Out-String | Invoke-Expression
}

# ──────────────────────────────────────────────────────────────────
# 자동완성 / 히스토리 — PSReadLine
#   대화형 세션에서만 (non-interactive 자식 프로세스 stderr 오염 방지)
# ──────────────────────────────────────────────────────────────────
if (-not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
}

# ──────────────────────────────────────────────────────────────────
# fzf 통합 — PSFzf
#   Ctrl+T 파일 선택, Ctrl+R 히스토리
# ──────────────────────────────────────────────────────────────────
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    if (-not (Get-Module -ListAvailable PSFzf)) {
        try {
            Install-Module -Name PSFzf -Scope CurrentUser -Force -ErrorAction Stop
        } catch {
            Write-Warning "PSFzf 설치 실패: $_"
        }
    }
    if (Get-Module -ListAvailable PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }

    # FZF 기본 명령 (fd 사용)
    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
        $env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
        $env:FZF_ALT_C_COMMAND   = 'fd --type d'
    }
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border'
}

# ──────────────────────────────────────────────────────────────────
# 모던 CLI alias — 도구가 설치된 경우만
# ──────────────────────────────────────────────────────────────────
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -ErrorAction SilentlyContinue
    Set-Alias -Name cat -Value bat -Option AllScope
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza -lh --git --group-directories-first --icons @args }
    function la { eza -lah --git --group-directories-first --icons @args }
    function lt { eza -T -L 2 --git-ignore --icons @args }
}

# ──────────────────────────────────────────────────────────────────
# 명령어 오타 시 유사 명령어 후보 제시 (PS 5.1엔 "Did you mean?" 없음)
#   PATH 내 실행파일 + cmdlet/함수/alias에서 유사한 이름 검색
# ──────────────────────────────────────────────────────────────────
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $EventArgs)
    $candidates = Get-Command "*$CommandName*" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Name -Unique |
        Select-Object -First 5
    if ($candidates) {
        Write-Host "Did you mean: $($candidates -join ', ')?" -ForegroundColor Yellow
    }
}

# ──────────────────────────────────────────────────────────────────
# Secrets (토큰, 자격증명) — 로컬 전용 파일
# ──────────────────────────────────────────────────────────────────
if (Test-Path "$HOME\.secrets.ps1") { . "$HOME\.secrets.ps1" }
