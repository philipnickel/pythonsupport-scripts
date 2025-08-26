# @doc
# @name: DTU Python Support Windows Installer
# @description: Main entry point for Windows automated installation
# @category: Main
# @usage: . .\install.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Main script that orchestrates the complete Windows installation process
# @/doc

param(
    [string]$RemoteRepo = "dtudk/pythonsupport-scripts",
    [string]$Branch = "main", 
    [string]$PythonVersion = "3.11",
    [switch]$UseGUI = $true
)

# Set default values and export environment variables
$env:REMOTE_PS = $RemoteRepo
$env:BRANCH_PS = $Branch
$env:PYTHON_VERSION_PS = $PythonVersion

Write-Host "DTU Python Support - Automated Windows Installation" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Repository: $RemoteRepo" -ForegroundColor Gray
Write-Host "Branch: $Branch" -ForegroundColor Gray
Write-Host ""

# Set up logging
if (-not $env:INSTALL_LOG) {
    $env:INSTALL_LOG = "$env:TEMP\dtu_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

"=== DTU Python Support Installation Log ===" | Out-File -FilePath $env:INSTALL_LOG
"Started: $(Get-Date)" | Out-File -FilePath $env:INSTALL_LOG -Append
"Repository: $RemoteRepo" | Out-File -FilePath $env:INSTALL_LOG -Append
"Branch: $Branch" | Out-File -FilePath $env:INSTALL_LOG -Append
"" | Out-File -FilePath $env:INSTALL_LOG -Append

# Load configuration and common utilities
try {
    Write-Host "Loading configuration..." -ForegroundColor Gray
    $configUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/config.ps1"
    $configScript = Invoke-WebRequest -Uri $configUrl -UseBasicParsing
    Invoke-Expression $configScript.Content
    
    $commonUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/Components/Shared/common.ps1"  
    $commonScript = Invoke-WebRequest -Uri $commonUrl -UseBasicParsing
    Invoke-Expression $commonScript.Content
}
catch {
    Write-Host "Failed to load configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Load GUI dialogs if available and requested
$useNativeDialogs = $false
if ($UseGUI) {
    try {
        $dialogsUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/Components/Shared/windows_dialogs.ps1"
        $dialogsScript = Invoke-WebRequest -Uri $dialogsUrl -UseBasicParsing
        Invoke-Expression $dialogsScript.Content
        $useNativeDialogs = $true
        Write-LogInfo "Native GUI dialogs loaded"
    }
    catch {
        Write-LogWarning "Failed to load GUI dialogs, using terminal interface"
        $useNativeDialogs = $false
    }
}

# === PHASE 1: PRE-INSTALLATION CHECK ===
Write-Host ""
Write-Host "Phase 1: Pre-Installation System Check" -ForegroundColor White
Write-Host "=======================================" -ForegroundColor White

# System requirements check
if (-not (Test-SystemRequirements)) {
    Exit-WithError "System requirements check failed"
}

# Network connectivity check
if (-not (Test-NetworkConnectivity)) {
    Exit-WithError "Network connectivity check failed"
}

# Set execution policy
Set-ExecutionPolicySafe

# Show installation plan and get confirmation
if ($useNativeDialogs) {
    $message = "This installer will set up your Python development environment with:`n`n" +
               "• Python $PythonVersion (via Miniforge)`n" +
               "• Visual Studio Code`n" +
               "• Essential Python packages`n" +
               "• VSCode extensions for Python development`n`n" +
               "Repository: $RemoteRepo`n" +
               "Branch: $Branch`n`n" +
               "Do you want to continue?"
    
    $confirm = Show-ConfirmationDialog -Title "DTU Python Support - Windows Installation" -Message $message
    if (-not $confirm) {
        Show-InfoDialog -Title "Installation Cancelled" -Message "Installation has been cancelled by user."
        exit 0
    }
} else {
    Write-Host "This script will install:" -ForegroundColor White
    Write-Host "  • Python $PythonVersion (via Miniforge)" -ForegroundColor White
    Write-Host "  • Visual Studio Code" -ForegroundColor White
    Write-Host "  • Essential Python packages" -ForegroundColor White
    Write-Host "  • VSCode extensions for Python development" -ForegroundColor White
    Write-Host ""
    
    $confirmation = Read-Host "Do you want to continue? (y/N)"
    if ($confirmation -ne "y" -and $confirmation -ne "Y") {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-LogInfo "Phase 1: Pre-installation checks completed"

# === PHASE 2: MAIN INSTALLATION ===
Write-Host ""
Write-Host "Phase 2: Main Installation Process" -ForegroundColor White
Write-Host "==================================" -ForegroundColor White

$installResults = @{
    Python = $false
    FirstYearSetup = $false
    VSCode = $false
}

try {
    if ($useNativeDialogs) {
        $installSuccess = Show-ProgressDialog -Title "DTU Python Support Installation" -InitialMessage "Starting installation process..." -InstallScript {
            # Install Python with Miniforge
            Update-ProgressDialog -Message "Installing Python (Miniforge)..."
            Write-LogInfo "Installing Python with Miniforge..."
            
            try {
                $pythonUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/install.ps1"
                $pythonScript = Invoke-WebRequest -Uri $pythonUrl -UseBasicParsing
                Invoke-Expression $pythonScript.Content
                $installResults.Python = $true
                Write-LogSuccess "Python installation completed"
            }
            catch {
                Write-LogError "Python installation failed: $($_.Exception.Message)"
                throw
            }
            
            # Setup Python environment and packages
            Update-ProgressDialog -Message "Setting up Python environment and packages..."
            Write-LogInfo "Setting up Python environment and packages..."
            
            try {
                $setupUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/first_year_setup.ps1"
                $setupScript = Invoke-WebRequest -Uri $setupUrl -UseBasicParsing
                Invoke-Expression $setupScript.Content
                $installResults.FirstYearSetup = $true
                Write-LogSuccess "Python environment setup completed"
            }
            catch {
                Write-LogError "Python environment setup failed: $($_.Exception.Message)"
                throw
            }
            
            # Install Visual Studio Code and extensions
            Update-ProgressDialog -Message "Installing Visual Studio Code..."
            Write-LogInfo "Installing Visual Studio Code..."
            
            try {
                $vscodeUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/VSC/install.ps1"
                $vscodeScript = Invoke-WebRequest -Uri $vscodeUrl -UseBasicParsing
                Invoke-Expression $vscodeScript.Content
                $installResults.VSCode = $true
                Write-LogSuccess "Visual Studio Code installation completed"
            }
            catch {
                Write-LogError "Visual Studio Code installation failed: $($_.Exception.Message)"
                throw
            }
            
            Update-ProgressDialog -Message "Installation completed!"
            Start-Sleep -Milliseconds 1000
        }
        
        if (-not $installSuccess) {
            Exit-WithError "Installation process failed"
        }
    } else {
        # Terminal-based installation
        Write-LogInfo "Installing Python with Miniforge..."
        $pythonUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/install.ps1"
        $pythonScript = Invoke-WebRequest -Uri $pythonUrl -UseBasicParsing
        Invoke-Expression $pythonScript.Content
        $installResults.Python = $true
        Write-LogSuccess "Python installation completed"
        
        Write-LogInfo "Setting up Python environment and packages..."
        $setupUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/first_year_setup.ps1"
        $setupScript = Invoke-WebRequest -Uri $setupUrl -UseBasicParsing
        Invoke-Expression $setupScript.Content
        $installResults.FirstYearSetup = $true
        Write-LogSuccess "Python environment setup completed"
        
        Write-LogInfo "Installing Visual Studio Code..."
        $vscodeUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/VSC/install.ps1"
        $vscodeScript = Invoke-WebRequest -Uri $vscodeUrl -UseBasicParsing
        Invoke-Expression $vscodeScript.Content
        $installResults.VSCode = $true
        Write-LogSuccess "Visual Studio Code installation completed"
    }
}
catch {
    Write-LogError "Installation failed: $($_.Exception.Message)"
    if ($useNativeDialogs) {
        Show-ErrorDialog -Title "Installation Failed" -Message "Installation failed: $($_.Exception.Message)`n`nFor help, visit: https://pythonsupport.dtu.dk/install/windows/automated-error.html`nOr contact: pythonsupport@dtu.dk"
    }
    Exit-WithError "Installation process failed"
}

Write-LogInfo "Phase 2: Main installation process completed"

# === PHASE 3: POST-INSTALLATION VERIFICATION ===
Write-Host ""
Write-Host "Phase 3: Post-Installation Verification" -ForegroundColor White
Write-Host "========================================" -ForegroundColor White

Write-LogInfo "Running post-installation verification..."

# Show installation summary
if ($useNativeDialogs) {
    Show-InstallationSummary -Results $installResults
} else {
    Write-Host ""
    Write-Host "Installation Summary:" -ForegroundColor White
    Write-Host "===================" -ForegroundColor White
    foreach ($component in $installResults.Keys) {
        $status = if ($installResults[$component]) { "✓" } else { "✗" }
        $color = if ($installResults[$component]) { "Green" } else { "Red" }
        Write-Host "$status $component" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "DTU Python Support Installation Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

if (-not $useNativeDialogs) {
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "1. Restart your terminal/PowerShell to ensure all PATH changes take effect" -ForegroundColor White
    Write-Host "2. Open VSCode and start coding with Python!" -ForegroundColor White
    Write-Host "3. Use 'conda activate first_year' to activate the Python environment" -ForegroundColor White
    Write-Host "4. Visit https://pythonsupport.dtu.dk for additional resources" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation log saved to: $env:INSTALL_LOG" -ForegroundColor Gray
}

Write-LogSuccess "Installation completed successfully!"
Write-LogInfo "Installation log saved to: $env:INSTALL_LOG"