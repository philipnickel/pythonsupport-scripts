# @doc
# @name: Uninstall VS Code
# @description: Uninstall the DTU user installation of VS Code and remove its user data
# @category: Utilities
# @usage: .\Install Windows.ps1 -Action uninstall-vscode
# @requirements: Windows, PowerShell 5.1+
# @notes: Runs the VS Code user uninstaller when present, then removes settings,
#   extensions, and remaining files from the current user's profile.
# @/doc

$ErrorActionPreference = "Stop"

if ($env:PS_ENV_INITIALIZED -ne "1") {
    throw "Environment is not initialized. Use Install Windows.ps1."
}

$appPath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"
$uninstallerPath = Join-Path $appPath "unins000.exe"
$configPath = Join-Path $env:APPDATA "Code"
$userDataPath = Join-Path $env:USERPROFILE ".vscode"
$removedSomething = $false

Write-Host "=== Uninstalling VS Code ===`n"

if (Test-Path $uninstallerPath -PathType Leaf) {
    Write-Host "  Running the VS Code uninstaller..."
    $proc = Start-Process -FilePath $uninstallerPath `
                          -ArgumentList "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES" `
                          -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        throw "VS Code uninstaller exited with code $($proc.ExitCode)"
    }
    Write-Host "  [OK] VS Code uninstaller completed"
    $removedSomething = $true
} elseif (Test-Path $appPath) {
    Write-Host "  [WARNING] VS Code uninstaller not found; removing the remaining application files." -ForegroundColor Yellow
} else {
    Write-Host "  VS Code application not found."
}

if (Test-Path $appPath) {
    Remove-Item -Path $appPath -Recurse -Force
    Write-Host "  [OK] Application files removed"
    $removedSomething = $true
}

if (Test-Path $configPath) {
    Remove-Item -Path $configPath -Recurse -Force
    Write-Host "  [OK] Settings and application data removed"
    $removedSomething = $true
}

if (Test-Path $userDataPath) {
    Remove-Item -Path $userDataPath -Recurse -Force
    Write-Host "  [OK] Extensions and user data removed"
    $removedSomething = $true
}

Write-Host ""
if ($removedSomething) {
    Write-Host "=== VS Code uninstall complete! ==="
} else {
    Write-Host "No changes made - VS Code not found."
}
