# @doc
# @name: VS Code Install (Windows)
# @description: Download and install VS Code on Windows
# @category: Core
# @usage: .\Install Windows.ps1 -Action install-vscode
# @requirements: Windows
# @notes: Downloads the architecture-appropriate user installer and installs VS Code.
#   PS_VSCODE_URL may override the installer URL for local testing.
# @/doc

$ErrorActionPreference = "Stop"

if ($env:PS_ENV_INITIALIZED -ne "1") {
    throw "Environment is not initialized. Use Install Windows.ps1 or install_all_windows.ps1."
}

$appPath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"

Write-Host "=== Installing VS Code ===`n"

# Check if already installed
if ((Get-Command code -ErrorAction SilentlyContinue) -or (Test-Path $appPath)) {
    Write-Host "  VS Code is already installed."
    Write-Host "  [OK] Skipping download"
} else {
    $tmpDir = $null
    try {
        if ($env:PS_ENV -eq "offline") {
            if (-not $env:PS_BUNDLE_ROOT) { throw "PS_BUNDLE_ROOT is required in offline mode" }
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
            Invoke-WebRequest -Uri $env:PS_VSCODE_URL -UseBasicParsing `
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

Write-Host "`n=== VS Code installation complete! ==="
