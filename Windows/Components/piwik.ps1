<#
.SYNOPSIS
  Piwik Analytics Utility (Windows PowerShell port)
.DESCRIPTION
  Enhanced analytics tracking utility for monitoring installation script usage
  and success rates with GDPR compliance.
  Tracks installation events to Piwik PRO for usage analytics and error
  monitoring with enhanced features and GDPR opt-out support.
.NOTES
  Requirements: Invoke-WebRequest, internet connection, Windows
  Usage: . .\piwik_utility_win.ps1; piwik_log "event_name" { <command> <args> }
#>

# === CONFIGURATION ===
$PIWIK_URL    = "https://pythonsupport.piwik.pro/ppms.php"
$SITE_ID      = "0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
$GITHUB_REPO  = "dtudk/pythonsupport-page"

# === GDPR COMPLIANCE ===

function Is-AnalyticsDisabled {
    # In CI mode, always enable analytics
    if ($env:PIS_ENV -eq "CI") { return $false }

    $optOutFile = "$env:TEMP\piwik_analytics_choice"
    if (Test-Path $optOutFile) {
        $choice = Get-Content $optOutFile -ErrorAction SilentlyContinue
        if ($choice -eq "opt-out") { return $true }
        elseif ($choice -eq "opt-in") { return $false }
    }
    return $false  # Default to enabled
}

function Show-AnalyticsChoiceDialog {
    $optOutFile = "$env:TEMP\piwik_analytics_choice"
    if (Test-Path $optOutFile) { return }

    Add-Type -AssemblyName PresentationFramework
    $result = [System.Windows.MessageBox]::Show(
        "This installation script collects anonymous usage analytics to help improve the installation process and identify potential issues.`n`nData collected:`n- Installation success/failure events`n- Operating system and version information`n- System architecture`n- Installation duration (for performance monitoring)`n- Git commit SHA (for version tracking)`n`nNo personal information is collected or stored.`n`nDo you consent to analytics collection?",
        "Analytics Consent",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Information
    )
    if ($result -eq "Yes") {
        "opt-in" | Set-Content $optOutFile
        Write-Host "Analytics enabled. Thank you for helping improve the installation process!"
    } else {
        "opt-out" | Set-Content $optOutFile
        Write-Host "Analytics disabled. No data will be collected."
    }
}

function Check-AnalyticsChoice {
    if ($env:PIS_ENV -eq "CI") { return }
    $optOutFile = "$env:TEMP\piwik_analytics_choice"
    if (-not (Test-Path $optOutFile)) {
        Show-AnalyticsChoiceDialog
    }
}

# === ENVIRONMENT DETECTION ===

function Detect-Environment {
    if ($env:PIS_ENV) {
        switch ($env:PIS_ENV) {
            "CI"         { return "CI" }
            "local-dev"  { return "DEV" }
            "staging"    { return "STAGING" }
            "production" { return "PROD" }
            default      { return "PROD" }
        }
    }
    if ($env:GITHUB_CI -eq "true" -or $env:CI -eq "true" -or $env:TRAVIS -eq "true" -or $env:CIRCLECI -eq "true") { return "CI" }
    if ($env:TESTING_MODE -eq "true" -or $env:DEV_MODE -eq "true" -or $env:DEBUG -eq "true") { return "DEV" }
    if ($env:STAGING -eq "true" -or $env:STAGE -eq "true") { return "STAGING" }
    return "PROD"
}

function Get-EnvironmentCategory {
    switch (Detect-Environment) {
        "CI"      { return "Installer_CI_win" }
        "DEV"     { return "Installer_DEV_win" }
        "STAGING" { return "Installer_STAGING_win" }
        "PROD"    { return "Installer_PROD_win" }
        default   { return "Installer_UNKNOWN_win" }
    }
}

# === HELPER FUNCTIONS ===

function Get-SystemInfo {
    $osName   = "Windows"
    $osVer    = (Get-CimInstance Win32_OperatingSystem).Version
    $osCode   = (Get-CimInstance Win32_OperatingSystem).Caption
    $arch     = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    $os       = "$osName $osVer ($osCode)"
    return @{
        OS        = $os
        OS_NAME   = $osName
        OS_VERSION= $osVer
        OS_CODENAME= $osCode
        ARCH      = $arch
    }
}

function Get-CommitSHA {
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://api.github.com/repos/$GITHUB_REPO/commits/main" -TimeoutSec 10
        $json = $response.Content | ConvertFrom-Json
        if ($json.sha) { return $json.sha.Substring(0,7) }
    } catch {}
    return "unknown"
}

function Categorize-Error {
    param([string]$Output, [int]$ExitCode)
    if ($ExitCode -eq 0) { return "" }
    if ($Output -match "(?i)permission denied|not permitted|access denied") { return "_permission_error" }
    elseif ($Output -match "(?i)network|download|curl|wget|connection|timeout") { return "_network_error" }
    elseif ($Output -match "(?i)space|disk|storage|no space") { return "_disk_error" }
    elseif ($Output -match "(?i)not found|command not found|no such file") { return "_missing_dependency" }
    elseif ($Output -match "(?i)already exists|already installed") { return "_already_exists" }
    elseif ($Output -match "(?i)version|incompatible|requires") { return "_version_error" }
    else { return "_unknown_error" }
}

# === ENHANCED TRACKING FUNCTIONS ===

function piwik_log_enhanced {
    param(
        [string]$event_name,
        [scriptblock]$block
    )
    Check-AnalyticsChoice
    if (Is-AnalyticsDisabled) {
        & $block
        return $LASTEXITCODE
    }
    $start_time = Get-Date
    $output = $block 2>&1
    $exit_code = $LASTEXITCODE
    $duration = ((Get-Date) - $start_time).TotalSeconds
    Write-Host $output

    $error_suffix = Categorize-Error $output $exit_code
    if ($error_suffix) { $event_name += $error_suffix }

    $sysinfo = Get-SystemInfo
    $commit_sha = Get-CommitSHA
    $event_category = Get-EnvironmentCategory

    $result = if ($exit_code -eq 0) { "success" } else { "failure" }
    $event_value = if ($exit_code -eq 0) { 1 } else { 0 }
    $os = $sysinfo.OS
    $arch = $sysinfo.ARCH

    $uri = $PIWIK_URL + "?idsite=$SITE_ID&rec=1&e_c=$event_category&e_a=Event&e_n=$event_name&e_v=$event_value&dimension1=$os&dimension2=$arch&dimension3=$commit_sha"

    try {
        $response = curl "$uri"
    } catch {}

    return $exit_code
}

function piwik_log {
    param(
        [string]$event_name,
        [scriptblock]$block
    )
    Check-AnalyticsChoice
    if (Is-AnalyticsDisabled) {
        & $block
        return $LASTEXITCODE
    }
    $output = & $block 2>&1
    $exit_code = $LASTEXITCODE
    Write-Host $output

    $sysinfo = Get-SystemInfo
    $commit_sha = Get-CommitSHA
    $event_category = Get-EnvironmentCategory

    $result = if ($exit_code -eq 0) { "success" } else { "failure" }
    $event_value = if ($exit_code -eq 0) { 1 } else { 0 }
    $os = $sysinfo.OS
    $arch = $sysinfo.ARCH

    # interpolating the variable directly doesnt work for some reason
    $uri = $PIWIK_URL + "?idsite=$SITE_ID&rec=1&e_c=$event_category&e_a=Event&e_n=$event_name&e_v=$event_value&dimension1=$os&dimension2=$arch&dimension3=$commit_sha"

    try {
        $response = curl "$uri"
    } catch {}
    return $exit_code
}

function piwik_log_timed {
    param(
        [string]$event_name,
        [scriptblock]$block
    )
    piwik_log_enhanced $event_name $block
}

# === UTILITY FUNCTIONS ===

function piwik_get_environment_info {
    Write-Host "=== Piwik Environment Information ==="
    $envType = Detect-Environment
    Write-Host "Detected Environment: $envType"
    Write-Host "Piwik Category: $(Get-EnvironmentCategory)"

    $sysinfo = Get-SystemInfo
    Write-Host "Operating System: $($sysinfo.OS_NAME)"
    Write-Host "OS Version: $($sysinfo.OS_VERSION)"
    if ($sysinfo.OS_CODENAME) { Write-Host "OS Codename: $($sysinfo.OS_CODENAME)" }
    Write-Host "Architecture: $($sysinfo.ARCH)"
    Write-Host "Full OS String: $($sysinfo.OS)"
    Write-Host "Commit SHA: $(Get-CommitSHA)"

    Write-Host "Analytics Choice:"
    if ($env:PIS_ENV -eq "CI") {
        Write-Host "Analytics enabled (CI mode - automatic)"
    } else {
        $optOutFile = "$env:TEMP\piwik_analytics_choice"
        if (Test-Path $optOutFile) {
            $choice = Get-Content $optOutFile -ErrorAction SilentlyContinue
            if ($choice -eq "opt-out") {
                Write-Host "Analytics disabled (user choice)"
            } else {
                Write-Host "Analytics enabled (user choice)"
            }
        } else {
            Write-Host "No choice made yet (will prompt on first use)"
        }
    }
    Write-Host "Environment Variables:"
    Write-Host "  PIS_ENV: $($env:PIS_ENV)"
    Write-Host "  GITHUB_CI: $($env:GITHUB_CI)"
    Write-Host "  CI: $($env:CI)"
    Write-Host "  TESTING_MODE: $($env:TESTING_MODE)"
    Write-Host "  DEV_MODE: $($env:DEV_MODE)"
    Write-Host "  STAGING: $($env:STAGING)"
    Write-Host "  DEBUG: $($env:DEBUG)"
    Write-Host "================================"
}

function piwik_test_connection {
    Check-AnalyticsChoice
    if (Is-AnalyticsDisabled) {
        Write-Host "Analytics disabled - cannot test connection"
        return 1
    }
    Write-Host "Testing Piwik connection..."

    $event_value = if ($exit_code -eq 0) { 1 } else { 0 }

    $uri = $PIWIK_URL + "?idsite=$SITE_ID&rec=1&e_c=$event_category&e_a=Event&e_n=$event_name&e_v=$event_value&dimension1=$os&dimension2=$arch&dimension3=$commit_sha"

    try {
        $response = curl $uri
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 202) {
            Write-Host "✅ Piwik connection successful (HTTP $($response.StatusCode))"
            return 0
        } else {
            Write-Host "❌ Piwik connection failed (HTTP $($response.StatusCode))"
            return 1
        }
    } catch {
        Write-Host "❌ Piwik connection failed (exception)"
        return 1
    }
}

function piwik_opt_out {
    "opt-out" | Set-Content "$env:TEMP\piwik_analytics_choice"
    Write-Host "Analytics disabled. No data will be collected."
}

function piwik_opt_in {
    "opt-in" | Set-Content "$env:TEMP\piwik_analytics_choice"
    Write-Host "Analytics enabled. Thank you for helping improve the installation process!"
}

function piwik_reset_choice {
    Remove-Item "$env:TEMP\piwik_analytics_choice" -ErrorAction SilentlyContinue
    Write-Host "Analytics choice reset. You will be prompted again on next use."
}
