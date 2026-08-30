# @doc
# @name: DTU Miniforge status
# @description: Check the installed DTU Miniforge release on Windows
# @category: Checks
# @/doc

$ErrorActionPreference = "Stop"
$installDir = Join-Path $env:USERPROFILE "miniforge3-dtu"
$condaExe = Join-Path $installDir "Scripts\conda.exe"
$marker = Join-Path $installDir ".dtu-python-support.json"
$installed = ""
$installedDtu = $false
$latest = ""
$details = @()

if (Test-Path $marker -PathType Leaf) {
    try {
        $installed = ([IO.File]::ReadAllText($marker) | ConvertFrom-Json).dtuRelease
        $installedDtu = -not [string]::IsNullOrWhiteSpace($installed)
    } catch { }
}
if ([string]::IsNullOrWhiteSpace($installed)) {
    $installerInfo = Join-Path $installDir ".installer.info"
    if (Test-Path $installerInfo -PathType Leaf) {
        try {
            $installed = ([IO.File]::ReadAllText($installerInfo) | ConvertFrom-Json).version
            if ($installed) { $details += "Installer version found, but the DTU release is unknown" }
        } catch { }
    }
}

try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/dtudk/pythonsupport-forge/releases/latest" `
                                 -UseBasicParsing -TimeoutSec 5
    $latest = [string]$release.tag_name
} catch { }

function Convert-ReleaseKey([string]$Value) {
    if ($Value -notmatch '^(\d+)\.(\d+)\.(\d+)(?:-(\d+))?$') { return $null }
    return @([int64]$Matches[1], [int64]$Matches[2], [int64]$Matches[3], [int64]$(if ($Matches[4]) { $Matches[4] } else { 0 }))
}

function Compare-Release([string]$Left, [string]$Right) {
    $a = Convert-ReleaseKey $Left
    $b = Convert-ReleaseKey $Right
    if ($null -eq $a -or $null -eq $b) { return $null }
    for ($i = 0; $i -lt 4; $i++) {
        if ($a[$i] -lt $b[$i]) { return -1 }
        if ($a[$i] -gt $b[$i]) { return 1 }
    }
    return 0
}

$status = "unknown"
$summary = "DTU Miniforge is not installed"
if (-not (Test-Path $condaExe -PathType Leaf)) {
    $status = "missing"
} elseif ([string]::IsNullOrWhiteSpace($installed)) {
    $summary = "DTU Miniforge is installed - version unknown"
    $details = @("This installation predates DTU release markers")
} elseif (-not $installedDtu) {
    $summary = "DTU Miniforge is installed - DTU release unknown"
} elseif ([string]::IsNullOrWhiteSpace($latest)) {
    $summary = "DTU Miniforge $installed - latest version unavailable"
    $details += "Could not reach the DTU release service"
} else {
    $comparison = Compare-Release $installed $latest
    if ($installed -eq $latest) {
        $status = "ready"
        $summary = "DTU Miniforge $installed"
    } elseif ($comparison -eq -1) {
        $status = "outdated"
        $summary = "DTU Miniforge $installed - update $latest available"
        $details += "Updates are informational and are not installed automatically"
    } elseif ($comparison -eq 1) {
        $status = "ready"
        $summary = "DTU Miniforge $installed - ahead of public release $latest"
    } else {
        $summary = "DTU Miniforge $installed - latest is $latest"
        $details += "The release tags could not be compared safely"
    }
}

[ordered]@{
    schema = 1; id = "miniforge"; status = $status; summary = $summary
    installedVersion = [string]$installed; latestVersion = [string]$latest; details = $details
} | ConvertTo-Json -Compress
