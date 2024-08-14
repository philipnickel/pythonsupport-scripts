
# check for env variable PYTHONVERSIONPS 
# if it isn't set set it to 3.11

if (-not $env:PYTHON_VERSION_PS) {
    $env:PYTHON_VERSION_PS = "3.11"
}



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

# Check if Miniconda or Anaconda is already installed
$minicondaPath1 = "$env:USERPROFILE\Miniconda3"
$minicondaPath2 = "C:\ProgramData\Miniconda3"
$anacondaPath1 = "$env:USERPROFILE\Anaconda3"
$anacondaPath2 = "C:\ProgramData\Anaconda3"

if ((Test-Path $minicondaPath1) -or (Test-Path $minicondaPath2) -or (Test-Path $anacondaPath1) -or (Test-Path $anacondaPath2)) {
    Write-Host "Miniconda or Anaconda is already installed. Skipping Miniconda installation."
    Write-Host "If you wish to install Miniconda using this script, please uninstall the existing Anaconda/Miniconda installation and run the script again."
} else {
    # Script by Python Installation Support DTU
    Write-Host "This script will install Python along with Visual Studio Code - and everything you need to get started with programming"
    Write-Host "This script will take a while to run, please be patient, and don't close PowerShell before it says 'script finished'."
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
    Write-Host "Updating Python to version $env:PYTHON_VERSION_PS..."
    & "$env:USERPROFILE\Miniconda3\condabin\conda.bat" install python=$env:PYTHON_VERSION_PS -y
    if ($?) {
        Write-Host "Python updated version installed."
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
}
Write-Host "Script finished. You may now close the terminal."
