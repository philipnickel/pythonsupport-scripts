# @doc
# @name: Install everything
# @description: Orchestrate the full installation of Miniforge and VS Code on Windows
# @category: Core
# @usage: irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/Orchestration/install_all_windows.ps1 | iex
# @requirements: Windows, PowerShell 5.1+
# @notes: Runs all installation steps in order: Miniforge, VS Code (with extensions and settings)
# @/doc

$ErrorActionPreference = "Stop"

if (Test-Path Env:PS_OFFLINE) {
    throw "PS_OFFLINE is no longer supported; use PS_ENV=offline."
}

function Import-Environment {
    if ($env:PS_ENV -eq "offline" -or
        ([string]::IsNullOrWhiteSpace($env:PS_ENV) -and -not [string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT))) {
        if ([string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT)) {
            throw "PS_BUNDLE_ROOT is required for offline initialization"
        }
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

Write-Host "========================================="
Write-Host "  DTU Python Support - Full Installation"
Write-Host "========================================="
Write-Host ""

# Step 1: Install Miniforge/Conda
Invoke-RepositoryScript "Core/Conda/install/install_windows.ps1"

# Step 2: Install VS Code (includes extensions and settings)
Invoke-RepositoryScript "Core/VsCode/install/install_windows.ps1"
Invoke-RepositoryScript "Core/VsCode/config/settings_windows.ps1"
try {
    Invoke-RepositoryScript "Core/VsCode/config/extensions_windows.ps1"
} catch {
    Write-Warning "VS Code extensions were not installed. Connect to the internet and run the VS Code setup again. $($_.Exception.Message)"
}

Write-Host "========================================="
Write-Host "  Installation complete!"
Write-Host "  Open Miniforge Prompt from the Start menu to interact with conda."
Write-Host "========================================="
