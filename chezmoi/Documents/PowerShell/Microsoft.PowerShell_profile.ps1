# PowerShell Profile (Windows PowerShell 5.1)
# Linked to: $HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

# ──────────────────────────────────────────────────────────────────
# Encoding (UTF-8) — for both console and redirects
# ──────────────────────────────────────────────────────────────────
chcp 65001 > $null
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Remove the Windows curl alias → use the real curl.exe
Remove-Item Alias:curl -ErrorAction SilentlyContinue

# Force scoop shims to the front of PATH
$shim = "$env:USERPROFILE\scoop\shims"
if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $shim })) {
    $env:PATH = "$shim;$env:PATH"
}

# ──────────────────────────────────────────────────────────────────
# Prompt — starship
# ──────────────────────────────────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ──────────────────────────────────────────────────────────────────
# Directory jump — zoxide (z / zi)
# ──────────────────────────────────────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init powershell | Out-String | Invoke-Expression
}

# ──────────────────────────────────────────────────────────────────
# Completion / history — PSReadLine
#   Interactive sessions only (avoid polluting non-interactive child process stderr)
# ──────────────────────────────────────────────────────────────────
if (-not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected) {
    # Force-load a newer version instead of the 2.0.0 bundled with 5.1 (for predictive input)
    Import-Module PSReadLine -MinimumVersion 2.2.0 -Force -ErrorAction SilentlyContinue
    if ((Get-Module PSReadLine).Version -ge [version]'2.2.0') {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}

# ──────────────────────────────────────────────────────────────────
# fzf integration — PSFzf
#   Ctrl+T file select, Ctrl+R history
# ──────────────────────────────────────────────────────────────────
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    if (-not (Get-Module -ListAvailable PSFzf)) {
        try {
            Install-Module -Name PSFzf -Scope CurrentUser -Force -ErrorAction Stop
        } catch {
            Write-Warning "PSFzf install failed: $_"
        }
    }
    if (Get-Module -ListAvailable PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }

    # FZF default command (uses fd)
    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
        $env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
        $env:FZF_ALT_C_COMMAND   = 'fd --type d'
    }
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border'
}

# ──────────────────────────────────────────────────────────────────
# Modern CLI aliases — only if the tool is installed
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
# Suggest similar command candidates on a typo (PS 5.1 has no "Did you mean?")
#   Search for similar names among PATH executables + cmdlets/functions/aliases
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
# Secrets (tokens, credentials) — local-only file
# ──────────────────────────────────────────────────────────────────
if (Test-Path "$HOME\.secrets.ps1") { . "$HOME\.secrets.ps1" }
