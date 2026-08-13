# @doc
# @name: VS Code Extensions (windows)
# @description: Install VS Code extensions from extensions.txt
# @category: Core
# @usage: . .\Core\VsCode\config\extensions_windows.ps1
# @requirements: windows, VS Code installed
# @notes: Reads extension IDs from extensions_windows.txt (one per line, # comments and blank lines skipped)
# @/doc

$ErrorActionPreference = "Stop"

# Resolve the VS Code CLI: prefer the default install location, fall back to PATH
$codeCli = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
if (-not (Test-Path $codeCli)) {
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $codeCli = $codeCmd.Source
    } else {
        throw "VS Code CLI ('code') not found. Is VS Code installed?"
    }
}

Write-Host "=== Installing VS Code Extensions ===`n"

$extensionsUrl = "$env:PS_REPO_URL/Core/VsCode/config/extensions.txt"
$lines = (Invoke-WebRequest -Uri $extensionsUrl -UseBasicParsing).Content -split "`n"
$failedExtensions = @()

foreach ($line in $lines) {
    $line = $line.Trim()

    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        continue
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $invocationError = $null
    $exitCode = $null

    try {
        # Windows PowerShell 5.1 promotes native stderr to its Error stream.
        # Keep it non-terminating so output remains visible and use the native
        # exit code to decide whether installation succeeded.
        $ErrorActionPreference = "Continue"
        & $codeCli --install-extension $line --force
        $exitCode = $LASTEXITCODE
    } catch {
        $invocationError = $_.Exception.Message
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($invocationError) {
        Write-Host "  [FAIL] $line ($invocationError)" -ForegroundColor Red
        $failedExtensions += $line
    } elseif ($null -eq $exitCode) {
        Write-Host "  [FAIL] $line (VS Code CLI did not report an exit code)" -ForegroundColor Red
        $failedExtensions += $line
    } elseif ($exitCode -eq 0) {
        Write-Host "  [OK] $line"
    } else {
        Write-Host "  [FAIL] $line (exit code $exitCode)" -ForegroundColor Red
        $failedExtensions += $line
    }
}

if ($failedExtensions.Count -gt 0) {
    throw "Failed to install VS Code extension(s): $($failedExtensions -join ', ')"
}

Write-Host "`n=== Extensions complete! ==="
