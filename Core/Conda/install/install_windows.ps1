# @doc
# @name: Miniforge Install (Windows)
# @description: Download and install Miniforge (conda) on Windows
# @category: Core
# @usage: powershell -File Core/Conda/install/install_windows.ps1
# @requirements: Windows, PowerShell 5.1+
# @notes: Downloads the latest Miniforge installer and runs it silently.
#   The installer bundles Python and all required course packages.
# @/doc

$ErrorActionPreference = "Stop"

$PS_FORGE_URL = $env:PS_FORGE_URL
if (-not $PS_FORGE_URL) { $PS_FORGE_URL = "https://github.com/dtudk/pythonsupport-forge/releases/latest/download" } #TODO: change to internal site
$installerName = "Miniforge3-Windows-x86_64.exe"
$installDir = Join-Path $env:USERPROFILE "miniforge3-dtu"
$condaExe = Join-Path $installDir "Scripts\conda.exe"

if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    Write-Host "  NOTE: no native ARM64 Miniforge installer; using the x64 installer (runs under emulation)."
}

Write-Host "=== Installing Miniforge ===`n"

# Check if already installed
if (Test-Path $condaExe) {
    Write-Host "  Miniforge is already installed at $installDir"
    Write-Host "  [OK] Skipping download"
} else {
    $tmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("miniforge_" + [System.Guid]::NewGuid())
    try {
        $installerPath = Join-Path $tmpDir.FullName $installerName

        Write-Host "  Downloading $installerName..."
        Invoke-WebRequest -Uri "$PS_FORGE_URL/$installerName" -OutFile $installerPath -UseBasicParsing
        Write-Host "  [OK] Download complete"

        # Run installer
        # Flag rules per the constructor docs
        # (https://conda.github.io/constructor/cli-options/#windows-installers):
        Write-Host "  Running installer..."
        $argString = "/S /InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /D=$installDir"
        $installLog = Join-Path $tmpDir.FullName "install.log"
        $proc = Start-Process -FilePath $installerPath -ArgumentList $argString `
                            -NoNewWindow -Wait -PassThru -RedirectStandardOutput $installLog
        if ($proc.ExitCode -ne 0) {
            if (Test-Path $installLog) { Get-Content $installLog | Write-Host }
            throw "Miniforge installer exited with code $($proc.ExitCode)"
        }
        Write-Host "  [OK] Miniforge installed to $installDir"
    }
    finally {
        Remove-Item -Recurse -Force $tmpDir.FullName -ErrorAction SilentlyContinue
    }
}

#NOTE: Not needed if we just use miniconda prompt 
# Load conda shell integration and activate the base environment
# (mirror of 'source conda.sh && conda activate' in the macOS script)
#Write-Host "  Initializing conda..."
#$condaHook = Join-Path $installDir "shell\condabin\conda-hook.ps1"
#if (Test-Path $condaHook) {
#    & $condaHook
#    conda activate $installDir
#}

# Initialize conda for all supported shells on this machine
# (on Windows: PowerShell profile + cmd.exe autorun)
#& $condaExe init --all
#if ($LASTEXITCODE -ne 0) {
#    throw "conda init --all failed with exit code $LASTEXITCODE"
#}
#Write-Host "  [OK] conda init complete (restart your terminal to activate)"

#Write-Host "`n=== Miniforge installation complete! ==="
