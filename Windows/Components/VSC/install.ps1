# @doc
# @name: VSCode Installation
# @description: Installs Visual Studio Code on Windows with Python extension setup
# @category: IDE
# @usage: . .\install.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Downloads and installs VSCode directly from Microsoft. Configures CLI access and installs Python extension.
# @/doc

Write-Host "Installing Visual Studio Code"


# Check if VSCode is already installed
Write-Host "Checking for existing VSCode installation..."
$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles(x86)\Microsoft VS Code\Code.exe"
)

$vscodeFound = $false
foreach ($path in $vscodePaths) {
    if (Test-Path $path) {
        Write-Host "Found existing VSCode installation at: $path"
        $vscodeFound = $true
        break
    }
}

if (-not $vscodeFound) {
    Write-Host "No existing VSCode installation found, installing VSCode..."
    
    # Download VSCode zip package (faster than installer)
    $vscodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive"
    $zipPath = Join-Path $env:TEMP "VSCode-win32-x64.zip"
    $extractPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    
    Write-Host "Downloading VSCode zip package..."
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $zipPath -UseBasicParsing
        Write-Host "VSCode zip downloaded successfully"
    }
    catch {
        Write-Host "Failed to download VSCode: $($_.Exception.Message)"
        exit 1
    }
    
    # Extract VSCode
    Write-Host "Extracting VSCode..."
    try {
        # Remove existing installation if present
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
        
        # Create directory and extract
        New-Item -Path $extractPath -ItemType Directory -Force | Out-Null
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        Write-Host "VSCode extracted successfully"
    }
    catch {
        Write-Host "Failed to extract VSCode: $($_.Exception.Message)"
        exit 1
    }
    
    # Clean up zip file
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Write-Host "VSCode installed successfully"
}
else {
    Write-Host "Using existing VSCode installation"
}

# Add VSCode to PATH for current session
$vscodeInstallPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
$vscodeBinPath = "$vscodeInstallPath\bin"
$vscodeExePath = "$vscodeInstallPath\Code.exe"

# Add to current session PATH
if (Test-Path $vscodeBinPath) {
    $env:PATH = "$vscodeBinPath;$env:PATH"
    Write-Host "Added VSCode bin to current session PATH: $vscodeBinPath"
} elseif (Test-Path $vscodeExePath) {
    $env:PATH = "$vscodeInstallPath;$env:PATH"
    Write-Host "Added VSCode to current session PATH: $vscodeInstallPath"
} else {
    Write-Host "VSCode not found in expected locations"
}

# Add VSCode to user PATH permanently
try {
    $currentUserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (Test-Path $vscodeBinPath -and $currentUserPath -notlike "*$vscodeBinPath*") {
        $newUserPath = "$currentUserPath;$vscodeBinPath"
        [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
        Write-Host "Added VSCode bin to user PATH permanently"
    } elseif (Test-Path $vscodeExePath -and $currentUserPath -notlike "*$vscodeInstallPath*") {
        $newUserPath = "$currentUserPath;$vscodeInstallPath"
        [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
        Write-Host "Added VSCode to user PATH permanently"
    }
} catch {
    Write-Host "Warning: Could not add VSCode to permanent PATH: $($_.Exception.Message)"
}



# Install Python extension
Write-Host "Installing Python extension for VSCode..."
try {
    & code --install-extension ms-python.python
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Python extension installed successfully"
    }
    else {
        Write-Host "Failed to install Python extension (non-critical)"
    }
}
catch {
    Write-Host "Failed to install Python extension: $($_.Exception.Message)"
}

Write-Host "Visual Studio Code installation completed!"
