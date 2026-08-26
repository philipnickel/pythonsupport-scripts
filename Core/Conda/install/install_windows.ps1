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

$PS_FORGE_URL = $env:PS_FORGE_URL
if (-not $PS_FORGE_URL) { $PS_FORGE_URL = "https://github.com/dtudk/pythonsupport-forge/releases/latest/download" } #TODO: change to internal site
$installerName = "Miniforge3-Windows-x86_64.exe"

function Test-PathWritable {
    param([string]$Path)
    try {
        $parent = if (Test-Path $Path) { $Path } else { Split-Path $Path -Parent }
        if ([string]::IsNullOrWhiteSpace($parent) -or -not (Test-Path $parent)) {
            $parent = [System.IO.Path]::GetPathRoot($Path)
        }
        $testFile = Join-Path $parent ("dtu_perm_test_" + [System.Guid]::NewGuid())
        [System.IO.File]::WriteAllText($testFile, "test")
        Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

if ($env:PS_CONDA_INSTALL_DIR) {
    $installDir = $env:PS_CONDA_INSTALL_DIR
} elseif ($env:USERPROFILE -match '\s') {
    $systemDrive = if ($env:SystemDrive) { $env:SystemDrive } else { "C:" }
    $installDir = Join-Path $systemDrive "miniforge3-dtu"
    Write-Host "  [NOTE] User profile path contains spaces. Defaulting to '$installDir' (will request administrator privileges)." -ForegroundColor Cyan
} else {
    $installDir = Join-Path $env:USERPROFILE "miniforge3-dtu"
}

$condaExe = Join-Path $installDir "Scripts\conda.exe"


Write-Host "=== Installing Miniforge ===`n"
Write-Host "  [DEBUG] User profile:    '$env:USERPROFILE'"
Write-Host "  [DEBUG] Custom env var:  '$env:PS_CONDA_INSTALL_DIR'"
Write-Host "  [DEBUG] Target dir:      '$installDir'"

# Check if already installed
if (Test-Path $condaExe) {
    Write-Host "  Miniforge is already installed at $installDir"
    Write-Host "  [OK] Skipping download"
} else {
    $tmpDir = $null
    try {
        $tmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("miniforge_" + [System.Guid]::NewGuid())
        $installerPath = Join-Path $tmpDir.FullName $installerName

        Write-Host "  Downloading $installerName..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri "$PS_FORGE_URL/$installerName" -UseBasicParsing `
            -OutFile $installerPath
        Write-Host "  [OK] Download complete"

        # Determine installation type and elevation requirement
        $isUnderUserProfile = $installDir.StartsWith($env:USERPROFILE, [System.StringComparison]::OrdinalIgnoreCase)
        $isWritable = Test-PathWritable -Path $installDir

        if ($isUnderUserProfile -and $isWritable) {
            $installType = "JustMe"
            $useElevation = $false
        } else {
            $installType = "AllUsers"
            $useElevation = $true
        }

        # Run installer
        # Flag rules per the constructor docs
        # (https://conda.github.io/constructor/cli-options/#windows-installers):
        $argString = "/S /InstallationType=$installType /RegisterPython=0 /AddToPath=0 /D=$installDir"

        if ($useElevation) {
            Write-Host "  [NOTE] Installing to '$installDir' requires administrator privileges. Prompting for elevation..." -ForegroundColor Yellow
            $proc = Start-Process -FilePath $installerPath -ArgumentList $argString `
                                -Verb RunAs -Wait -PassThru
        } else {
            Write-Host "  Running installer with arguments: $argString"
            $proc = Start-Process -FilePath $installerPath -ArgumentList $argString `
                                -NoNewWindow -Wait -PassThru
        }

        if ($proc.ExitCode -ne 0) {
            throw "Miniforge installer exited with code $($proc.ExitCode)"
        }
        Write-Host "  [OK] Miniforge installed to $installDir"
    }
    finally {
        if ($tmpDir -and (Test-Path $tmpDir.FullName)) {
            Remove-Item -Recurse -Force $tmpDir.FullName -ErrorAction SilentlyContinue
        }
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

Write-Host "`n=== Miniforge installation complete! ==="
