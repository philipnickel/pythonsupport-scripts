# @doc
# @name: VS Code Install (Windows)
# @description: Download and install VS Code on Windows
# @category: Core
# @usage: powershell -File Core/VsCode/install/install_windows.ps1
# @requirements: Windows
# @notes: Downloads the installer and installs VS Code
# @/doc

$ErrorActionPreference = "Stop"

$AppPath = "$Env:LOCALAPPDATA\Programs\Microsoft VS Code"
$DownloadUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"

Write-Host "=== Installing VS Code ===`n"

# Check if already installed
if (Get-Command code -ErrorAction SilentlyContinue -or (Test-Path $AppPath)) {
    Write-Host "  VS Code is already installed."
    Write-Host "  [OK] Skipping download"
} else {
    # Create temp directory
    $TmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("vscode_" + [System.Guid]::NewGuid())
    try {
        $ZipPath = Join-Path $TmpDir.FullName "VSCode.exe"

        Write-Host "  Downloading VS Code..."
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath
        Write-Host "  [OK] Download complete"

        # Remove existing installation if present
        if (Test-Path $AppPath) {
            Write-Host "  Removing existing installation..."
            Remove-Item -Recurse -Force $AppPath
        }

        # Install silently
        Write-Host "  Installing..."
        Start-Process -FilePath $ZipPath -ArgumentList "/silent /mergetasks=!runcode" -Wait
        Write-Host "  [OK] VS Code installed"
    }
    finally {
        Remove-Item -Recurse -Force $TmpDir
    }
}

# Apply settings
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/config/settings_windows.ps1" -UseBasicParsing).Content

# Install extensions
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/config/extensions_windows.ps1" -UseBasicParsing).Content

Write-Host "`n=== VS Code installation complete! ==="
