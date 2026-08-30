# @doc
# @name: VS Code settings status
# @description: Check whether a VS Code settings file exists on Windows
# @category: Checks
# @/doc

$ErrorActionPreference = "Stop"
$settingsFile = Join-Path $env:APPDATA "Code\User\settings.json"
$codeExe = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\Code.exe"
if (Test-Path $settingsFile -PathType Leaf) {
    $status = "ready"; $summary = "VS Code settings are configured"
} elseif (-not (Test-Path $codeExe -PathType Leaf) -and $null -eq (Get-Command code -ErrorAction SilentlyContinue)) {
    $status = "blocked"; $summary = "Settings need VS Code"
} else {
    $status = "missing"; $summary = "VS Code settings are not configured"
}
[ordered]@{schema=1; id="vscode-settings"; status=$status; summary=$summary; installedVersion=""; latestVersion=""; details=@()} | ConvertTo-Json -Compress
