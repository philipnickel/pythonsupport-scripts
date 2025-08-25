# @doc
# @name: VSCode Installation
# @description: Installs Visual Studio Code on Windows with Python extension setup
# @category: IDE
# @usage: . .\install.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Uses master utility system for consistent error handling and logging. Downloads and installs VSCode directly from Microsoft. Configures CLI access and installs Python extension.
# @/doc

# Load master utilities
try {
    $masterUtilsUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Shared/master_utils.ps1"
    Invoke-Expression (Invoke-WebRequest -Uri $masterUtilsUrl -UseBasicParsing).Content
}
catch {
    Write-LogError "Failed to load master utilities: $($_.Exception.Message)"
    Exit-Message
}

Write-LogInfo "Installing Visual Studio Code"

# Check system requirements
Test-SystemRequirements
Test-AllDependencies

# Set execution policy to allow script execution
Set-ExecutionPolicySafe

# Check if VSCode is already installed
Write-LogInfo "Checking for existing VSCode installation..."
$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles(x86)\Microsoft VS Code\Code.exe"
)

$vscodeFound = $false
foreach ($path in $vscodePaths) {
    if (Test-Path $path) {
        Write-LogSuccess "Found existing VSCode installation at: $path"
        $vscodeFound = $true
        break
    }
}

if (-not $vscodeFound) {
    Write-LogInfo "No existing VSCode installation found, installing VSCode..."
    
    # Download VSCode installer
    $vscodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $installerPath = Join-Path $env:TEMP "VSCodeUserSetup-x64.exe"
    
    Write-LogInfo "Downloading VSCode installer..."
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $installerPath -UseBasicParsing
        Check-ExitCode "Failed to download VSCode installer"
    }
    catch {
        Write-LogError "Failed to download VSCode: $($_.Exception.Message)"
        Exit-Message
    }
    
    # Install VSCode silently
    Write-LogInfo "Installing VSCode..."
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /TASKS=addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-LogError "VSCode installation failed with exit code: $($process.ExitCode)"
            Exit-Message
        }
    }
    catch {
        Write-LogError "Failed to install VSCode: $($_.Exception.Message)"
        Exit-Message
    }
    
    # Clean up installer
    if (Test-Path $installerPath) {
        Remove-Item $installerPath -Force
    }
    
    Write-LogSuccess "VSCode installed successfully"
}
else {
    Write-LogSuccess "Using existing VSCode installation"
}

# Add VSCode to PATH if not already there
$vscodeBinPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
if ($env:PATH -notlike "*$vscodeBinPath*") {
    Add-ToPath $vscodeBinPath
    $env:PATH = "$vscodeBinPath;$env:PATH"
}

# Test if VSCode CLI is working
Write-LogInfo "Testing VSCode CLI..."
try {
    $codeVersion = & code --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "VSCode CLI is working"
        Write-LogInfo "VSCode version: $($codeVersion[0])"
    }
    else {
        Write-LogWarning "VSCode CLI not working, attempting to fix..."
        
        # Try to add VSCode to PATH manually
        $vscodeExePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
        if (Test-Path $vscodeExePath) {
            $env:PATH = "$(Split-Path $vscodeExePath -Parent);$env:PATH"
            
            # Test again
            $codeVersion = & code --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-LogSuccess "VSCode CLI fixed and working"
                Write-LogInfo "VSCode version: $($codeVersion[0])"
            }
            else {
                Write-LogWarning "VSCode CLI still not working, but installation completed"
            }
        }
    }
}
catch {
    Write-LogWarning "Failed to test VSCode CLI: $($_.Exception.Message)"
}

# Install Python extension
Write-LogInfo "Installing Python extension for VSCode..."
try {
    & code --install-extension ms-python.python
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "Python extension installed successfully"
    }
    else {
        Write-LogWarning "Failed to install Python extension (non-critical)"
    }
}
catch {
    Write-LogWarning "Failed to install Python extension: $($_.Exception.Message)"
}

# Install additional useful extensions
$extensions = @(
    "ms-python.pylint",
    "ms-python.black-formatter",
    "ms-python.isort",
    "ms-vscode.vscode-json"
)

foreach ($extension in $extensions) {
    Write-LogInfo "Installing extension: $extension"
    try {
        & code --install-extension $extension
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "Extension $extension installed successfully"
        }
        else {
            Write-LogWarning "Failed to install extension $extension (non-critical)"
        }
    }
    catch {
        Write-LogWarning "Failed to install extension $extension : $($_.Exception.Message)"
    }
}

Write-LogSuccess "Visual Studio Code installation completed!"
