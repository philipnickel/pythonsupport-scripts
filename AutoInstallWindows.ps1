
# Script by Python Installation Support DTU
Write-Host "This script will install Python along with Visual Studio Code - and everything you need to get started with programming"

Write-Host "This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
Start-Sleep -Seconds 1

# Download the Miniconda installer
$minicondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
$minicondaInstallerPath = "$env:USERPROFILE\Downloads\Miniconda3-latest-Windows-x86_64.exe"
Invoke-WebRequest -Uri $minicondaUrl -OutFile $minicondaInstallerPath

# Install Miniconda
Start-Process -FilePath $minicondaInstallerPath -ArgumentList "/InstallationType=JustMe /RegisterPython=1 /D=$env:USERPROFILE\Miniconda3" -Wait

# Refresh environment variables
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
Invoke-WebRequest -Uri $vscodeUrl -OutFile $vscodeInstallerPath

# Install VS Code
Start-Process -FilePath $vscodeInstallerPath -ArgumentList "/norestart" -Wait

# Refresh environment variables again
& "$env:USERPROFILE\Miniconda3\Scripts\activate"

# Install VS Code extensions
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter
code --install-extension tomoki1207.pdf

Write-Host "Script finished"
