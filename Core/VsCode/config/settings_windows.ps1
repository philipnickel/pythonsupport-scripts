# @doc
# @name: Configure VS Code settings
# @description: Apply default VS Code settings
# @category: Core
# @usage: .\Install Windows.ps1 -Action install-vscode
# @requirements: windows, VS Code installed
# @notes: Copies default_settings_Windows.json to the VS Code user settings location
# @/doc

# Like 'set -e' in bash
$ErrorActionPreference = "Stop"

if ($env:PS_ENV_INITIALIZED -ne "1") {
    throw "Environment is not initialized. Use Install Windows.ps1 or install_all_windows.ps1."
}

$settingsDir = Join-Path $env:APPDATA "Code\User"
$settingsFile = Join-Path $settingsDir "settings.json"

Write-Host "=== Applying VS Code Settings ===`n"

if (Test-Path $settingsFile) {
    Write-Host "  [WARNING] $settingsFile already exists. Keeping the existing settings." -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null

    if ($env:PS_ENV -eq "offline") {
        if (-not $env:PS_BUNDLE_ROOT) { throw "PS_BUNDLE_ROOT is required in offline mode" }
        $bundledSettings = Join-Path $env:PS_BUNDLE_ROOT "Core\VsCode\config\default_settings_Windows.json"
        if (-not (Test-Path -LiteralPath $bundledSettings -PathType Leaf)) {
            throw "Missing bundled VS Code settings: $bundledSettings"
        }
        Copy-Item -LiteralPath $bundledSettings -Destination $settingsFile
    } else {
        Invoke-WebRequest -Uri "$env:PS_REPO_URL/Core/VsCode/config/default_settings_Windows.json" `
                          -OutFile $settingsFile `
                          -UseBasicParsing
    }

    Write-Host "  [OK] Settings applied to $settingsFile"
}

Write-Host "`n=== VS Code settings complete! ==="
