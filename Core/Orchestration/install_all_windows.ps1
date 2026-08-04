# @doc
# @name: Full Installation (Windows)
# @description: Orchestrate the full installation of Miniforge and VS Code on Windows
# @category: Core
# @usage: irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/install_all_windows.ps1 | iex
# @requirements: Windows, PowerShell 5.1+
# @notes: Runs all installation steps in order: Miniforge, VS Code (with extensions and settings)
# @/doc

$ErrorActionPreference = "Stop"

if (-not $env:PS_REPO_URL) {
    $env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev"
}

# Load the progress UI (defines the `progress` function; the source guard in
# progress.ps1 skips its self-test when loaded via Invoke-Expression).
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Utils/progress.ps1" -UseBasicParsing).Content

Write-Host "========================================="
Write-Host "  DTU Python Support - Full Installation"
Write-Host "========================================="
Write-Host ""

# Step 1: Install Miniforge/Conda
progress "Step 1/2: Miniforge" 10 {
    Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/Conda/install/install_windows.ps1" -UseBasicParsing).Content
}

# Step 2: Install VS Code (includes extensions and settings)
progress "Step 2/2: VS Code" 5 {
    Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/install/install_windows.ps1" -UseBasicParsing).Content
}

Write-Host "========================================="
Write-Host "  Installation complete!"
Write-Host "  Restart your terminal to activate conda."
Write-Host "========================================="
