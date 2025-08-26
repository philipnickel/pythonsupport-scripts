# @doc
# @name: Error Handling Utilities
# @description: Standardized error handling, logging, and user messaging functions for Windows
# @category: Utilities
# @usage: . .\error_handling.ps1
# @requirements: PowerShell 5.1+
# @notes: Provides consistent error messages, logging levels, and exit handling across all scripts
# @/doc

# Standard prefix for all Python Support scripts
$script:Prefix = "PYS:"

# Error function - Print error message, contact information and exits script
function Exit-Message {
    Write-Host ""
    Write-Host "Oh no! Something went wrong"
    Write-Host ""
    Write-Host "Please visit the following web page:"
    Write-Host ""
    Write-Host "   https://pythonsupport.dtu.dk/install/windows/automated-error.html"
    Write-Host ""
    Write-Host "or contact the Python Support Team:"
    Write-Host ""
    Write-Host "   pythonsupport@dtu.dk"
    Write-Host ""
    Write-Host "Or visit us during our office hours"
    
    if (-not $env:PKG_INSTALLER) {
        Start-Process "https://pythonsupport.dtu.dk/install/windows/automated-error.html"
    }
    
    exit 1
}

# Logging functions with consistent formatting
function Write-LogInfo {
    param([string]$Message)
    Write-Host "$Prefix $Message"
}

function Write-LogError {
    param([string]$Message)
    Write-Host "$Prefix ERROR: $Message" -ForegroundColor Red
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "$Prefix ✓ $Message" -ForegroundColor Green
}

function Write-LogWarning {
    param([string]$Message)
    Write-Host "$Prefix WARNING: $Message" -ForegroundColor Yellow
}

function Write-LogDebug {
    param([string]$Message)
    if ($env:DEBUG -eq "true") {
        Write-Host "$Prefix DEBUG: $Message" -ForegroundColor Gray
    }
}

# Enhanced error checking function
function Check-ExitCode {
    param([string]$ErrorMessage)
    
    if ($LASTEXITCODE -ne 0) {
        if ($ErrorMessage) {
            Write-LogError $ErrorMessage
        }
        Exit-Message
    }
}

# Function to check if a command exists
function Test-Command {
    param(
        [string]$Command,
        [string]$ErrorMessage
    )
    
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-LogError ($ErrorMessage ?? "Command '$Command' not found")
        Exit-Message
    }
}

# Function to require admin access
function Require-Admin {
    param([string]$Message)
    
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544") {
        Write-LogWarning "Running as administrator - this may not be necessary"
        return $true
    }
    
    Write-LogInfo ($Message ?? "This script requires administrator privileges")
    
    # Check if we can elevate
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-LogError "Failed to obtain administrator privileges"
        Exit-Message
    }
    
    return $true
}

# Function to handle PowerShell execution policy
function Set-ExecutionPolicySafe {
    param([string]$Policy = "RemoteSigned")
    
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($currentPolicy -eq "Restricted") {
            Write-LogInfo "Setting PowerShell execution policy to $Policy for current user..."
            Set-ExecutionPolicy -ExecutionPolicy $Policy -Scope CurrentUser -Force
            Write-LogSuccess "Execution policy updated successfully"
        }
        else {
            Write-LogInfo "Execution policy is already set to: $currentPolicy"
        }
    }
    catch {
        Write-LogError "Failed to set execution policy: $($_.Exception.Message)"
        Exit-Message
    }
}

# Function to test network connectivity with retry logic
function Test-NetworkConnectivity {
    param(
        [string]$Url = "https://github.com",
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            Write-LogDebug "Testing network connectivity (attempt $i/$MaxRetries)..."
            $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "Network connectivity confirmed"
                return $true
            }
        }
        catch {
            Write-LogWarning "Network test failed (attempt $i/$MaxRetries): $($_.Exception.Message)"
            if ($i -lt $MaxRetries) {
                Write-LogInfo "Retrying in $DelaySeconds seconds..."
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }
    
    Write-LogError "Network connectivity test failed after $MaxRetries attempts"
    Write-LogError "Please check your internet connection and firewall settings"
    return $false
}

# Function to clean up temporary files
function Clear-TempFiles {
    param([string[]]$AdditionalPaths = @())
    
    $tempPaths = @(
        "$env:TEMP\*.exe",
        "$env:TEMP\*.msi",
        "$env:TEMP\*.zip", 
        "$env:TEMP\miniforge*.sh",
        "$env:TEMP\VSCode*.zip"
    ) + $AdditionalPaths
    
    foreach ($pattern in $tempPaths) {
        try {
            $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
            if ($files) {
                Write-LogDebug "Cleaning up temporary files: $pattern"
                $files | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-LogDebug "Failed to clean temp files $pattern : $($_.Exception.Message)"
        }
    }
}

# Function to check system requirements
function Test-SystemRequirements {
    param(
        [Version]$MinPowerShellVersion = [Version]"5.1",
        [string[]]$RequiredFeatures = @()
    )
    
    $issues = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion -lt $MinPowerShellVersion) {
        $issues += "PowerShell version $($PSVersionTable.PSVersion) is below minimum required version $MinPowerShellVersion"
    }
    
    # Check Windows version
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        $issues += "Windows version $($osVersion.Major).$($osVersion.Minor) is not supported. Windows 10 or later is required."
    }
    
    # Check architecture
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -ne "AMD64" -and $arch -ne "ARM64") {
        $issues += "Processor architecture '$arch' may not be supported. AMD64 or ARM64 recommended."
    }
    
    # Check available disk space (require at least 2GB)
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
    
    # Check for Windows Defender or antivirus interference
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus -and $defenderStatus.RealTimeProtectionEnabled) {
            Write-LogWarning "Windows Defender real-time protection is enabled - this may slow down installation"
        }
    }
    catch {
        Write-LogDebug "Unable to check Windows Defender status"
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

# Function to attempt recovery from common installation failures
function Invoke-InstallationRecovery {
    param(
        [string]$ComponentName,
        [string]$ErrorMessage,
        [scriptblock]$RetryAction
    )
    
    Write-LogWarning "$ComponentName installation failed: $ErrorMessage"
    Write-LogInfo "Attempting recovery procedures..."
    
    # Clean up any partial installations
    Clear-TempFiles
    
    # Check network connectivity
    if (-not (Test-NetworkConnectivity)) {
        Write-LogError "Recovery failed: Network connectivity issues detected"
        return $false
    }
    
    # Wait a moment before retry
    Write-LogInfo "Waiting 5 seconds before retry..."
    Start-Sleep -Seconds 5
    
    # Attempt retry
    try {
        Write-LogInfo "Retrying $ComponentName installation..."
        & $RetryAction
        Write-LogSuccess "$ComponentName installation recovery successful"
        return $true
    }
    catch {
        Write-LogError "Recovery attempt failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to create installation report
function New-InstallationReport {
    param(
        [hashtable]$Results,
        [string]$LogPath = "$env:TEMP\dtu_install_report.txt"
    )
    
    $report = @"
DTU Python Support Installation Report
======================================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Computer: $env:COMPUTERNAME
User: $env:USERNAME
OS: $((Get-CimInstance -ClassName Win32_OperatingSystem).Caption)
PowerShell: $($PSVersionTable.PSVersion)

Installation Results:
"@
    
    foreach ($component in $Results.Keys) {
        $status = if ($Results[$component]) { "SUCCESS" } else { "FAILED" }
        $report += "`n$component : $status"
    }
    
    $report += @"

System Information:
Architecture: $env:PROCESSOR_ARCHITECTURE
.NET Version: $($PSVersionTable.CLRVersion)
Execution Policy: $(Get-ExecutionPolicy -Scope CurrentUser)

Environment Variables:
REMOTE_PS: $env:REMOTE_PS
BRANCH_PS: $env:BRANCH_PS
PYTHON_VERSION_PS: $env:PYTHON_VERSION_PS

Report saved to: $LogPath
"@
    
    try {
        $report | Out-File -FilePath $LogPath -Encoding UTF8
        Write-LogInfo "Installation report saved to: $LogPath"
    }
    catch {
        Write-LogWarning "Failed to save installation report: $($_.Exception.Message)"
    }
}
