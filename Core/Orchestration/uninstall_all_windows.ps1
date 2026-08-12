# @doc
# @name: Full Uninstall (Windows)
# @description: Uninstall VS Code and all Conda distributions from the current Windows user
# @category: Core
# @usage: irm https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev/Core/Orchestration/uninstall_all_windows.ps1 | iex
# @requirements: Windows, PowerShell 5.1+
# @notes: Removes VS Code first, followed by current-user Conda distributions and data.
# @/doc

$ErrorActionPreference = "Stop"

if (-not $env:PS_REPO_URL) {
    $env:PS_REPO_URL = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/dev"
}

Write-Host "========================================="
Write-Host "  DTU Python Support - Full Uninstall"
Write-Host "========================================="
Write-Host ""

Write-Host "--- Step 1/2: VS Code ---"
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Utils/VsCode/uninstall_Windows.ps1" -UseBasicParsing).Content
Write-Host ""

Write-Host "--- Step 2/2: Conda distributions ---"
Invoke-Expression (Invoke-WebRequest -Uri "$env:PS_REPO_URL/Utils/Conda/uninstall_Windows.ps1" -UseBasicParsing).Content
Write-Host ""

Write-Host "========================================="
Write-Host "  Uninstall complete!"
Write-Host "========================================="
