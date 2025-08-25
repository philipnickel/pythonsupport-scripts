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

# Set execution policy to allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

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
foreach ($path in $condaPaths) {
    if (Test-Path $path) {
        Write-Host "Found existing conda installation at: $path"
        $env:PATH = "$(Split-Path $path -Parent);$env:PATH"
        $condaFound = $true
        break
    }
}

if (-not $condaFound) {
    Write-Host "No existing conda installation found, installing Miniforge..."
    
    # Download Miniforge installer
    $miniforgeUrl = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe"
    $installerPath = Join-Path $env:TEMP "Miniforge3-Windows-x86_64.exe"
    
    Write-Host "Downloading Miniforge installer..."
    try {
        Invoke-WebRequest -Uri $miniforgeUrl -OutFile $installerPath -UseBasicParsing
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to download Miniforge installer"
            exit 1
        }
    }
    catch {
        Write-Host "Failed to download Miniforge: $($_.Exception.Message)"
        exit 1
    }
    
    # Install Miniforge silently
    Write-Host "Installing Miniforge..."
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/S /D=$env:USERPROFILE\miniforge3" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "Miniforge installation failed with exit code: $($process.ExitCode)"
            exit 1
        }
    }
    catch {
        Write-Host "Failed to install Miniforge: $($_.Exception.Message)"
        exit 1
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
        exit 1
    }
    
    # Initialize conda for Command Prompt
    conda init cmd.exe
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to initialize conda for Command Prompt"
        exit 1
    }
    
    # Reload environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}
catch {
    Write-Host "Failed to initialize conda: $($_.Exception.Message)"
    exit 1
}

# Disable anaconda usage tracking
Write-Host "Disabling anaconda usage tracking..."
try {
    conda config --set anaconda_anon_usage off
}
catch {
    Write-Host "Failed to disable anaconda usage tracking (non-critical)"
}

# Show conda installation location
Write-Host "Conda installation location:"
try {
    conda info --base
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to get conda base directory"
        exit 1
    }
}
catch {
    Write-Host "Failed to get conda base directory: $($_.Exception.Message)"
    exit 1
}

# Configure conda channels (conda-forge only)
Write-Host "Configuring conda channels..."
try {
    # Remove all existing channels
    conda config --remove-key channels 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to remove existing channels"
        exit 1
    }
    
    # Add conda-forge channel
    conda config --add channels conda-forge
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to add conda-forge channel"
        exit 1
    }
    
    # Set channel priority to strict
    conda config --set channel_priority strict
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to set channel priority"
        exit 1
    }
    
    Write-Host "Conda channels configured successfully"
}
catch {
    Write-Host "Failed to configure conda channels: $($_.Exception.Message)"
    exit 1
}

# Update conda
Write-Host "Updating conda..."
try {
    conda update conda -y
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to update conda (non-critical)"
    }
}
catch {
    Write-Host "Failed to update conda (non-critical): $($_.Exception.Message)"
}

Write-Host "Python (Miniforge) installation completed successfully!"
