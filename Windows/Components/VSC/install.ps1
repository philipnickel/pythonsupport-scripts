# @doc
# @name: VSCode Installation
# @description: Installs Visual Studio Code on Windows with Python extension setup
# @category: IDE
# @usage: . .\install.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Downloads and installs VSCode directly from Microsoft. Configures CLI access and installs Python extension.
# @/doc

Write-Host "Installing Visual Studio Code"

# Set execution policy to allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

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
    
    # Download VSCode installer
    $vscodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $installerPath = Join-Path $env:TEMP "VSCodeUserSetup-x64.exe"
    
    Write-Host "Downloading VSCode installer..."
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $installerPath -UseBasicParsing
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to download VSCode installer"
            exit 1
        }
    }
    catch {
        Write-Host "Failed to download VSCode: $($_.Exception.Message)"
        exit 1
    }
    
    # Install VSCode silently
    Write-Host "Installing VSCode..."
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /TASKS=addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "VSCode installation failed with exit code: $($process.ExitCode)"
            exit 1
        }
    }
    catch {
        Write-Host "Failed to install VSCode: $($_.Exception.Message)"
        exit 1
    }
    
    # Clean up installer
    if (Test-Path $installerPath) {
        Remove-Item $installerPath -Force
    }
    
    Write-Host "VSCode installed successfully"
}
else {
    Write-Host "Using existing VSCode installation"
}

# Add VSCode to PATH for current session (like macOS approach)
$vscodeBinPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
$vscodeExePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"

# Simple direct PATH export for current session
if (Test-Path $vscodeBinPath) {
    $env:PATH = "$vscodeBinPath;$env:PATH"
    Write-Host "Added VSCode to current session PATH: $vscodeBinPath"
}
elseif (Test-Path $vscodeExePath) {
    $vscodeDir = Split-Path $vscodeExePath -Parent
    $env:PATH = "$vscodeDir;$env:PATH"
    Write-Host "Added VSCode to current session PATH: $vscodeDir"
}
else {
    Write-Host "VSCode not found in expected locations"
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
