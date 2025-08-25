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
    [string]$PythonVersion = "3.11"
)

# Set environment variables
$env:REMOTE_PS = $RemoteRepo
$env:BRANCH_PS = $Branch
$env:PYTHON_VERSION_PS = $PythonVersion

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

Write-Host ""

# Run the orchestrator
try {
    $orchestratorUrl = "https://raw.githubusercontent.com/$RemoteRepo/$Branch/Windows/Components/orchestrators/first_year_students.ps1"
    Write-Host "Downloading and running orchestrator..." -ForegroundColor Green
    $orchestratorScript = Invoke-WebRequest -Uri $orchestratorUrl -UseBasicParsing
    Invoke-Expression $orchestratorScript.Content
}
catch {
    Write-Host "Failed to run orchestrator: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please visit: https://pythonsupport.dtu.dk/install/windows/automated-error.html" -ForegroundColor Yellow
    Write-Host "Or contact: pythonsupport@dtu.dk" -ForegroundColor Yellow
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
