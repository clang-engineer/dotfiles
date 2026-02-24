# Windows Scripts

## Neovim only

Run in PowerShell:

```powershell
scripts\windows\setup-nvim.ps1
```

If your dotfiles live somewhere else, edit `$SourceConfig` inside the script.

## Windows native setup (Scoop)

Run in PowerShell:

```powershell
scripts\windows\setup.ps1
```

Options:

```powershell
scripts\windows\setup.ps1 -NvimFlavor classic
scripts\windows\setup.ps1 -Force
scripts\windows\setup.ps1 -FontName CascadiaCode-NF
```

## Claude Code

```powershell
# ~/.claude/settings.json에 아래 설정 추가
# "statusLine": {
#   "type": "command",
#   "command": "pwsh -File C:\\Users\\<you>\\.claude\\statusline-command.ps1"
# }

# 또는 직접 복사
Copy-Item scripts\windows\statusline-command.ps1 ~\.claude\statusline-command.ps1
```

Notes:
- Assumes dotfiles are at `C:\Users\<you>\dotfiles`
- Installs lazygit and Windows-native CLI tools via Scoop
- Packages are read from `scripts\windows\scoop-packages.txt` (one per line, curated for a Unix-like CLI feel)
- Updates Windows Terminal defaults (font face, acrylic, opacity) when settings are found
