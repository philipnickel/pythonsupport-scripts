# @doc
# @name: Windows AutoInstall
# @description: Main entry point for Windows automated installation
# @category: Main
# @usage: . .\AutoInstall.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Main script that orchestrates the complete Windows installation process
# @/doc

# Set script parameters
param(
    [string]$RemoteRepo = "dtudk/pythonsupport-scripts",
    [string]$Branch = "main",
    [string]$PythonVersion = "3.11",
    [switch]$UseGUI = $true
)

# Set environment variables
$env:REMOTE_PS = $RemoteRepo
$env:BRANCH_PS = $Branch
$env:PYTHON_VERSION_PS = $PythonVersion

# Load GUI dialogs if available and requested
$useNativeDialogs = $false
if ($UseGUI) {
    try {
        $dialogsUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/Components/Shared/gui_dialogs.ps1"
        $dialogsScript = Invoke-WebRequest -Uri $dialogsUrl -UseBasicParsing
        Invoke-Expression $dialogsScript.Content
        $useNativeDialogs = $true
        Write-Host "Native GUI dialogs loaded" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to load GUI dialogs, falling back to terminal mode" -ForegroundColor Yellow
        $useNativeDialogs = $false
    }
}

if ($useNativeDialogs) {
    # Show welcome dialog
    $message = "This installer will set up your Python development environment with:`n`n" +
               "• Python $PythonVersion (via Miniforge)`n" +
               "• Visual Studio Code`n" +
               "• Essential Python packages`n" +
               "• VSCode extensions for Python development`n`n" +
               "Repository: $RemoteRepo`n" +
               "Branch: $Branch`n`n" +
               "Do you want to continue?"
    
    $confirm = Show-ConfirmationDialog -Title "DTU Python Support - Windows AutoInstall" -Message $message
    if (-not $confirm) {
        Show-InfoDialog -Title "Installation Cancelled" -Message "Installation has been cancelled by user."
        exit 0
    }
} else {
    # Fallback to terminal interface
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "DTU Python Support - Windows AutoInstall" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "This script will install:" -ForegroundColor White
    Write-Host "  • Python $PythonVersion (via Miniforge)" -ForegroundColor White
    Write-Host "  • Visual Studio Code" -ForegroundColor White
    Write-Host "  • Essential Python packages" -ForegroundColor White
    Write-Host "  • VSCode extensions for Python development" -ForegroundColor White
    Write-Host ""

    Write-Host "Repository: $RemoteRepo" -ForegroundColor Gray
    Write-Host "Branch: $Branch" -ForegroundColor Gray
    Write-Host ""

    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin) {
        Write-Host "Running as Administrator" -ForegroundColor Yellow
    }
    else {
        Write-Host "Not running as Administrator - some operations may require elevation" -ForegroundColor Yellow
    }

    Write-Host ""

    # Ask for confirmation
    $confirmation = Read-Host "Do you want to continue? (y/N)"
    if ($confirmation -ne "y" -and $confirmation -ne "Y") {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""

# Run the orchestrator
try {
    $orchestratorUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/Components/orchestrators/first_year_students.ps1"
    
    if ($useNativeDialogs) {
        # Run installation with progress dialog
        $installSuccess = Show-ProgressDialog -Title "DTU Python Support Installation" -InitialMessage "Starting installation process..." -InstallScript {
            Update-ProgressDialog -Message "Downloading orchestrator..."
            $orchestratorScript = Invoke-WebRequest -Uri $orchestratorUrl -UseBasicParsing
            
            Update-ProgressDialog -Message "Running installation orchestrator..."
            $env:USE_GUI_DIALOGS = "true"
            Invoke-Expression $orchestratorScript.Content
        }
        
        if (-not $installSuccess) {
            exit 1
        }
    } else {
        Write-Host "Downloading and running orchestrator..." -ForegroundColor Green
        $orchestratorScript = Invoke-WebRequest -Uri $orchestratorUrl -UseBasicParsing
        Invoke-Expression $orchestratorScript.Content
    }
}
catch {
    if ($useNativeDialogs) {
        Show-ErrorDialog -Title "Installation Failed" -Message "Failed to run orchestrator: $($_.Exception.Message)`n`nPlease visit: https://pythonsupport.dtu.dk/install/windows/automated-error.html`nOr contact: pythonsupport@dtu.dk"
    } else {
        Write-Host "Failed to run orchestrator: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please visit: https://pythonsupport.dtu.dk/install/windows/automated-error.html" -ForegroundColor Yellow
        Write-Host "Or contact: pythonsupport@dtu.dk" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Installation completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Restart your terminal/PowerShell" -ForegroundColor White
Write-Host "2. Open VSCode and start coding!" -ForegroundColor White
Write-Host "3. Use 'conda activate first_year' to activate Python environment" -ForegroundColor White
Write-Host "4. Visit https://pythonsupport.dtu.dk for resources" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
