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
        if ($env:PS_OFFLINE -eq "1") {
            if (-not $env:PS_BUNDLE_ROOT) { throw "PS_BUNDLE_ROOT is required in offline mode" }
            if (-not $env:PS_BUNDLE_PLATFORM) {
                $architecture = $env:PROCESSOR_ARCHITECTURE
                if ([Environment]::Is64BitOperatingSystem -and $env:PROCESSOR_ARCHITEW6432) {
                    $architecture = $env:PROCESSOR_ARCHITEW6432
                }
                switch ($architecture.ToUpperInvariant()) {
                    "ARM64" { $env:PS_BUNDLE_PLATFORM = "windows-arm64" }
                    "AMD64" { $env:PS_BUNDLE_PLATFORM = "windows-x64" }
                    default { throw "Unsupported Windows architecture: $architecture" }
                }
            }
            $bundlePlatform = $env:PS_BUNDLE_PLATFORM
            if ($bundlePlatform -notin @("windows-x64", "windows-arm64")) {
                throw "Invalid or missing PS_BUNDLE_PLATFORM: $bundlePlatform"
            }
            $installerPath = Join-Path $env:PS_BUNDLE_ROOT "bundle_assets\vscode\$bundlePlatform\VSCode.exe"
            if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
                throw "Missing offline VS Code installer: $installerPath"
            }
            Write-Host "  Using bundled VS Code installer"
        } else {
            $tmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("vscode_" + [System.Guid]::NewGuid())
            $installerPath = Join-Path $tmpDir.FullName "VSCode.exe"

            Write-Host "  Downloading VS Code..."
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing `
                -OutFile $installerPath
            Write-Host "  [OK] Download complete"
        }

        # Install silently
        Write-Host "  Installing..."
        $proc = Start-Process -FilePath $installerPath -ArgumentList "/silent /mergetasks=!runcode" `
                              -NoNewWindow -Wait -PassThru
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
if ($env:PS_OFFLINE -eq "1") {
    & (Join-Path $env:PS_BUNDLE_ROOT "Core\VsCode\config\settings_windows.ps1")
} else {
    Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/config/settings_windows.ps1" -UseBasicParsing).Content
}

# Install extensions
if ($env:PS_OFFLINE -eq "1") {
    & (Join-Path $env:PS_BUNDLE_ROOT "Core\VsCode\config\extensions_windows.ps1")
} else {
    Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/config/extensions_windows.ps1" -UseBasicParsing).Content
}

Write-Host "`n=== VS Code installation complete! ==="
