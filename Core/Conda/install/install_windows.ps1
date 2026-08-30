# @doc
# @name: Install DTU Miniforge
# @description: Download and install Miniforge (conda) on Windows
# @category: Core
# @usage: .\Install Windows.ps1 -Action install-conda
# @requirements: Windows, PowerShell 5.1+
# @notes: Downloads the latest DTU Miniforge installer and runs it silently.
#   The installer bundles Python and all required course packages.
# @/doc

$ErrorActionPreference = "Stop"

if ($env:PS_ENV_INITIALIZED -ne "1") {
    throw "Environment is not initialized. Use Install Windows.ps1 or install_all_windows.ps1."
}

$installerName = "Miniforge3-Windows-x86_64.exe"
$installDir = Join-Path $env:USERPROFILE "miniforge3-dtu"
$condaExe = Join-Path $installDir "Scripts\conda.exe"
$installedNow = $false
$releasePayload = $null


Write-Host "=== Installing Miniforge ===`n"

# Check if already installed
if (Test-Path $condaExe) {
    Write-Host "  Miniforge is already installed at $installDir"
    Write-Host "  [OK] Skipping download"
} else {
    $tmpDir = $null
    try {
        if ($env:PS_ENV -eq "offline") {
            if (-not $env:PS_BUNDLE_ROOT) { throw "PS_BUNDLE_ROOT is required in offline mode" }
            $installerPath = Join-Path $env:PS_BUNDLE_ROOT "bundle_assets\miniforge\windows-x64\Miniforge3.exe"
            if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
                throw "Missing offline Miniforge installer: $installerPath"
            }
            Write-Host "  Using bundled $installerName"
        } else {
            $tmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("miniforge_" + [System.Guid]::NewGuid())
            $installerPath = Join-Path $tmpDir.FullName $installerName

            Write-Host "  Downloading $installerName..."
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri "$(($env:PS_FORGE_URL).TrimEnd('/'))/$installerName" -UseBasicParsing `
                -OutFile $installerPath
            try {
                $releasePayload = Invoke-RestMethod -Uri "https://api.github.com/repos/dtudk/pythonsupport-forge/releases/latest" `
                                                    -UseBasicParsing -TimeoutSec 5
            } catch { }
            Write-Host "  [OK] Download complete"
        }

        # Run installer
        # Flag rules per the constructor docs
        # (https://conda.github.io/constructor/cli-options/#windows-installers):
        Write-Host "  Running installer..."
        $argString = "/S /InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /D=$installDir"
        $proc = Start-Process -FilePath $installerPath -ArgumentList $argString `
                            -NoNewWindow -Wait -PassThru
        if ($proc.ExitCode -ne 0) {
            throw "Miniforge installer exited with code $($proc.ExitCode)"
        }
        $installedNow = $true
        Write-Host "  [OK] Miniforge installed to $installDir"
    }
    finally {
        if ($tmpDir -and (Test-Path $tmpDir.FullName)) {
            Remove-Item -Recurse -Force $tmpDir.FullName -ErrorAction SilentlyContinue
        }
    }
}

if ($installedNow) {
    $dtuRelease = ""
    $miniforgeVersion = ""
    if ($env:PS_ENV -eq "offline") {
        $dtuRelease = [string]$env:PS_DTU_RELEASE
        $miniforgeVersion = [string]$env:PS_MINIFORGE_VERSION
    } elseif ($releasePayload) {
        $dtuRelease = [string]$releasePayload.tag_name
        $asset = $releasePayload.assets |
            Where-Object { $_.name -match '^Miniforge3-([0-9][0-9.]*-[0-9]+)-Windows-' } |
            Select-Object -First 1
        if ($asset -and $asset.name -match '^Miniforge3-([0-9][0-9.]*-[0-9]+)-Windows-') {
            $miniforgeVersion = $Matches[1]
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($dtuRelease)) {
        $marker = [ordered]@{
            schema = 1
            dtuRelease = $dtuRelease
            miniforgeVersion = $miniforgeVersion
            installedAt = [DateTime]::UtcNow.ToString("o")
            source = $env:PS_ENV
        } | ConvertTo-Json
        [IO.File]::WriteAllText((Join-Path $installDir ".dtu-python-support.json"), $marker + "`n")
    } else {
        Write-Warning "Could not determine the DTU release; installation marker was not written"
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
