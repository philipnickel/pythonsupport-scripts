# @doc
# @name: Common Utilities
# @description: Minimal utilities for Windows Python Support Scripts
# @category: Utilities
# @usage: . .\common.ps1
# @requirements: PowerShell 5.1+
# @notes: Core functions for logging, error handling, and system checks
# @/doc

# Set up global log file if not already set
if (-not $env:INSTALL_LOG) {
    $env:INSTALL_LOG = "$env:TEMP\dtu_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

# Standard prefix for all Python Support scripts
$script:Prefix = "DTU:"

# Core logging functions
function Write-LogInfo {
    param([string]$Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] $Message"
    Write-Host "$Prefix $Message"
    Add-Content -Path $env:INSTALL_LOG -Value $logMessage
}

function Write-LogError {
    param([string]$Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ERROR] $Message"
    Write-Host "$Prefix ERROR: $Message" -ForegroundColor Red
    Add-Content -Path $env:INSTALL_LOG -Value $logMessage
}

function Write-LogSuccess {
    param([string]$Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [SUCCESS] $Message"
    Write-Host "$Prefix ✓ $Message" -ForegroundColor Green
    Add-Content -Path $env:INSTALL_LOG -Value $logMessage
}

function Write-LogWarning {
    param([string]$Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [WARNING] $Message"
    Write-Host "$Prefix WARNING: $Message" -ForegroundColor Yellow
    Add-Content -Path $env:INSTALL_LOG -Value $logMessage
}

# System requirements check
function Test-SystemRequirements {
    $issues = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion -lt [Version]"5.1") {
        $issues += "PowerShell version $($PSVersionTable.PSVersion) is below minimum required version 5.1"
    }
    
    # Check Windows version
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        $issues += "Windows version $($osVersion.Major).$($osVersion.Minor) is not supported. Windows 10 or later required."
    }
    
    # Check disk space (require at least 2GB)
    try {
        $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($env:USERPROFILE).TrimEnd('\'))
        $freeSpaceGB = [Math]::Round($drive.Free / 1GB, 2)
        if ($freeSpaceGB -lt 2) {
            $issues += "Insufficient disk space. Available: ${freeSpaceGB}GB, Required: 2GB minimum"
        }
    }
    catch {
        $issues += "Unable to check disk space: $($_.Exception.Message)"
    }
    
    if ($issues.Count -gt 0) {
        Write-LogError "System requirements check failed:"
        foreach ($issue in $issues) {
            Write-LogError "  • $issue"
        }
        return $false
    }
    
    Write-LogSuccess "System requirements check passed"
    return $true
}

# Network connectivity test
function Test-NetworkConnectivity {
    param(
        [string]$Url = "https://github.com",
        [int]$MaxRetries = 3
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "Network connectivity confirmed"
                return $true
            }
        }
        catch {
            Write-LogWarning "Network test failed (attempt $i/$MaxRetries): $($_.Exception.Message)"
            if ($i -lt $MaxRetries) {
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-LogError "Network connectivity test failed after $MaxRetries attempts"
    return $false
}

# Set execution policy safely
function Set-ExecutionPolicySafe {
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($currentPolicy -eq "Restricted") {
            Write-LogInfo "Setting PowerShell execution policy to RemoteSigned..."
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-LogSuccess "Execution policy updated"
        } else {
            Write-LogInfo "Execution policy is already set to: $currentPolicy"
        }
    }
    catch {
        Write-LogError "Failed to set execution policy: $($_.Exception.Message)"
        throw
    }
}

# Error exit function
function Exit-WithError {
    param([string]$Message = "Installation failed")
    
    Write-LogError $Message
    Write-LogError ""
    Write-LogError "For help, visit: https://pythonsupport.dtu.dk/install/windows/automated-error.html"
    Write-LogError "Or contact: pythonsupport@dtu.dk"
    
    exit 1
}