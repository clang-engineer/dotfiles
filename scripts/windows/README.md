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

Notes:
- Assumes dotfiles are at `C:\Users\<you>\dotfiles`
- Installs lazygit and Windows-native CLI tools via Scoop
- Packages are read from `scripts\windows\scoop-packages.txt` (one per line, curated for a Unix-like CLI feel)
- Updates Windows Terminal defaults (font face, acrylic, opacity) when settings are found
