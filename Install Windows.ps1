# @doc
# @name: Install Windows Launcher
# @description: Interactive launcher menu to install or uninstall Miniforge and VS Code on Windows
# @category: Launchers
# @usage: powershell -ExecutionPolicy Bypass -File "Install Windows.ps1"
# @requirements: Windows, PowerShell 5.1+
# @notes: Interactive CLI menu to run full or partial installs and uninstalls
# @/doc

param(
    [string]$Action
)

$ErrorActionPreference = "Stop"

if (-not $env:PS_REPO_URL) {
    $env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main"
}

# Auto-resolve bundle root if running offline and not set
if ($env:PS_OFFLINE -eq "1" -and (-not $env:PS_BUNDLE_ROOT)) {
    $env:PS_BUNDLE_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

# Auto-detect architecture if running offline
if ($env:PS_OFFLINE -eq "1" -and (-not $env:PS_BUNDLE_PLATFORM)) {
    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ([Environment]::Is64BitOperatingSystem -and $env:PROCESSOR_ARCHITEW6432) {
        $architecture = $env:PROCESSOR_ARCHITEW6432
    }
    switch ($architecture.ToUpperInvariant()) {
        "ARM64" { $platform = "windows-arm64" }
        "AMD64" { $platform = "windows-x64" }
        default { throw "Unsupported Windows architecture: $architecture" }
    }
    $env:PS_BUNDLE_PLATFORM = $platform
}

function Invoke-RepositoryScript {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    if ($env:PS_OFFLINE -eq "1") {
        if (-not $env:PS_BUNDLE_ROOT) {
            throw "PS_BUNDLE_ROOT is required in offline mode"
        }
        $scriptPath = Join-Path $env:PS_BUNDLE_ROOT ($RelativePath -replace '/', '\')
        & $scriptPath
    } else {
        Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/$RelativePath" -UseBasicParsing).Content
    }
}

function Invoke-Action {
    param([string]$Choice)

    switch ($Choice) {
        "1" {
            Write-Host "`n>>> Running Full Installation..."
            Invoke-RepositoryScript "Core/Orchestration/install_all_windows.ps1"
        }
        "2" {
            Write-Host "`n>>> Installing Miniforge..."
            Invoke-RepositoryScript "Core/Conda/install/install_windows.ps1"
        }
        "3" {
            Write-Host "`n>>> Installing VS Code (with extensions & settings)..."
            Invoke-RepositoryScript "Core/VsCode/install/install_windows.ps1"
        }
        "4" {
            Write-Host "`n>>> Running Full Uninstall..."
            Invoke-RepositoryScript "Core/Orchestration/uninstall_all_windows.ps1"
        }
        "5" {
            Write-Host "`n>>> Uninstalling Miniforge..."
            Invoke-RepositoryScript "Utils/Conda/uninstall_Windows.ps1"
        }
        "6" {
            Write-Host "`n>>> Uninstalling VS Code..."
            Invoke-RepositoryScript "Utils/VsCode/uninstall_Windows.ps1"
        }
        { $_ -in @("q", "Q") } {
            Write-Host "Exiting."
            exit 0
        }
        default {
            Write-Host "Invalid choice: $Choice" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

if ($Action) {
    $null = Invoke-Action $Action
    exit $LASTEXITCODE
}

while ($true) {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "            DTU Python Support (Windows)" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "  [1] Full Installation (Miniforge + VS Code) [Default]"
    Write-Host "  [2] Install Miniforge only"
    Write-Host "  [3] Install VS Code only (with extensions & settings)"
    Write-Host "  ---------------------------------------------------"
    Write-Host "  [4] Full Uninstall (Miniforge + VS Code)"
    Write-Host "  [5] Uninstall Miniforge only"
    Write-Host "  [6] Uninstall VS Code only"
    Write-Host "  ---------------------------------------------------"
    Write-Host "  [q] Quit"
    Write-Host "=====================================================" -ForegroundColor Cyan

    $choice = Read-Host "Enter choice [1-6, or q] (Default: 1)"
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $choice = "1"
    }

    $success = Invoke-Action $choice
    if ($success) {
        Write-Host ""
        Write-Host "=====================================================" -ForegroundColor Green
        Write-Host " [OK] Completed successfully! Closing window..." -ForegroundColor Green
        Write-Host "=====================================================" -ForegroundColor Green
        exit 0
    }
}
