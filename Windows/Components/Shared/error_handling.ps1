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
