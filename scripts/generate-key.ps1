# Generate an SSH key pair at ~/.ssh/id_rsa_<Label> and register it with ssh-agent.
# Label is a free-form identifier (e.g. "github_myuser", "gcp_yorez333").
# Host alias / IdentityFile binding is configured separately in ssh/config.d/.
param(
    [string]$Label,
    [string]$Email
)

$ErrorActionPreference = "Stop"

if (-not $Label) { $Label = Read-Host "Enter key label (e.g. github_myuser)" }
if (-not $Email) { $Email = Read-Host "Enter email (used as key comment)" }

$KeyPath = Join-Path $env:USERPROFILE ".ssh\id_rsa_$Label"

Write-Host ""
Write-Host "Configuration:"
Write-Host "  Label:    $Label"
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
Write-Host "SSH key generated: $KeyPath" -ForegroundColor Green
Write-Host ""
Write-Host "Public key:"
Write-Host "========================================"
Get-Content "$KeyPath.pub"
Write-Host "========================================"
