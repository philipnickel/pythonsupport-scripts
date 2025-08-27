# @doc
# @name: Python Component Installer
# @description: Installs Python via Miniforge with essential packages for data science and academic work
# @category: Python
# @requires: Windows 10/11, Internet connection, PowerShell 5.1+
# @usage: . .\install.ps1
# @example: $env:PYTHON_VERSION_PS="3.11"; . .\install.ps1
# @notes: Downloads and installs Miniforge directly from GitHub releases. Supports multiple Python versions via PYTHON_VERSION_PS environment variable.
# @author: Python Support Team
# @version: 2024-12-19
# @/doc

Write-Host "Python (Miniforge) installation"
Write-Host "Starting installation process..."


# Check if conda is already installed
Write-Host "Checking for existing conda installation..."
$condaPaths = @(
    "$env:USERPROFILE\miniforge3\Scripts\conda.exe",
    "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
    "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
    "$env:ProgramData\miniforge3\Scripts\conda.exe",
    "$env:ProgramData\miniconda3\Scripts\conda.exe",
    "$env:ProgramData\anaconda3\Scripts\conda.exe"
)

$condaFound = $false
$existingCondaPath = $null
foreach ($path in $condaPaths) {
    if (Test-Path $path) {
        Write-Host "Found existing conda installation at: $path"
        $existingCondaPath = $path
        $condaFound = $true
        break
    }
}

if ($condaFound) {
    Write-Host "Existing conda installation detected at: $existingCondaPath"
    
    # Show native Windows popup asking for manual uninstall (skip in CI)
    if ($env:PIS_ENV -ne "CI") {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show(
                "An existing conda installation was found at:`n$existingCondaPath`n`nPlease uninstall it manually through Windows Settings (Add or Remove Programs) and run this installer again.`n`nInstallation will now exit.",
                "DTU Python Setup - Manual Action Required",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        } catch {
            Write-Host "Could not show GUI dialog, showing terminal message instead"
        }
    }
    
    Write-Host ""
    Write-Host "❌ INSTALLATION ABORTED" -ForegroundColor Red
    Write-Host "An existing conda installation was found at: $existingCondaPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To continue with this installer:" -ForegroundColor White
    Write-Host "1. Open Windows Settings" -ForegroundColor White
    Write-Host "2. Go to 'Apps' or 'Add or Remove Programs'" -ForegroundColor White
    Write-Host "3. Find and uninstall the existing conda installation" -ForegroundColor White
    Write-Host "4. Run this installer again" -ForegroundColor White
    Write-Host ""
    Write-Host "For help, visit: https://pythonsupport.dtu.dk" -ForegroundColor Cyan
    
    exit 1
}

if (-not $condaFound) {
    Write-Host "No existing conda installation found, installing Miniforge..."
    
    # Download Miniforge installer
    $miniforgeUrl = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe"
    $installerPath = Join-Path $env:TEMP "Miniforge3-Windows-x86_64.exe"
    
    Write-Host "Downloading Miniforge installer..."
    Write-Host "URL: $miniforgeUrl"
    Write-Host "Target: $installerPath"
    try {
        $response = Invoke-WebRequest -Uri $miniforgeUrl -OutFile $installerPath -UseBasicParsing -Verbose
        Write-Host "Download completed. File size: $((Get-Item $installerPath).Length) bytes"
    }
    catch {
        Write-Host "Failed to download Miniforge: $($_.Exception.Message)"
        Write-Host "Exception type: $($_.Exception.GetType().Name)"
        Write-Host "Status code: $($_.Exception.Response.StatusCode)"
        throw "Failed to download Miniforge"
    }
    
    # Install Miniforge silently
    Write-Host "Installing Miniforge..."
    Write-Host "Installer path: $installerPath"
    Write-Host "Installation directory: $env:USERPROFILE\miniforge3"
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/S /D=$env:USERPROFILE\miniforge3" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "Miniforge installation failed with exit code: $($process.ExitCode)"
            throw "Miniforge installation failed"
        }
        Write-Host "Miniforge installation completed with exit code: $($process.ExitCode)"
    }
    catch {
        Write-Host "Failed to install Miniforge: $($_.Exception.Message)"
        throw "Failed to install Miniforge"
    }
    
    # Clean up installer
    if (Test-Path $installerPath) {
        Remove-Item $installerPath -Force
    }
    
    # Add Miniforge to PATH
    $miniforgePath = "$env:USERPROFILE\miniforge3\Scripts"
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$miniforgePath*") {
        $newPath = "$currentPath;$miniforgePath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    }
    $env:PATH = "$miniforgePath;$env:PATH"
    
    Write-Host "Miniforge installed successfully"
}
else {
    Write-Host "Using existing conda installation"
}

# Initialize conda
Write-Host "Initializing conda..."
try {
    # Initialize conda for PowerShell
    conda init powershell
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to initialize conda for PowerShell"
        throw "Failed to initialize conda for PowerShell"
    }
    
    # Initialize conda for Command Prompt
    conda init cmd.exe
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to initialize conda for Command Prompt"
        throw "Failed to initialize conda for Command Prompt"
    }
    
    # Reload environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}
catch {
    Write-Host "Failed to initialize conda: $($_.Exception.Message)"
    throw "Failed to initialize conda"
}



# Show conda installation location
Write-Host "Conda installation location:"
try {
    conda info --base
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to get conda base directory"
        throw "Failed to get conda base directory"
    }
}
catch {
    Write-Host "Failed to get conda base directory: $($_.Exception.Message)"
    throw "Failed to get conda base directory"
}



# Disable conda error reporting to prevent interactive prompts
Write-Host "Configuring conda to disable error reporting..."
try {
    conda config --set report_errors false
    Write-Host "Conda error reporting disabled"
}
catch {
    Write-Host "Failed to disable conda error reporting (non-critical)"
}

# Initialize conda for PowerShell
Write-Host "Initializing conda for PowerShell..."
try {
    conda init powershell
    Write-Host "Conda initialized for PowerShell successfully"
}
catch {
    Write-Host "Failed to initialize conda for PowerShell: $($_.Exception.Message)"
    exit 1
}

# Skip conda update for performance - not needed for fresh installs
Write-Host "Skipping conda update for performance (not needed for fresh installs)..."

Write-Host "Python (Miniforge) installation completed successfully!"
