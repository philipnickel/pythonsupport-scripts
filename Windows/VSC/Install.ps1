
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
$executionPolicies = Get-ExecutionPolicy -List
$currentUserPolicy = $executionPolicies | Where-Object { $_.Scope -eq "CurrentUser" } | Select-Object -ExpandProperty ExecutionPolicy
$localMachinePolicy = $executionPolicies | Where-Object { $_.Scope -eq "LocalMachine" } | Select-Object -ExpandProperty ExecutionPolicy

if ($currentUserPolicy -ne "RemoteSigned" -and $currentUserPolicy -ne "Unrestricted" -and
    $localMachinePolicy -ne "RemoteSigned" -and $localMachinePolicy -ne "Unrestricted") {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    if ($?) {
        Write-Host "Execution policy set to RemoteSigned for CurrentUser."
    } else {
        Exit-Message
    }
} else {
    Write-Host "Execution policy is already set appropriately."
}


# Check if VS Code is already installed
$vscodePath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Microsoft VS Code\Code.exe"
if (Test-Path $vscodePath) {
    Write-Host "Visual Studio Code is already installed. Skipping VS Code installation."
} else {
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

Write-Host "Script finished. You may now close the terminal."
