# @doc
# @name: Install required VS Code extensions
# @description: Install required extensions from the VS Code Marketplace (internet required)
# @category: Core
# @usage: .\Install Windows.ps1 -Action install-vscode
# @requirements: Windows, VS Code installed, internet connection
# @notes: Reads extension IDs from extensions.txt; VS Code resolves versions and dependencies
# @/doc

$ErrorActionPreference = "Stop"

if ($env:PS_ENV_INITIALIZED -ne "1") {
    throw "Environment is not initialized. Use Install Windows.ps1 or install_all_windows.ps1."
}

$codeCli = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
if (-not (Test-Path $codeCli)) {
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $codeCli = $codeCmd.Source
    } else {
        throw "VS Code CLI ('code') not found. Is VS Code installed?"
    }
}

Write-Host "=== Installing VS Code Extensions (internet required) ===`n"

if ($env:PS_ENV -eq "offline") {
    if ([string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT)) {
        throw "PS_BUNDLE_ROOT is required in offline mode"
    }
    $extensionsFile = Join-Path $env:PS_BUNDLE_ROOT "Core\VsCode\config\extensions.txt"
    if (-not (Test-Path -LiteralPath $extensionsFile -PathType Leaf)) {
        throw "Missing extension list: $extensionsFile"
    }
    $lines = [IO.File]::ReadAllLines($extensionsFile)
} else {
    $extensionsUrl = "$env:PS_REPO_URL/Core/VsCode/config/extensions.txt"
    $lines = (Invoke-WebRequest -Uri $extensionsUrl -UseBasicParsing).Content -split "`n"
}

$failedExtensions = @()
foreach ($line in $lines) {
    $extensionId = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($extensionId) -or $extensionId.StartsWith("#")) {
        continue
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $invocationError = $null
    $exitCode = $null
    try {
        $ErrorActionPreference = "Continue"
        & $codeCli --install-extension $extensionId --force
        $exitCode = $LASTEXITCODE
    } catch {
        $invocationError = $_.Exception.Message
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($invocationError) {
        Write-Host "  [FAIL] $extensionId ($invocationError)" -ForegroundColor Red
        $failedExtensions += $extensionId
    } elseif ($null -eq $exitCode) {
        Write-Host "  [FAIL] $extensionId (VS Code CLI did not report an exit code)" -ForegroundColor Red
        $failedExtensions += $extensionId
    } elseif ($exitCode -eq 0) {
        Write-Host "  [OK] $extensionId"
    } else {
        Write-Host "  [FAIL] $extensionId (exit code $exitCode)" -ForegroundColor Red
        $failedExtensions += $extensionId
    }
}

if ($failedExtensions.Count -gt 0) {
    throw "Could not install extension(s): $($failedExtensions -join ', '). Connect to the internet and run the VS Code setup again."
}

Write-Host "`n=== Extensions complete! ==="
