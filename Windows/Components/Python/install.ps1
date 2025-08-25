# @doc
# @name: Python Component Installer
# @description: Installs Python via Miniforge with essential packages for data science and academic work
# @category: Python
# @requires: Windows 10/11, Internet connection, PowerShell 5.1+
# @usage: . .\install.ps1
# @example: $env:PYTHON_VERSION_PS="3.11"; . .\install.ps1
# @notes: Uses master utility system for consistent error handling and logging. Downloads and installs Miniforge directly from GitHub releases. Supports multiple Python versions via PYTHON_VERSION_PS environment variable. Creates conda environments and installs essential data science packages.
# @author: Python Support Team
# @version: 2024-12-19
# @/doc

# Load master utilities
try {
    $masterUtilsUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Shared/master_utils.ps1"
    $masterUtilsScript = Invoke-WebRequest -Uri $masterUtilsUrl -UseBasicParsing
    & ([ScriptBlock]::Create($masterUtilsScript.Content))
}
catch {
    Write-Error "Failed to load master utilities: $($_.Exception.Message)"
    exit 1
}

Write-LogInfo "Python (Miniforge) installation"
Write-LogInfo "Starting installation process..."

# Check system requirements
Test-SystemRequirements
Test-AllDependencies

# Set execution policy to allow script execution
Set-ExecutionPolicySafe

# Check if conda is already installed
Write-LogInfo "Checking for existing conda installation..."
$condaPaths = @(
    "$env:USERPROFILE\miniforge3\Scripts\conda.exe",
    "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
    "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
    "$env:ProgramData\miniforge3\Scripts\conda.exe",
    "$env:ProgramData\miniconda3\Scripts\conda.exe",
    "$env:ProgramData\anaconda3\Scripts\conda.exe"
)

$condaFound = $false
foreach ($path in $condaPaths) {
    if (Test-Path $path) {
        Write-LogSuccess "Found existing conda installation at: $path"
        $env:PATH = "$(Split-Path $path -Parent);$env:PATH"
        $condaFound = $true
        break
    }
}

if (-not $condaFound) {
    Write-LogInfo "No existing conda installation found, installing Miniforge..."
    
    # Download Miniforge installer
    $miniforgeUrl = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe"
    $installerPath = Join-Path $env:TEMP "Miniforge3-Windows-x86_64.exe"
    
    Write-LogInfo "Downloading Miniforge installer..."
    try {
        Invoke-WebRequest -Uri $miniforgeUrl -OutFile $installerPath -UseBasicParsing
        Check-ExitCode "Failed to download Miniforge installer"
    }
    catch {
        Write-LogError "Failed to download Miniforge: $($_.Exception.Message)"
        Exit-Message
    }
    
    # Install Miniforge silently
    Write-LogInfo "Installing Miniforge..."
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/S /D=$env:USERPROFILE\miniforge3" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-LogError "Miniforge installation failed with exit code: $($process.ExitCode)"
            Exit-Message
        }
    }
    catch {
        Write-LogError "Failed to install Miniforge: $($_.Exception.Message)"
        Exit-Message
    }
    
    # Clean up installer
    if (Test-Path $installerPath) {
        Remove-Item $installerPath -Force
    }
    
    # Add Miniforge to PATH
    $miniforgePath = "$env:USERPROFILE\miniforge3\Scripts"
    Add-ToPath $miniforgePath
    $env:PATH = "$miniforgePath;$env:PATH"
    
    Write-LogSuccess "Miniforge installed successfully"
}
else {
    Write-LogSuccess "Using existing conda installation"
}

# Initialize conda
Write-LogInfo "Initializing conda..."
try {
    # Initialize conda for PowerShell
    conda init powershell
    Check-ExitCode "Failed to initialize conda for PowerShell"
    
    # Initialize conda for Command Prompt
    conda init cmd.exe
    Check-ExitCode "Failed to initialize conda for Command Prompt"
    
    # Reload environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}
catch {
    Write-LogError "Failed to initialize conda: $($_.Exception.Message)"
    Exit-Message
}

# Disable anaconda usage tracking
Write-LogInfo "Disabling anaconda usage tracking..."
try {
    conda config --set anaconda_anon_usage off
}
catch {
    Write-LogWarning "Failed to disable anaconda usage tracking (non-critical)"
}

# Show conda installation location
Write-LogInfo "Conda installation location:"
try {
    conda info --base
    Check-ExitCode "Failed to get conda base directory"
}
catch {
    Write-LogError "Failed to get conda base directory: $($_.Exception.Message)"
    Exit-Message
}

# Configure conda channels (conda-forge only)
Write-LogInfo "Configuring conda channels..."
try {
    # Remove all existing channels
    conda config --remove-key channels 2>$null
    Check-ExitCode "Failed to remove existing channels"
    
    # Add conda-forge channel
    conda config --add channels conda-forge
    Check-ExitCode "Failed to add conda-forge channel"
    
    # Set channel priority to strict
    conda config --set channel_priority strict
    Check-ExitCode "Failed to set channel priority"
    
    Write-LogSuccess "Conda channels configured successfully"
}
catch {
    Write-LogError "Failed to configure conda channels: $($_.Exception.Message)"
    Exit-Message
}

# Update conda
Write-LogInfo "Updating conda..."
try {
    conda update conda -y
    Check-ExitCode "Failed to update conda"
}
catch {
    Write-LogWarning "Failed to update conda (non-critical): $($_.Exception.Message)"
}

Write-LogSuccess "Python (Miniforge) installation completed successfully!"
