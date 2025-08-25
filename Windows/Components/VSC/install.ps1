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

# Add VSCode to PATH if not already there
$vscodeBinPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$vscodeBinPath*") {
    $newPath = "$currentPath;$vscodeBinPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "Added VSCode to PATH"
}
$env:PATH = "$vscodeBinPath;$env:PATH"

# Test if VSCode CLI is working
Write-Host "Testing VSCode CLI..."
try {
    $codeVersion = & code --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "VSCode CLI is working"
        Write-Host "VSCode version: $($codeVersion[0])"
    }
    else {
        Write-Host "VSCode CLI not working, attempting to fix..."
        
        # Try to add VSCode to PATH manually
        $vscodeExePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
        if (Test-Path $vscodeExePath) {
            $env:PATH = "$(Split-Path $vscodeExePath -Parent);$env:PATH"
            
            # Test again
            $codeVersion = & code --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "VSCode CLI fixed and working"
                Write-Host "VSCode version: $($codeVersion[0])"
            }
            else {
                Write-Host "VSCode CLI still not working, but installation completed"
            }
        }
    }
}
catch {
    Write-Host "Failed to test VSCode CLI: $($_.Exception.Message)"
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
