# @doc
# @name: Conda Distribution Uninstall (Windows)
# @description: Uninstall all detected Conda distributions and remove Conda user data
# @category: Utilities
# @usage: powershell -File Utils/Conda/uninstall_Windows.ps1
# @requirements: Windows, PowerShell 5.1+
# @notes: Removes positively identified per-user and machine-wide Miniforge,
#   Miniconda, Anaconda, and Mambaforge installations. Administrator rights may
#   be required for machine-wide installations.
# @/doc

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    throw "USERPROFILE is not set; refusing to resolve Conda uninstall paths."
}

$userProfileFullPath = [System.IO.Path]::GetFullPath($env:USERPROFILE)
$userProfileRoot = [System.IO.Path]::GetPathRoot($userProfileFullPath)
if ($userProfileFullPath.Equals($userProfileRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove Conda from an unsafe user profile: $userProfileFullPath"
}

$userProfilePath = $userProfileFullPath.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
)
$condarcPath = Join-Path $userProfilePath ".condarc"
$condaDataPath = Join-Path $userProfilePath ".conda"
$removedSomething = $false
$installDirs = New-Object System.Collections.ArrayList
$protectedPaths = New-Object System.Collections.ArrayList

$protectedPathValues = @(
    [System.IO.Path]::GetPathRoot($userProfilePath),
    $userProfilePath,
    $env:SystemRoot,
    $env:windir,
    $env:ProgramData,
    $env:ProgramFiles,
    [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
)
foreach ($path in $protectedPathValues) {
    if (-not [string]::IsNullOrWhiteSpace($path)) {
        [void]$protectedPaths.Add(
            [System.IO.Path]::GetFullPath($path).TrimEnd(
                [System.IO.Path]::DirectorySeparatorChar,
                [System.IO.Path]::AltDirectorySeparatorChar
            )
        )
    }
}

function Add-CondaInstallCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList]$Candidates
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    if ($protectedPaths | Where-Object { $_.Equals($fullPath, [System.StringComparison]::OrdinalIgnoreCase) }) {
        Write-Host "  [WARNING] Skipping protected Conda path: $fullPath" -ForegroundColor Yellow
        return
    }

    if (Test-Path $fullPath) {
        $item = Get-Item -Path $fullPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "  [WARNING] Skipping Conda path that is a symbolic link or junction: $fullPath" -ForegroundColor Yellow
            return
        }

        if (-not (Test-CondaInstallRoot -Path $fullPath) -and
            -not ([System.IO.Path]::GetFileName($fullPath) -ieq "miniforge3-dtu")) {
            Write-Host "  [WARNING] Skipping directory without Conda installation markers: $fullPath" -ForegroundColor Yellow
            return
        }
    }

    if (-not ($Candidates | Where-Object { $_.Equals($fullPath, [System.StringComparison]::OrdinalIgnoreCase) })) {
        [void]$Candidates.Add($fullPath)
    }
}

function Test-CondaInstallRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path -PathType Container)) {
        return $false
    }

    $hasMetadata = Test-Path (Join-Path $Path "conda-meta") -PathType Container
    $hasExecutable = (Test-Path (Join-Path $Path "Scripts\conda.exe") -PathType Leaf) -or
                     (Test-Path (Join-Path $Path "condabin\conda.bat") -PathType Leaf)
    $hasUninstaller = $null -ne (Get-ChildItem -Path $Path -Filter "Uninstall-*.exe" -File `
        -ErrorAction SilentlyContinue | Select-Object -First 1)
    return ($hasUninstaller -or ($hasMetadata -and $hasExecutable))
}

$commonInstallNames = @(
    "miniforge3-dtu",
    "miniforge3",
    "miniforge",
    "miniconda3",
    "miniconda",
    "anaconda3",
    "anaconda",
    "mambaforge"
)
$searchRoots = @(
    $userProfilePath,
    $env:ProgramData,
    $env:ProgramFiles,
    [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
)
foreach ($searchRoot in $searchRoots) {
    if ([string]::IsNullOrWhiteSpace($searchRoot)) {
        continue
    }
    foreach ($name in $commonInstallNames) {
        Add-CondaInstallCandidate -Path (Join-Path $searchRoot $name) -Candidates $installDirs
    }
}

# Discover custom-named Conda roots directly below standard install roots.
foreach ($searchRoot in $searchRoots) {
    if ([string]::IsNullOrWhiteSpace($searchRoot) -or -not (Test-Path $searchRoot -PathType Container)) {
        continue
    }
    Get-ChildItem -Path $searchRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if (Test-CondaInstallRoot -Path $_.FullName) {
            Add-CondaInstallCandidate -Path $_.FullName -Candidates $installDirs
        }
    }
}

# Include registered installations with a usable InstallLocation.
$registryRoots = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($registryRoot in $registryRoots) {
    if (-not (Test-Path $registryRoot)) {
        continue
    }
    Get-ItemProperty -Path "$registryRoot\*" -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match "(?i)(Anaconda|Miniconda|Miniforge|Mambaforge)"
    } | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_.InstallLocation)) {
            Add-CondaInstallCandidate -Path $_.InstallLocation -Candidates $installDirs
        }
    }
}

$condaCommand = Get-Command conda -ErrorAction SilentlyContinue
if ($condaCommand) {
    try {
        $condaInvoker = if ([string]::IsNullOrWhiteSpace($condaCommand.Source)) {
            $condaCommand.Name
        } else {
            $condaCommand.Source
        }
        $detectedBase = (& $condaInvoker info --base 2>$null | Select-Object -First 1).Trim()
        if (-not [string]::IsNullOrWhiteSpace($detectedBase)) {
            if (Test-CondaInstallRoot -Path $detectedBase) {
                Add-CondaInstallCandidate -Path $detectedBase -Candidates $installDirs
            } else {
                Write-Host "  [WARNING] Ignoring detected Conda base without installation markers: $detectedBase" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  [WARNING] Could not query the active Conda installation: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "=== Uninstalling Conda distributions ===`n"

foreach ($installDir in $installDirs) {
    if (-not (Test-Path $installDir)) {
        continue
    }

    Write-Host "  Found Conda installation at $installDir"
    $uninstaller = Get-ChildItem -Path $installDir -Filter "Uninstall-*.exe" -File -ErrorAction SilentlyContinue |
                   Select-Object -First 1

    if ($uninstaller) {
        Write-Host "  Running $($uninstaller.Name)..."
        $proc = Start-Process -FilePath $uninstaller.FullName -ArgumentList "/S" -Wait -PassThru
        if ($proc.ExitCode -ne 0) {
            throw "$($uninstaller.Name) exited with code $($proc.ExitCode)"
        }
        Write-Host "  [OK] Conda uninstaller completed"
        $removedSomething = $true
    } else {
        Write-Host "  [WARNING] Conda uninstaller not found; removing the installation directory." -ForegroundColor Yellow
    }

    if (Test-Path $installDir) {
        Remove-Item -Path $installDir -Recurse -Force
        Write-Host "  [OK] Removed $installDir"
        $removedSomething = $true
    }
}

if (Test-Path $condarcPath) {
    Remove-Item -Path $condarcPath -Force
    Write-Host "  [OK] Conda configuration removed"
    $removedSomething = $true
}

if (Test-Path $condaDataPath) {
    Remove-Item -Path $condaDataPath -Recurse -Force
    Write-Host "  [OK] Conda user data removed"
    $removedSomething = $true
}

Write-Host ""
if ($removedSomething) {
    Write-Host "=== Conda uninstall complete! ==="
} else {
    Write-Host "No changes made - no Conda installations found."
}
