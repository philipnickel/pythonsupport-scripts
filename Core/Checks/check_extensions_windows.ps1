# @doc
# @name: VS Code extensions status
# @description: Check that every required DTU VS Code extension is installed
# @category: Checks
# @/doc

$ErrorActionPreference = "Stop"
$codeCli = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
if (-not (Test-Path $codeCli -PathType Leaf)) {
    $command = Get-Command code -ErrorAction SilentlyContinue
    if ($command) { $codeCli = $command.Source }
}
if (-not (Test-Path $codeCli -PathType Leaf)) {
    [ordered]@{schema=1; id="vscode-extensions"; status="blocked"; summary="Extensions need VS Code"; installedVersion=""; latestVersion=""; details=@()} | ConvertTo-Json -Compress
    exit 0
}

if ($env:PS_ENV -eq "offline") {
    $extensionsFile = Join-Path $env:PS_BUNDLE_ROOT "Core\VsCode\config\extensions.txt"
    $expectedLines = [IO.File]::ReadAllLines($extensionsFile)
} else {
    $expectedLines = ((Invoke-WebRequest -Uri "$($env:PS_REPO_URL.TrimEnd('/'))/Core/VsCode/config/extensions.txt" -UseBasicParsing -TimeoutSec 5).Content -split "`n")
}
$installed = @(& $codeCli --list-extensions 2>$null | ForEach-Object { $_.Trim().ToLowerInvariant() })
$missing = @()
foreach ($line in $expectedLines) {
    $extension = $line.Trim()
    if (-not $extension -or $extension.StartsWith("#")) { continue }
    if ($installed -notcontains $extension.ToLowerInvariant()) { $missing += $extension }
}
$status = if ($missing.Count) { "missing" } else { "ready" }
$summary = if ($missing.Count) { "$($missing.Count) required extension(s) missing" } else { "All required extensions are installed" }
[ordered]@{schema=1; id="vscode-extensions"; status=$status; summary=$summary; installedVersion=""; latestVersion=""; details=$missing} | ConvertTo-Json -Compress
