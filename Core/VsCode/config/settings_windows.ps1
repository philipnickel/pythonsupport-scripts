# @doc
# @name: VS Code Settings (windows)
# @description: Apply default VS Code settings
# @category: Core
# @usage: . .\Core\VsCode\config\settings_windows.ps1
# @requirements: windows, VS Code installed
# @notes: Copies default_settings_Windows.json to the VS Code user settings location
# @/doc

# Like 'set -e' in bash
$ErrorActionPreference = "Stop"

$settingsDir = Join-Path $env:APPDATA "Code\User"
$settingsFile = Join-Path $settingsDir "settings.json"

Write-Host "=== Applying VS Code Settings ===`n"

if (Test-Path $settingsFile) {
    Write-Host "  [WARNING] $settingsFile already exists. Keeping the existing settings." -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null

    if ($env:PS_OFFLINE -eq "1") {
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
