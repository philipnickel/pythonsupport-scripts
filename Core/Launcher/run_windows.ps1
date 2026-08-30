param(
    [Parameter(Mandatory = $true)][string]$Script
)

$ErrorActionPreference = "Stop"

if ($Script -notmatch '^(Core|Utils)/.+\.ps1$' -or (($Script -split '[\\/]') -contains '..')) {
    throw "Launcher script path must be a safe Core/ or Utils/ .ps1 path: $Script"
}

$bundleRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if ([string]::IsNullOrWhiteSpace($env:PS_ENV) -and
    [string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT) -and
    [string]::IsNullOrWhiteSpace($env:PS_REPO_URL) -and
    [string]::IsNullOrWhiteSpace($env:PS_REPO_USER) -and
    [string]::IsNullOrWhiteSpace($env:PS_BRANCH) -and
    [string]::IsNullOrWhiteSpace($env:PS_FORGE_URL) -and
    [string]::IsNullOrWhiteSpace($env:PS_VSCODE_URL)) {
    $env:PS_ENV = "offline"
    $env:PS_BUNDLE_ROOT = $bundleRoot
} elseif ($env:PS_ENV -eq "offline" -and [string]::IsNullOrWhiteSpace($env:PS_BUNDLE_ROOT)) {
    $env:PS_BUNDLE_ROOT = $bundleRoot
}

. (Join-Path $bundleRoot "Core\env.ps1")
Invoke-RepositoryScript $Script
