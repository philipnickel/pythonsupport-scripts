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
    
    # Detect system architecture and download appropriate VSCode installer
    # Use the same approach as legacy scripts for better compatibility
    Write-Host "Detecting system architecture..."
    
        # Get architecture using environment variable (Windows equivalent of uname -m)
    $architecture = $env:PROCESSOR_ARCHITECTURE
    Write-Host "Architecture: $architecture"
    
    # Simple architecture detection (like uname -m)
    switch($architecture) {
        "ARM64" { 
            $vscodeUrl = "https://update.code.visualstudio.com/latest/win32-arm64-user/stable"
            $installerPath = Join-Path $env:TEMP "VSCodeUserSetup-arm64.exe"
            Write-Host "Using ARM64 VSCode installer"
        }
        default { 
            $vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
            $installerPath = Join-Path $env:TEMP "VSCodeUserSetup-x64.exe"
            Write-Host "Using x64 VSCode installer"
        }
    }
    
    Write-Host "Downloading VSCode installer..."
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $installerPath -UseBasicParsing
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to download VSCode installer"
            throw "Failed to download VSCode installer"
        }
    }
    catch {
        Write-Host "Failed to download VSCode: $($_.Exception.Message)"
        throw "Failed to download VSCode"
    }
    
    # Install VSCode silently
    Write-Host "Installing VSCode..."
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /TASKS=addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "VSCode installation failed with exit code: $($process.ExitCode)"
            throw "VSCode installation failed"
        }
    }
    catch {
        Write-Host "Failed to install VSCode: $($_.Exception.Message)"
        throw "Failed to install VSCode"
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
# VSCode installs to the same location regardless of architecture
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



# Install extensions
Write-Host "Installing VSCode extensions..."

# Define extensions to install (matching macOS)
$extensions = @(
    "ms-python.python",
    "ms-toolsai.jupyter", 
    #"tomoki1207.pdf"
)

$failedExtensions = @()

foreach ($extension in $extensions) {
    Write-Host "Installing $extension..."
    try {
        & code --install-extension $extension
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully installed $extension"
        } else {
            Write-Host "Failed to install $extension"
            $failedExtensions += $extension
        }
    }
    catch {
        Write-Host "Failed to install $extension : $($_.Exception.Message)"
        $failedExtensions += $extension
    }
}

# Report results and log to Piwik if available
if ($failedExtensions.Count -eq 0) {
    Write-Host "All VSCode extensions installed successfully"
    if (Get-Command "Piwik-Log" -ErrorAction SilentlyContinue) {
        Piwik-Log 40  # VS Code Extensions success
    }
} elseif ($failedExtensions.Count -eq $extensions.Count) {
    Write-Host "All extension installations failed"
    if (Get-Command "Piwik-Log" -ErrorAction SilentlyContinue) {
        Piwik-Log 41  # VS Code Extensions fail
    }
} else {
    Write-Host "Some extensions failed to install: $($failedExtensions -join ', ')"
    Write-Host "Installation will continue (extensions can be installed manually later)"
    if (Get-Command "Piwik-Log" -ErrorAction SilentlyContinue) {
        Piwik-Log 40  # VS Code Extensions success (partial)
    }
}

Write-Host "Visual Studio Code installation completed!"
