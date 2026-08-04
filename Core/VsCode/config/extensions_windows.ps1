# @doc
# @name: VS Code Extensions (windows)
# @description: Install VS Code extensions from extensions.txt
# @category: Core
# @usage: . .\Core\VsCode\config\extensions_windows.ps1
# @requirements: windows, VS Code installed
# @notes: Reads extension IDs from extensions_windows.txt (one per line, # comments and blank lines skipped)
# @/doc

$ErrorActionPreference = "Stop"

$codeCli = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"

Write-Host "=== Installing VS Code Extensions ===`n"

$extensionsUrl = "$env:PS_REPO_URL/Core/VsCode/config/extensions.txt"
$lines = (Invoke-WebRequest -Uri $extensionsUrl -UseBasicParsing).Content -split "`n"

foreach ($line in $lines) {
    $line = $line.Trim()

    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        continue
    }

    try {
        & $codeCli --install-extension $line --force 2>$null
        Write-Host "  [OK] $line"
    } catch {
        Write-Host "  [FAIL] $line"
    }
}

Write-Host "`n=== Extensions complete! ==="
