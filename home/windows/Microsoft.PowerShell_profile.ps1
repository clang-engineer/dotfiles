# PowerShell Profile
# Link to: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

# Load secrets (tokens, credentials) from a local-only file
if (Test-Path "$HOME\.secrets.ps1") { . "$HOME\.secrets.ps1" }
