# @doc
# @name: VS Code Install (Windows)
# @description: Download and install VS Code on Windows
# @category: Core
# @usage: powershell -File Core/VsCode/install/install_windows.ps1
# @requirements: Windows
# @notes: Downloads the architecture-appropriate user installer and installs VS Code.
#   PS_VSCODE_URL may override the installer URL for local testing.
# @/doc

$ErrorActionPreference = "Stop"

$appPath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"
$downloadUrl = $env:PS_VSCODE_URL
if (-not $downloadUrl) {
    $downloadUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        $downloadUrl = "https://update.code.visualstudio.com/latest/win32-arm64-user/stable"
    }
}

Write-Host "=== Installing VS Code ===`n"

# Check if already installed
if ((Get-Command code -ErrorAction SilentlyContinue) -or (Test-Path $appPath)) {
    Write-Host "  VS Code is already installed."
    Write-Host "  [OK] Skipping download"
} else {
    $tmpDir = $null
    try {
        $tmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("vscode_" + [System.Guid]::NewGuid())
        $installerPath = Join-Path $tmpDir.FullName "VSCode.exe"

        Write-Host "  Downloading VS Code..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "  [OK] Download complete"

        # Install silently
        Write-Host "  Installing..."
        $proc = Start-Process -FilePath $installerPath -ArgumentList "/silent /mergetasks=!runcode" `
                              -Wait -PassThru
        if ($proc.ExitCode -ne 0) {
            throw "VS Code installer exited with code $($proc.ExitCode)"
        }
        Write-Host "  [OK] VS Code installed"
    }
    finally {
        if ($tmpDir -and (Test-Path $tmpDir.FullName)) {
            Remove-Item -Recurse -Force $tmpDir.FullName -ErrorAction SilentlyContinue
        }
    }
}

# Apply settings
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/config/settings_windows.ps1" -UseBasicParsing).Content

# Install extensions
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/config/extensions_windows.ps1" -UseBasicParsing).Content

Write-Host "`n=== VS Code installation complete! ==="
