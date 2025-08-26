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
        exit 1
    }
    
    # Install Miniforge silently
    Write-Host "Installing Miniforge..."
    Write-Host "Installer path: $installerPath"
    Write-Host "Installation directory: $env:USERPROFILE\miniforge3"
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/S /D=$env:USERPROFILE\miniforge3" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "Miniforge installation failed with exit code: $($process.ExitCode)"
            exit 1
        }
        Write-Host "Miniforge installation completed with exit code: $($process.ExitCode)"
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

# Skip conda update - unnecessary and slow
Write-Host "Skipping conda update for performance..."

Write-Host "Python (Miniforge) installation completed successfully!"
