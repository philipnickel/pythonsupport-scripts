
# Function to refresh environment variables in the current session
function Refresh-Env {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
}

# Add Miniconda to PATH environment variable
function Add-CondaToPath {
    $minicondaPath = "$env:USERPROFILE\Miniconda3\Scripts"
    if (-not ($env:Path -contains $minicondaPath)) {
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$minicondaPath", [System.EnvironmentVariableTarget]::User)
    }
}

# Script by Python Installation Support DTU
Write-Host "This script will install Python along with Visual Studio Code - and everything you need to get started with programming"

Write-Host "This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
Start-Sleep -Seconds 1

# Download the Miniconda installer
$minicondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
$minicondaInstallerPath = "$env:USERPROFILE\Downloads\Miniconda3-latest-Windows-x86_64.exe"

Write-Host "Downloading installer for miniconda..."

Invoke-WebRequest -Uri $minicondaUrl -OutFile $minicondaInstallerPath


Write-Host "Will now install miniconda..."

# Install Miniconda
Start-Process -FilePath $minicondaInstallerPath -ArgumentList "/InstallationType=JustMe /AddToPath=1 /RegisterPython=1 /S /D=$env:USERPROFILE\Miniconda3" -Wait



# Refresh environment variables
# Add-CondaToPath
Refresh-Env
# Activate conda base environment
& "$env:USERPROFILE\Miniconda3\Scripts\activate"

# Install the GUI (Anaconda Navigator)
conda install anaconda-navigator -y

# Ensure version of Python
conda install python=3.11 -y 

# Install packages
conda install -c conda-forge dtumathtools uncertainties -y

# Download the VS Code installer
$vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
$vscodeInstallerPath = "$env:USERPROFILE\Downloads\vscode-installer.exe"

Write-Host "Downloading installer for VsCode..."

Invoke-WebRequest -Uri $vscodeUrl -OutFile $vscodeInstallerPath

Write-Host "installing VsCode..."

# Install VS Code
Start-Process -FilePath $vscodeInstallerPath -ArgumentList "/verysilent /norestart /mergetasks=!runcode" -Wait 


# Refresh environment variables
Refresh-Env



Write-Host "Installing extensions for VsCode"

# Install VS Code extensions
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter
code --install-extension tomoki1207.pdf

Write-Host "Script finished"
