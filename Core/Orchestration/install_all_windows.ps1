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

if ($env:PS_OFFLINE -eq "1") {
    if (-not $env:PS_BUNDLE_ROOT) { throw "PS_BUNDLE_ROOT is required in offline mode" }

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

Write-Host "========================================="
Write-Host "  DTU Python Support - Full Installation"
Write-Host "========================================="
Write-Host ""

# Step 1: Install Miniforge/Conda
Invoke-RepositoryScript "Core/Conda/install/install_windows.ps1"

# Step 2: Install VS Code (includes extensions and settings)
Invoke-RepositoryScript "Core/VsCode/install/install_windows.ps1"

Write-Host "========================================="
Write-Host "  Installation complete!"
Write-Host "  Open Miniforge Prompt from the Start menu to interact with conda."
Write-Host "========================================="
