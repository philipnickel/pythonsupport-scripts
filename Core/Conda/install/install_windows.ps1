# @doc
# @name: DTU Miniforge Install (Windows)
# @description: Download and install Miniforge (conda) on Windows
# @category: Core
# @usage: powershell -File Core/Conda/install/install_windows.ps1
# @requirements: Windows, PowerShell 5.1+
# @notes: Downloads the latest DTU Miniforge installer and runs it silently.
#   The installer bundles Python and all required course packages.
# @/doc

$ErrorActionPreference = "Stop"

$PS_FORGE_URL = if ($env:PS_FORGE_URL) { $env:PS_FORGE_URL } else { "https://github.com/dtudk/pythonsupport-forge/releases/latest/download" }
$installerName = "Miniforge3-Windows-x86_64.exe"

# Resolve install directory
$baseDir = if ($env:USERPROFILE -match '\s') { $env:SystemDrive } else { $env:USERPROFILE }
$installDir = if ($env:PS_CONDA_INSTALL_DIR) { $env:PS_CONDA_INSTALL_DIR } else { Join-Path $baseDir "miniforge3-dtu" }
$condaExe = Join-Path $installDir "Scripts\conda.exe"

Write-Host "=== Installing Miniforge ===`n"

# Check if already installed
if (Test-Path $condaExe) {
    Write-Host "  Miniforge is already installed at $installDir"
    Write-Host "  [OK] Skipping download"
} else {
    $installerPath = Join-Path ([System.IO.Path]::GetTempPath()) $installerName
    try {
        Write-Host "  Downloading $installerName..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri "$PS_FORGE_URL/$installerName" -UseBasicParsing -OutFile $installerPath
        Write-Host "  [OK] Download complete"

        $isAllUsers = -not $installDir.StartsWith($env:USERPROFILE, [System.StringComparison]::OrdinalIgnoreCase)
        $installType = if ($isAllUsers) { "AllUsers" } else { "JustMe" }

        Write-Host "  Running installer..."
        $procArgs = @{
            FilePath     = $installerPath
            ArgumentList = "/S /InstallationType=$installType /RegisterPython=0 /AddToPath=0 /D=$installDir"
            Wait         = $true
            PassThru     = $true
        }
        if ($isAllUsers) { $procArgs.Verb = "RunAs" }

        $proc = Start-Process @procArgs
        if ($proc.ExitCode -ne 0) {
            throw "Miniforge installer exited with code $($proc.ExitCode)"
        }
        Write-Host "  [OK] Miniforge installed to $installDir"
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item -Force $installerPath -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`n=== Miniforge installation complete! ==="
