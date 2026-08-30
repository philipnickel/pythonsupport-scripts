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

if (Test-Path Env:PS_OFFLINE) {
    throw "PS_OFFLINE is no longer supported; use PS_ENV=offline."
}

if ([string]::IsNullOrWhiteSpace($env:PS_ENV) -and
    [string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT) -and
    [string]::IsNullOrWhiteSpace($env:PS_REPO_URL) -and
    [string]::IsNullOrWhiteSpace($env:PS_REPO_USER) -and
    [string]::IsNullOrWhiteSpace($env:PS_BRANCH) -and
    [string]::IsNullOrWhiteSpace($env:PS_FORGE_URL) -and
    [string]::IsNullOrWhiteSpace($env:PS_VSCODE_URL)) {
    $env:PS_ENV = "offline"
    $env:PS_BUNDLE_ROOT = $PSScriptRoot
} elseif ($env:PS_ENV -eq "offline" -and [string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT)) {
    $env:PS_BUNDLE_ROOT = $PSScriptRoot
}

function Import-Environment {
    if ($env:PS_ENV -eq "offline" -or
        ([string]::IsNullOrWhiteSpace($env:PS_ENV) -and -not [string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT))) {
        . (Join-Path $env:PS_BUNDLE_ROOT "Core\env.ps1")
        return
    }

    if ($env:PS_ENV -eq "main") {
        $envSource = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/env.ps1"
    } elseif (-not [string]::IsNullOrWhiteSpace($env:PS_REPO_URL)) {
        $envSource = "$(($env:PS_REPO_URL).TrimEnd('/'))/Core/env.ps1"
    } else {
        $repoUser = if ($env:PS_REPO_USER) { $env:PS_REPO_USER } else { "dtudk" }
        $branch = if ($env:PS_BRANCH) { $env:PS_BRANCH } else { "main" }
        $envSource = "https://raw.githubusercontent.com/$repoUser/pythonsupport-scripts/$branch/Core/env.ps1"
    }

    $content = (Invoke-WebRequest -Uri $envSource -UseBasicParsing).Content
    . ([ScriptBlock]::Create($content))
}

Import-Environment

function Invoke-Action {
    param([string]$Choice)

    switch ($Choice) {
        { $_ -in @("1", "install-all") } {
            Write-Host "`n>>> Running Full Installation..."
            Invoke-RepositoryScript "Core/Conda/install/install_windows.ps1"
            Invoke-RepositoryScript "Core/VsCode/install/install_windows.ps1"
            Invoke-RepositoryScript "Core/VsCode/config/settings_windows.ps1"
            try {
                Invoke-RepositoryScript "Core/VsCode/config/extensions_windows.ps1"
            } catch {
                Write-Warning "VS Code extensions were not installed. Connect to the internet and run the VS Code setup again. $($_.Exception.Message)"
            }
        }
        { $_ -in @("2", "install-conda") } {
            Write-Host "`n>>> Installing Miniforge..."
            Invoke-RepositoryScript "Core/Conda/install/install_windows.ps1"
        }
        { $_ -in @("3", "install-vscode") } {
            Write-Host "`n>>> Installing VS Code (with extensions & settings)..."
            Invoke-RepositoryScript "Core/VsCode/install/install_windows.ps1"
            Invoke-RepositoryScript "Core/VsCode/config/settings_windows.ps1"
            Invoke-RepositoryScript "Core/VsCode/config/extensions_windows.ps1"
        }
        { $_ -in @("4", "uninstall-all") } {
            Write-Host "`n>>> Running Full Uninstall..."
            Invoke-RepositoryScript "Utils/VsCode/uninstall_Windows.ps1"
            Invoke-RepositoryScript "Utils/Conda/uninstall_Windows.ps1"
        }
        { $_ -in @("5", "uninstall-conda") } {
            Write-Host "`n>>> Uninstalling Miniforge..."
            Invoke-RepositoryScript "Utils/Conda/uninstall_Windows.ps1"
        }
        { $_ -in @("6", "uninstall-vscode") } {
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
    $success = Invoke-Action $Action
    if ($success -eq $false) { exit 1 }
    exit 0
}

while ($true) {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "            DTU Python Support (Windows)" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "  [1] Full Installation (install-all) [Default]"
    Write-Host "  [2] Install Miniforge only (install-conda)"
    Write-Host "  [3] Install VS Code only (install-vscode)"
    Write-Host "  ---------------------------------------------------"
    Write-Host "  [4] Full Uninstall (uninstall-all)"
    Write-Host "  [5] Uninstall Miniforge only (uninstall-conda)"
    Write-Host "  [6] Uninstall VS Code only (uninstall-vscode)"
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
