# @doc
# @name: Full Installation (Windows)
# @description: Orchestrate the full installation of Miniforge and VS Code on Windows
# @category: Core
# @usage: irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Core/Orchestration/install_all_windows.ps1 | iex
# @requirements: Windows, PowerShell 5.1+
# @notes: Runs all installation steps in order: Miniforge, VS Code (with extensions and settings)
# @/doc

$ErrorActionPreference = "Stop"

if (-not $env:PS_REPO_URL) {
    $env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main"
}

Write-Host "========================================="
Write-Host "  DTU Python Support - Full Installation"
Write-Host "========================================="
Write-Host ""

# Step 1: Install Miniforge/Conda
#Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/Conda/install/install_windows.ps1" -UseBasicParsing).Content

# Step 2: Install VS Code (includes extensions and settings)
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/install/install_windows.ps1" -UseBasicParsing).Content

Write-Host "========================================="
Write-Host "  Installation complete!"
Write-Host "  Open Miniforge Prompt from the Start menu to interact with conda."
Write-Host "========================================="
