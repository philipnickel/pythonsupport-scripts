# @doc
# @name: Dependencies Utilities
# @description: Windows-specific dependency validation and system checks
# @category: Utilities
# @usage: . .\dependencies.ps1
# @requirements: PowerShell 5.1+, Windows 10/11
# @notes: Provides Windows-specific dependency checks and validation
# @/doc

# Function to check PowerShell version
function Test-PowerShellVersion {
    param([string]$MinVersion = "5.1")
    
    $psVersion = $PSVersionTable.PSVersion
    Write-LogInfo "PowerShell version: $psVersion"
    
    if ($psVersion -lt [Version]$MinVersion) {
        Write-LogError "PowerShell $MinVersion or later is required (current: $psVersion)"
        Exit-Message
    }
    
    Write-LogSuccess "PowerShell version check passed"
}

# Function to check .NET Framework
function Test-DotNetFramework {
    param([string]$MinVersion = "4.7.2")
    
    try {
        $dotNetVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction Stop).Release
        $versionMap = @{
            378389 = "4.5"
            378675 = "4.5.1"
            379893 = "4.5.2"
            393295 = "4.6"
            394254 = "4.6.1"
            394802 = "4.6.2"
            460798 = "4.7"
            461308 = "4.7.1"
            461808 = "4.7.2"
            528040 = "4.8"
        }
        
        $installedVersion = $versionMap[$dotNetVersion] ?? "Unknown"
        Write-LogInfo ".NET Framework version: $installedVersion"
        
        if ($dotNetVersion -lt 461808) { # 4.7.2
            Write-LogError ".NET Framework $MinVersion or later is required (current: $installedVersion)"
            Exit-Message
        }
        
        Write-LogSuccess ".NET Framework version check passed"
    }
    catch {
        Write-LogError "Failed to check .NET Framework version: $($_.Exception.Message)"
        Exit-Message
    }
}

# Function to check Windows features
function Test-WindowsFeatures {
    Write-LogInfo "Checking Windows features..."
    
    # Check for Windows Subsystem for Linux (optional)
    try {
        $wslEnabled = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
        if ($wslEnabled.State -eq "Enabled") {
            Write-LogInfo "WSL is enabled"
        }
    }
    catch {
        Write-LogDebug "WSL check failed (not critical)"
    }
    
    Write-LogSuccess "Windows features check completed"
}

# Function to check available disk space
function Test-DiskSpace {
    param([long]$MinSpaceGB = 5)
    
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    
    Write-LogInfo "Available disk space: $freeSpaceGB GB"
    
    if ($freeSpaceGB -lt $MinSpaceGB) {
        Write-LogError "At least $MinSpaceGB GB of free disk space is required (available: $freeSpaceGB GB)"
        Exit-Message
    }
    
    Write-LogSuccess "Disk space check passed"
}

# Function to check internet connectivity
function Test-InternetConnectivity {
    Write-LogInfo "Checking internet connectivity..."
    
    try {
        $response = Invoke-WebRequest -Uri "https://www.google.com" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-LogSuccess "Internet connectivity confirmed"
            return $true
        }
    }
    catch {
        Write-LogError "No internet connectivity detected"
        Write-LogError "Please check your network connection and try again"
        Exit-Message
    }
}

# Function to check if running as administrator
function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if ($isAdmin) {
        Write-LogInfo "Running with administrator privileges"
        return $true
    }
    else {
        Write-LogWarning "Not running with administrator privileges"
        Write-LogInfo "Some operations may require elevation"
        return $false
    }
}

# Function to check antivirus software
function Test-AntivirusSoftware {
    Write-LogInfo "Checking antivirus software..."
    
    try {
        $antivirus = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
        if ($antivirus) {
            foreach ($av in $antivirus) {
                Write-LogInfo "Antivirus: $($av.displayName) - State: $($av.productState)"
            }
        }
        else {
            Write-LogInfo "No antivirus software detected via WMI"
        }
    }
    catch {
        Write-LogDebug "Antivirus check failed (not critical): $($_.Exception.Message)"
    }
}

# Function to run all dependency checks
function Test-AllDependencies {
    Write-LogInfo "Running dependency checks..."
    
    Test-PowerShellVersion
    Test-DotNetFramework
    Test-SystemRequirements
    Test-WindowsFeatures
    Test-DiskSpace
    Test-InternetConnectivity
    Test-AdminPrivileges
    Test-AntivirusSoftware
    
    Write-LogSuccess "All dependency checks passed"
}

# Function to check if a specific application is installed
function Test-ApplicationInstalled {
    param([string]$AppName)
    
    $installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$AppName*" }
    
    if ($installed) {
        Write-LogInfo "$AppName is already installed"
        return $true
    }
    else {
        Write-LogInfo "$AppName is not installed"
        return $false
    }
}

# Function to check if a specific service is running
function Test-ServiceRunning {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($service.Status -eq "Running") {
            Write-LogInfo "Service $ServiceName is running"
            return $true
        }
        else {
            Write-LogInfo "Service $ServiceName is not running (Status: $($service.Status))"
            return $false
        }
    }
    catch {
        Write-LogInfo "Service $ServiceName not found"
        return $false
    }
}
