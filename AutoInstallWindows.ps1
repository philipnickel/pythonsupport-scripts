# Function to refresh environment variables in the current session
function Refresh-Env {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
}

# Function to handle errors and exit
function Exit-Message {
    Write-Host "Oh no! Something went wrong."
    Write-Host "Please try to install manually or contact the Python Support Team:"
    Write-Host "Pythonsupport@dtu.dk"
    Write-Host "Or visit us during our office hours"
    exit 1
}

# Check and set execution policy if necessary
$currentExecutionPolicy = Get-ExecutionPolicy
if ($currentExecutionPolicy -ne "RemoteSigned" -and $currentExecutionPolicy -ne "Unrestricted") {
    set-executionpolicy remotesigned -Force
    if ($?) {
        Write-Host "Execution policy set to remotesigned."
    } else {
        Exit-Message
    }
} else {
    Write-Host "Execution policy is already set to $currentExecutionPolicy."
}

# Add Anaconda to PATH environment variable
function Add-CondaToPath {
    if (Test-Path "$env:USERPROFILE\Miniconda3\condabin") {
        $condaPath = "$env:USERPROFILE\Miniconda3\condabin"
    } elseif (Test-Path "C:\ProgramData\Miniconda3\condabin") {
        $condaPath = "C:\ProgramData\Miniconda3\condabin"
    } else {
        Write-Host "Miniconda is not installed."
        Exit-Message
    }

    if (-not ($env:Path -contains $condaPath)) {
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$condaPath", [System.EnvironmentVariableTarget]::User)
    }
}

# Script by Python Installation Support DTU
Write-Host "This script will install Python along with Visual Studio Code - and everything you need to get started with programming"
Write-Host "This script will take a while to run, please be patient, and don't close your terminal before it says 'script finished'."
Start-Sleep -Seconds 3

# Download the Miniconda installer
$minicondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
$minicondaInstallerPath = "$env:USERPROFILE\Downloads\Miniconda3-latest-Windows-x86_64.exe"

Write-Host "Downloading installer for Miniconda..."
Invoke-WebRequest -Uri $minicondaUrl -OutFile $minicondaInstallerPath
if ($?) {
    Write-Host "Miniconda installer downloaded."
} else {
    Exit-Message
}

Write-Host "Will now install Miniconda..."
# Install Miniconda
Start-Process -FilePath $minicondaInstallerPath -ArgumentList "/InstallationType=JustMe /RegisterPython=1 /S /D=$env:USERPROFILE\Miniconda3" -Wait
if ($?) {
    Write-Host "Miniconda installed."
} else {
    Exit-Message
}

# Add Anaconda to PATH and refresh environment variables
Add-CondaToPath
if ($?) {
    Refresh-Env
    Write-Host "Environment variables refreshed."
} else {
    Exit-Message
}

# Re-import the updated PATH for the current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

# Activate conda base environment
& "$env:USERPROFILE\Miniconda3\condabin\conda.bat" activate
if ($?) {
    Write-Host "Conda base environment activated."
} else {
    Exit-Message
}

# Initialize conda
& "$env:USERPROFILE\Miniconda3\condabin\conda.bat" init
if ($?) {
    Write-Host "Conda initialized."
} else {
    Exit-Message
}

# Ensure version of Python
& "$env:USERPROFILE\Miniconda3\condabin\conda.bat" install python=3.11 -y
if ($?) {
    Write-Host "Python 3.11 installed."
} else {
    Exit-Message
}

# Install the GUI (Anaconda Navigator)
& "$env:USERPROFILE\Miniconda3\condabin\conda.bat" install anaconda-navigator -y
if ($?) {
    Write-Host "Anaconda Navigator installed."
} else {
    Exit-Message
}

# Install packages
& "$env:USERPROFILE\Miniconda3\condabin\conda.bat" install -c conda-forge dtumathtools uncertainties -y
if ($?) {
    Write-Host "Additional packages installed."
} else {
    Exit-Message
}

# Download the VS Code installer
$vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
$vscodeInstallerPath = "$env:USERPROFILE\Downloads\vscode-installer.exe"

Write-Host "Downloading installer for Visual Studio Code..."
Invoke-WebRequest -Uri $vscodeUrl -OutFile $vscodeInstallerPath
if ($?) {
    Write-Host "VS Code installer downloaded."
} else {
    Exit-Message
}

Write-Host "Installing Visual Studio Code..."
# Install VS Code
Start-Process -FilePath $vscodeInstallerPath -ArgumentList "/verysilent /norestart /mergetasks=!runcode" -Wait
if ($?) {
    Write-Host "VS Code installed."
} else {
    Exit-Message
}

# Refresh environment variables
Refresh-Env
if ($?) {
    Write-Host "Environment variables refreshed."
} else {
    Exit-Message
}

# Re-import the updated PATH for the current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

Write-Host "Installing extensions for Visual Studio Code"
# Install VS Code extensions
code --install-extension ms-python.python
if ($?) {
    Write-Host "Python extension installed."
} else {
    Exit-Message
}

code --install-extension ms-toolsai.jupyter
if ($?) {
    Write-Host "Jupyter extension installed."
} else {
    Exit-Message
}

code --install-extension tomoki1207.pdf
if ($?) {
    Write-Host "PDF extension installed."
} else {
    Exit-Message
}

Write-Host "Script finished. You may now close the terminal"
