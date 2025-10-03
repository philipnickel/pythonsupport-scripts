# @doc
# @name: DTU Python Support Windows Installer
# @description: Main entry point for Windows automated installation
# @category: Main
# @usage: . .\install.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Main script that orchestrates the complete Windows installation process
# @/doc

[CmdletBinding()]
param(
    [string]$RemoteRepo = "dtudk/pythonsupport-scripts",
    [string]$Branch = "main", 
    [string]$PythonVersion = "3.12",
    [switch]$UseGUI = $false,  # Default to false for better testing
    [switch]$Force = $true     # Skip user confirmation when true
)

# Early error handling setup - always continue
$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"

Write-Host "DTU Python Support - Windows Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Repository: $RemoteRepo" -ForegroundColor Gray
Write-Host "Branch: $Branch" -ForegroundColor Gray
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host ""

# Set environment variables
$env:REMOTE_PS = $RemoteRepo
$env:BRANCH_PS = $Branch
$env:PYTHON_VERSION_PS = $PythonVersion


# Set up logging
if (-not $env:INSTALL_LOG) {
    $env:INSTALL_LOG = "$env:TEMP\dtu_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

# Basic logging function (before loading common.ps1)
function Write-InstallLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host "DTU: $Message" -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "SUCCESS"){"Green"}elseif($Level -eq "WARNING"){"Yellow"}else{"White"})
    Add-Content -Path $env:INSTALL_LOG -Value $logEntry -ErrorAction SilentlyContinue
}

Write-InstallLog "Starting DTU Python Support installation"
Write-InstallLog "Log file: $env:INSTALL_LOG"

#if ( $false ) {
    # Load Piwik analytics utility
    #Write-InstallLog "Loading analytics utility..."
#    try {
        #$piwikUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/piwik_utility.ps1"
        #$piwikScript = Invoke-WebRequest -Uri $piwikUrl -UseBasicParsing -TimeoutSec 30
        #Invoke-Expression $piwikScript.Content
        #Write-InstallLog "Analytics utility loaded successfully"

        # Log installation start
        #Piwik-Log "1"
#    } catch {
#        Write-InstallLog "Could not load analytics utility: $($_.Exception.Message)" "WARNING"
#    }
#}

# Load configuration and utilities
Write-InstallLog "Loading configuration and utilities..."

try {
    # Load remote config
    Write-InstallLog "Loading remote configuration..."
    $ConfigUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/config.ps1"
    $ConfigScript = Invoke-WebRequest -Uri $ConfigUrl -UseBasicParsing
    Invoke-Expression $ConfigScript.Content
    Write-InstallLog "Remote config loaded successfully"
} catch {
    Write-InstallLog "Failed to load configuration: $($_.Exception.Message)" -Level "ERROR"
    Write-Host "Installation cannot continue without configuration" -ForegroundColor Red
    exit 1
}

try {
    # Load remote utilities
    Write-InstallLog "Loading remote utilities..."
    $CommonUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/Components/Shared/common.ps1"
    $CommonScript = Invoke-WebRequest -Uri $CommonUrl -UseBasicParsing
    Invoke-Expression $CommonScript.Content
    Write-InstallLog "Remote utilities loaded successfully"
} catch {
    Write-InstallLog "Failed to load utilities: $($_.Exception.Message)" -Level "ERROR"
    Write-Host "Installation cannot continue without utilities" -ForegroundColor Red
    exit 1
}

# Test that core functions are available
try {
    if (Get-Command Write-LogInfo -ErrorAction SilentlyContinue) {
        Write-LogInfo "Core utilities loaded successfully"
    } else {
        throw "Write-LogInfo function not available"
    }

    if (Get-Command Test-SystemRequirements -ErrorAction SilentlyContinue) {
        Write-LogInfo "System requirements function available"
    } else {
        throw "Test-SystemRequirements function not available"
    }
} catch {
    Write-InstallLog "Core functions not available: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}

# Load GUI dialogs if requested
$UseNativeDialogs = $false
if ($UseGUI) {
    try {
        Write-LogInfo "Loading remote GUI dialogs..."
        $DialogsUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/Components/Shared/windows_dialogs.ps1"
        $DialogsScript = Invoke-WebRequest -Uri $DialogsUrl -UseBasicParsing
        Invoke-Expression $DialogsScript.Content
        $UseNativeDialogs = $true
        Write-LogInfo "GUI dialogs loaded successfully"
    } catch {
        Write-LogWarning "Failed to load GUI dialogs, using terminal interface: $($_.Exception.Message)"
        $UseNativeDialogs = $false
    }
}

# Component loading helper function
function Invoke-ComponentScript {
    param(
        [string]$ComponentPath,
        [string]$Description = "component"
    )

    Write-LogInfo "Running $Description..."
    Write-LogInfo "Using remote $Description : $ComponentPath"

    try {
        $RemoteUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/$ComponentPath"
        $Script = Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing
        Invoke-Expression $Script.Content
        Write-LogSuccess "$Description completed successfully"
    } catch {
        Write-LogError "$Description failed: $($_.Exception.Message)"
        throw
    }
}

# === PHASE 1: PRE-INSTALLATION CHECKS ===
Write-Host ""
Write-LogInfo "=== Phase 1: Pre-Installation System Check ==="

# System requirements check
Write-LogInfo "Checking system requirements..."
if (-not (Test-SystemRequirements)) {
    Write-LogError "System requirements check failed - continuing anyway"
}

# Network connectivity check
Write-LogInfo "Checking network connectivity..."
if (-not (Test-NetworkConnectivity)) {
    Write-LogError "Network connectivity check failed - continuing anyway"
}

# Set execution policy
Write-LogInfo "Setting PowerShell execution policy..."
try {
    Set-ExecutionPolicySafe
} catch {
    Write-LogWarning "Could not set execution policy: $($_.Exception.Message)"
}

# Get user confirmation
$Proceed = $true

# Check if we should skip user confirmation
if ($Force) {
    Write-LogInfo "Force parameter specified, proceeding without confirmation"
    $Proceed = $true

} elseif ($UseNativeDialogs) {
    $Message = "This installer will set up Python development environment with:`n`n" +
               "- Python $PythonVersion (Miniforge)`n" +
               "- Visual Studio Code`n" +
               "- Essential packages and extensions`n`n" +
               "Continue with installation?"

    $Proceed = Show-ConfirmationDialog -Title "DTU Python Support Installation" -Message $Message
    if (-not $Proceed) {
        Show-InfoDialog -Title "Cancelled" -Message "Installation cancelled by user."
    }

} else {
    Write-Host ""
    Write-Host "This installation will set up:" -ForegroundColor White
    Write-Host "  - Python $PythonVersion (via Miniforge)" -ForegroundColor White
    Write-Host "  - Visual Studio Code" -ForegroundColor White
    Write-Host "  - Essential Python packages" -ForegroundColor White
    Write-Host "  - VSCode extensions" -ForegroundColor White
    Write-Host ""

    $Response = Read-Host "Continue? (y/N)"
    $Proceed = ($Response -eq "y" -or $Response -eq "Y")
}

if (-not $Proceed) {
    Write-LogInfo "Installation cancelled by user"
    exit 0
}

Write-LogSuccess "Phase 1 completed - system ready for installation"

# === PHASE 2: COMPONENT INSTALLATION ===
Write-Host ""
Write-LogInfo "=== Phase 2: Component Installation ==="

$InstallResults = @{
    Python = $false
    FirstYearSetup = $false
    VSCode = $false
}

# Install Python
Write-LogInfo "Installing Python (Miniforge)..."
try {
    Invoke-ComponentScript -ComponentPath "Components\Python\install.ps1" -Description "Python installer"
    $InstallResults.Python = $true
    Write-LogSuccess "Python installed successfully"
} catch {
    Write-LogError "Python installation failed: $($_.Exception.Message)"
}

# Setup Python environment
Write-LogInfo "Setting up Python environment..."
try {
    Invoke-ComponentScript -ComponentPath "Components\Python\first_year_setup.ps1" -Description "Python environment setup"
    $InstallResults.FirstYearSetup = $true
    Write-LogSuccess "Python environment setup completed"
} catch {
    Write-LogError "Python environment setup failed: $($_.Exception.Message)"
}

# Install VSCode
Write-LogInfo "Installing Visual Studio Code..."
try {
    Invoke-ComponentScript -ComponentPath "Components\VSC\install.ps1" -Description "VSCode installer"
    $InstallResults.VSCode = $true
    Write-LogSuccess "VSCode installed successfully"
} catch {
    Write-LogError "VSCode installation failed: $($_.Exception.Message)"
}

# Set execution policy for current user
Write-LogInfo "Setting execution policy to RemoteSigned for current user..."
Set-ExecutionPolicy -WarningAction:SilentlyContinue RemoteSigned -Scope CurrentUser -Force

# === PHASE 3: VERIFICATION AND SUMMARY ===
Write-Host ""
Write-LogInfo "=== Phase 3: Installation Summary ==="

# Show results
if ($UseNativeDialogs) {
    Show-InstallationSummary -Results $InstallResults
} else {
    Write-Host ""
    Write-Host "Installation Summary:" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    foreach ($Component in $InstallResults.Keys) {
        $Status = if ($InstallResults[$Component]) { "[OK]" } else { "[FAIL]" }
        $Color = if ($InstallResults[$Component]) { "Green" } else { "Red" }
        Write-Host "$Status $Component" -ForegroundColor $Color
    }
    
}

# Show final results
$successfulComponents = ($InstallResults.Values | Where-Object { $_ -eq $true }).Count
$totalComponents = $InstallResults.Count

Write-LogInfo "Installation log: $env:INSTALL_LOG"

Write-Host ""
if ($successfulComponents -eq $totalComponents) {
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-LogSuccess "DTU Python Support installation completed successfully!"
} elseif ($successfulComponents -gt 0) {
    Write-Host "Installation completed with partial success ($successfulComponents/$totalComponents components)" -ForegroundColor Yellow
    Write-LogWarning "DTU Python Support installation completed with partial success"
} else {
    Write-Host "Installation failed!" -ForegroundColor Red
    Write-LogError "DTU Python Support installation failed"
}
Write-Host "Log file: $env:INSTALL_LOG" -ForegroundColor Gray

# Generate installation report silently as the very last step
Write-LogInfo "Generating installation report..."
try {
    PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/Components/Diagnostics/generate_report.ps1' -UseBasicParsing).Content}"
    Write-LogSuccess "Installation report generated successfully"
} catch {
    Write-LogWarning "Could not generate installation report: $($_.Exception.Message)"
    Write-Host "NOTE: Installation may still have been successful. Please verify manually." -ForegroundColor Yellow
}
