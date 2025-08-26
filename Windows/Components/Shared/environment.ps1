# @doc
# @name: Environment Setup Utilities
# @description: Environment variable management and system configuration functions for Windows
# @category: Utilities
# @usage: . .\environment.ps1
# @requirements: PowerShell 5.1+, Windows 10/11
# @notes: Handles REMOTE_PS/BRANCH_PS variables, URL construction, and environment validation
# @/doc

# Function to set default environment variables for remote repository access
function Set-DefaultEnv {
    if (-not $env:REMOTE_PS) {
        $env:REMOTE_PS = "dtudk/pythonsupport-scripts"
    }
    if (-not $env:BRANCH_PS) {
        $env:BRANCH_PS = "main"
    }
    if (-not $env:PYTHON_VERSION_PS) {
        $env:PYTHON_VERSION_PS = "3.11"
    }
}

# Function to get the base URL for scripts
function Get-BaseUrl {
    Set-DefaultEnv
    return "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows"
}

# Function to construct component script URLs
function Get-ScriptUrl {
    param(
        [string]$Component,
        [string]$Script
    )
    
    $baseUrl = Get-BaseUrl
    return "$baseUrl/Components/$Component/$Script"
}

# Function to detect system architecture
function Get-SystemArch {
    if ([Environment]::Is64BitOperatingSystem) {
        return "x64"
    }
    else {
        return "x86"
    }
}

# Function to detect Windows version
function Get-WindowsVersion {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return $os.Version
}

# Function to get Windows build number
function Get-WindowsBuild {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return $os.BuildNumber
}

# Function to check system requirements
function Test-SystemRequirements {
    param([string]$MinWindowsVersion = "10.0.0")
    
    # Check if running on Windows
    if ($env:OS -ne "Windows_NT") {
        Write-LogError "This script is designed for Windows only"
        Exit-Message
    }
    
    # Check Windows version
    $currentVersion = Get-WindowsVersion
    if (-not (Test-VersionGreaterEqual $currentVersion $MinWindowsVersion)) {
        Write-LogError "Windows 10 or later is required (current: $currentVersion)"
        Exit-Message
    }
    
    Write-LogInfo "System check passed: Windows $currentVersion ($(Get-SystemArch))"
}

# Function to compare version numbers
function Test-VersionGreaterEqual {
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    try {
        $v1 = [Version]$Version1
        $v2 = [Version]$Version2
        return $v1 -ge $v2
    }
    catch {
        Write-LogError "Invalid version format: $Version1 or $Version2"
        return $false
    }
}

# Function to setup PowerShell profile
function Set-PowerShellProfile {
    $profilePath = $PROFILE.CurrentUserAllHosts
    
    # Ensure the profile directory exists
    $profileDir = Split-Path $profilePath -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Ensure the profile file exists
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }
    
    return $profilePath
}

# Function to add to PATH environment variable
function Add-ToPath {
    param([string]$PathToAdd)
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPath -notlike "*$PathToAdd*") {
        $newPath = "$currentPath;$PathToAdd"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-LogInfo "Added $PathToAdd to PATH"
        return $true
    }
    else {
        Write-LogInfo "$PathToAdd already in PATH"
        return $false
    }
}

# Function to get temporary directory
function Get-TempDir {
    return $env:TEMP
}

# Function to get user home directory
function Get-UserHome {
    return $env:USERPROFILE
}

# Function to get program files directory
function Get-ProgramFiles {
    return $env:ProgramFiles
}

# Function to get local app data directory
function Get-LocalAppData {
    return $env:LOCALAPPDATA
}
