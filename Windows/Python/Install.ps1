
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
    Write-Output "Oh no! Something went wrong."
    Write-Output "Please visit the following web page for more info:"
    Write-Output ""
    Write-Output "   https://pythonsupport.dtu.dk/install/windows/automated-error.html "
    Write-Output ""
    Write-Output "or contact the Python Support Team:"
    Write-Output ""
    Write-Output "   pythonsupport@dtu.dk"
    Write-Output ""
    Write-Output "Or visit us during our office hours"
    exit 1
}

# Check and set execution policy if necessary
$executionPolicies = Get-ExecutionPolicy -List
$currentUserPolicy = $executionPolicies | Where-Object { $_.Scope -eq "CurrentUser" } | Select-Object -ExpandProperty ExecutionPolicy
$localMachinePolicy = $executionPolicies | Where-Object { $_.Scope -eq "LocalMachine" } | Select-Object -ExpandProperty ExecutionPolicy

if ($currentUserPolicy -ne "RemoteSigned" -and $currentUserPolicy -ne "Bypass" -and $currentUserPolicy -ne "Unrestricted" -and
    $localMachinePolicy -ne "RemoteSigned" -and $localMachinePolicy -ne "Unrestricted" -and $localMachinePolicy -ne "Bypass") {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

# Check if Miniconda or Anaconda is already installed
$minicondaPath1 = "$env:USERPROFILE\Miniconda3"
$minicondaPath2 = "C:\ProgramData\Miniconda3"
$anacondaPath1 = "$env:USERPROFILE\Anaconda3"
$anacondaPath2 = "C:\ProgramData\Anaconda3"

if ((Test-Path $minicondaPath1) -or (Test-Path $minicondaPath2) -or (Test-Path $anacondaPath1) -or (Test-Path $anacondaPath2)) {
    Write-Output "Miniconda or Anaconda is already installed. Skipping Miniconda installation."
    Write-Output "If you wish to install Miniconda using this script, please uninstall the existing Anaconda/Miniconda installation and run the script again."
} else {
    # Script by Python Installation Support DTU
    Write-Output "This script will install Python along with Visual Studio Code - and everything you need to get started with programming"
    Write-Output "This script will take a while to run, please be patient, and don't close PowerShell before it says 'script finished'."
    Start-Sleep -Seconds 3

    # Download the Miniconda installer
    $minicondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
    $minicondaInstallerPath = "$env:USERPROFILE\Downloads\Miniconda3-latest-Windows-x86_64.exe"

    Write-Output "Downloading installer for Miniconda..."
    Invoke-WebRequest -Uri $minicondaUrl -OutFile $minicondaInstallerPath
    if ($?) {
        Write-Output "Miniconda installer downloaded."
    } else {
        Exit-Message
    }

    Write-Output "Will now install Miniconda..."
    # Install Miniconda
    Start-Process -FilePath $minicondaInstallerPath -ArgumentList "/InstallationType=JustMe /RegisterPython=1 /S /D=$env:USERPROFILE\Miniconda3" -Wait
    if ($?) {
        Write-Output "Miniconda installed."
    } else {
        Exit-Message
    }

    # Add miniconda to PATH and refresh environment variables
    function Add-CondaToPath {
        if (Test-Path "$env:USERPROFILE\Miniconda3\condabin") {
            $condaPath = "$env:USERPROFILE\Miniconda3\condabin"
        } elseif (Test-Path "C:\ProgramData\Miniconda3\condabin") {
            $condaPath = "C:\ProgramData\Miniconda3\condabin"
        } else {
            Write-Output "Miniconda is not installed."
            Exit-Message
        }

        if (-not ($env:Path -contains $condaPath)) {
            [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$condaPath", [System.EnvironmentVariableTarget]::User)
        }
    }

    Add-CondaToPath
    if ($?) {
        Refresh-Env
        Write-Output "Environment variables refreshed."
    } else {
        Exit-Message
    }

    # Re-import the updated PATH for the current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

    # Activate conda base environment
    & "$env:USERPROFILE\Miniconda3\condabin\conda.bat" activate
    if ($?) {
        Write-Output "Conda base environment activated."
    } else {
        Exit-Message
    }

    # Initialize conda
    & "$env:USERPROFILE\Miniconda3\condabin\conda.bat" init
    if ($?) {
        Write-Output "Conda initialized."
    } else {
        Exit-Message
    }

    # Ensuring correct channels are set
    Write-Output "Removing defaults channel (due to licensing problems)"
    & "$env:USERPROFILE\Miniconda3\condabin\conda.bat" config --add channels conda-forge
    if (-not $?) {
        Exit-Message
    }
    & "$env:USERPROFILE\Miniconda3\condabin\conda.bat" config --remove channels defaults
    if (-not $?) {
        Exit-Message
    }

    # Ensure version of Python
    Write-Output "Updating Python to version $env:PYTHON_VERSION_PS..."
    & "$env:USERPROFILE\Miniconda3\condabin\conda.bat" install python=$env:PYTHON_VERSION_PS -y
    if ($?) {
        Write-Output "Python updated version installed."
    } else {
        Exit-Message
    }

    # We will not install the Anaconda GUI
    # There may be license issues due to DTU being
    # a rather big institution. So our installation guides
    # Will be pre-cautious here, and remove the defaults channels.
        # Install packages
        
    & "$env:USERPROFILE\Miniconda3\condabin\conda.bat" install dtumathtools pandas scipy statsmodels uncertainties -y
    if ($?) {
        Write-Output "Additional packages installed."
    } else {
        Exit-Message
    }
}

Write-Output "Installed conda and related packages for 1st year at DTU!"
