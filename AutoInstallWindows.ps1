
# Function to refresh environment variables in the current session
function Refresh-Env {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
}

# Add Anaconda to PATH environment variable
function Add-CondaToPath {
    if (Test-Path "$env:USERPROFILE\Anaconda3\condabin") {
        $condaPath = "$env:USERPROFILE\Anaconda3\condabin"
    } elseif (Test-Path "C:\ProgramData\Anaconda3\condabin") {
        $condaPath = "C:\ProgramData\Anaconda3\condabin"
    } else {
        Write-Host "Anaconda is not installed."
        return
    }

    if (-not ($env:Path -contains $condaPath)) {
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$condaPath", [System.EnvironmentVariableTarget]::User)
    }
}

# Script by Python Installation Support DTU
Write-Host "This script will install Python along with Visual Studio Code - and everything you need to get started with programming"

Write-Host "This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
Start-Sleep -Seconds 1

# Download the Miniconda installer
$minicondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
$minicondaInstallerPath = "$env:USERPROFILE\Downloads\Miniconda3-latest-Windows-x86_64.exe"

Write-Host "Downloading installer for Miniconda..."

Invoke-WebRequest -Uri $minicondaUrl -OutFile $minicondaInstallerPath

Write-Host "Will now install Miniconda..."

# Install Miniconda
Start-Process -FilePath $minicondaInstallerPath -ArgumentList "/InstallationType=JustMe /RegisterPython=1 /S /D=$env:USERPROFILE\Miniconda3" -Wait

# Add Anaconda to PATH and refresh environment variables
Add-CondaToPath
Refresh-Env

# Initialize conda
conda init

# Activate conda base environment
& "$env:USERPROFILE\Miniconda3\condabin\conda.bat" activate

# Install the GUI (Anaconda Navigator)
conda install anaconda-navigator -y

# Ensure version of Python
conda install python=3.11 -y 

# Install packages
conda install -c conda-forge dtumathtools uncertainties -y

# Download the VS Code installer
$vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
$vscodeInstallerPath = "$env:USERPROFILE\Downloads\vscode-installer.exe"

Write-Host "Downloading installer for Visual Studio Code..."

Invoke-WebRequest -Uri $vscodeUrl -OutFile $vscodeInstallerPath

Write-Host "Installing Visual Studio Code..."

# Install VS Code
Start-Process -FilePath $vscodeInstallerPath -ArgumentList "/verysilent /norestart /mergetasks=!runcode" -Wait 

# Refresh environment variables
Refresh-Env

Write-Host "Installing extensions for Visual Studio Code"

# Install VS Code extensions
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter
code --install-extension tomoki1207.pdf

Write-Host "Script finished"
