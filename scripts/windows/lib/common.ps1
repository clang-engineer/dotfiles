# Shared utility functions for Windows setup scripts

function Write-TaskHeader {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function New-Junction {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Dest,
        [switch]$Force
    )

    if (-not (Test-Path $Source)) {
        Write-Error "Source not found: $Source"
        return $false
    }

    if (Test-Path $Dest) {
        $Item = Get-Item $Dest

        if ($Item.LinkType -eq "Junction" -or $Item.LinkType -eq "SymbolicLink") {
            Write-Host "Removing existing link..." -ForegroundColor Yellow
            Remove-Item $Dest -Force
        }
        else {
            $BackupPath = "$Dest.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Host "Backing up existing folder to: $BackupPath" -ForegroundColor Yellow
            Move-Item $Dest $BackupPath -Force
        }
    }

    Write-Host "Creating Junction..." -ForegroundColor Green
    $result = cmd /c mklink /J "$Dest" "$Source" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Linked successfully." -ForegroundColor Green
        Get-Item $Dest | Select-Object FullName, LinkType, Target
        return $true
    } else {
        Write-Error "Failed to create Junction: $result"
        return $false
    }
}
