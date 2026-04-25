# Generate SSH key for GitHub account
param(
    [string]$Username,
    [string]$Email
)

$ErrorActionPreference = "Stop"

if (-not $Username) { $Username = Read-Host "Enter GitHub username" }
if (-not $Email)    { $Email    = Read-Host "Enter GitHub email" }

$KeyName = "id_rsa_github_$Username"
$KeyPath = Join-Path $env:USERPROFILE ".ssh\$KeyName"

Write-Host ""
Write-Host "Configuration:"
Write-Host "  Username: $Username"
Write-Host "  Email:    $Email"
Write-Host "  Key path: $KeyPath"
Write-Host ""

if (Test-Path $KeyPath) {
    Write-Host "Warning: SSH key already exists at $KeyPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? (y/N)"
    if ($overwrite -notmatch '^[Yy]$') {
        Write-Host "Using existing key"
        Get-Content "$KeyPath.pub"
        exit 0
    }
}

Write-Host "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -C $Email -f $KeyPath -N '""'

# ssh-agent service (Win32-OpenSSH)
$agent = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($agent) {
    if ($agent.StartType -eq 'Disabled') {
        Write-Host "ssh-agent service is disabled. Enable with (admin):" -ForegroundColor Yellow
        Write-Host "  Set-Service ssh-agent -StartupType Automatic" -ForegroundColor Yellow
    } else {
        if ($agent.Status -ne 'Running') { Start-Service ssh-agent }
        ssh-add $KeyPath
    }
} else {
    Write-Host "ssh-agent not found (install OpenSSH Client capability)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "SSH key generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Public key (add this to GitHub):"
Write-Host "========================================"
Get-Content "$KeyPath.pub"
Write-Host "========================================"
Write-Host ""
Write-Host "Add this key to: https://github.com/settings/keys"
