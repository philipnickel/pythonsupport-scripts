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

$offlineExtensions = $env:PS_OFFLINE -eq "1"
if ($offlineExtensions) {
    if (-not $env:PS_BUNDLE_ROOT) { throw "PS_BUNDLE_ROOT is required in offline mode" }
    if (-not $env:PS_BUNDLE_PLATFORM) {
        $architecture = $env:PROCESSOR_ARCHITECTURE
        if ([Environment]::Is64BitOperatingSystem -and $env:PROCESSOR_ARCHITEW6432) {
            $architecture = $env:PROCESSOR_ARCHITEW6432
        }
        switch ($architecture.ToUpperInvariant()) {
            "ARM64" { $env:PS_BUNDLE_PLATFORM = "windows-arm64" }
            "AMD64" { $env:PS_BUNDLE_PLATFORM = "windows-x64" }
            default { throw "Unsupported Windows architecture: $architecture" }
        }
    }
    switch ($env:PS_BUNDLE_PLATFORM) {
        "windows-x64" { $extensionPlatform = "win32-x64" }
        "windows-arm64" { $extensionPlatform = "win32-arm64" }
        default { throw "Invalid or missing PS_BUNDLE_PLATFORM: $env:PS_BUNDLE_PLATFORM" }
    }
    $extensionIndex = Join-Path $env:PS_BUNDLE_ROOT "bundle_assets\extensions\$extensionPlatform\index.txt"
    if (-not (Test-Path -LiteralPath $extensionIndex -PathType Leaf)) {
        throw "Missing offline extension index: $extensionIndex"
    }
    $lines = [IO.File]::ReadAllLines($extensionIndex)
} else {
    $extensionsUrl = "$env:PS_REPO_URL/Core/VsCode/config/extensions.txt"
    $lines = (Invoke-WebRequest -Uri $extensionsUrl -UseBasicParsing).Content -split "`n"
}
$failedExtensions = @()
$offlineArguments = @()

foreach ($line in $lines) {
    $line = $line.Trim()

    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        continue
    }

    $extensionArgument = $line
    if ($offlineExtensions) {
        $extensionArgument = Join-Path $env:PS_BUNDLE_ROOT ($line -replace '/', '\')
        if (-not (Test-Path -LiteralPath $extensionArgument -PathType Leaf)) {
            $failedExtensions += $line
            Write-Host "  [FAIL] Missing VSIX: $line" -ForegroundColor Red
            continue
        }
        $offlineArguments += "--install-extension"
        $offlineArguments += $extensionArgument
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
        & $codeCli --install-extension $extensionArgument --force
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

if ($offlineExtensions) {
    if ($offlineArguments.Count -eq 0) {
        throw "Offline extension index is empty: $extensionIndex"
    }
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & $codeCli @offlineArguments --force
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        throw "Failed to install bundled VS Code extensions (exit code $exitCode)"
    }
    Write-Host "  [OK] Bundled extensions installed"
}

Write-Host "`n=== Extensions complete! ==="
