# @doc
# @name: VS Code status
# @description: Check whether VS Code is installed on Windows
# @category: Checks
# @/doc

$ErrorActionPreference = "Stop"
$appPath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"
$codeExe = Join-Path $appPath "Code.exe"
$version = ""
if (Test-Path $codeExe -PathType Leaf) {
    $version = (Get-Item $codeExe).VersionInfo.ProductVersion
} else {
    $command = Get-Command code -ErrorAction SilentlyContinue
    if ($command) {
        try { $version = (& $command.Source --version 2>$null | Select-Object -First 1) } catch { }
    }
}

$installed = (Test-Path $codeExe -PathType Leaf) -or $null -ne (Get-Command code -ErrorAction SilentlyContinue)
$summary = if ($installed -and $version) { "VS Code $version" } elseif ($installed) { "VS Code is installed" } else { "VS Code is not installed" }
[ordered]@{
    schema = 1; id = "vscode"; status = $(if ($installed) { "ready" } else { "missing" })
    summary = $summary; installedVersion = [string]$version; latestVersion = ""; details = @()
} | ConvertTo-Json -Compress
