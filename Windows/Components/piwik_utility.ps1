<#
.SYNOPSIS
  Piwik Analytics Utility (Windows PowerShell port)
.DESCRIPTION
  Analytics tracking utility for monitoring installation script usage
  and success rates with GDPR compliance.
  Tracks installation events to Piwik PRO for usage analytics and error
  monitoring with enhanced features and GDPR opt-out support.
.NOTES
  Requirements: Invoke-WebRequest, internet connection, Windows
  Usage: . .\piwik_utility.ps1; Piwik-Log <code>
#>

# === CONFIGURATION ===

$PIWIK_URL    = "https://pythonsupport.piwik.pro/ppms.php"
$SITE_ID      = "0bc7bce7-fb4d-4159-a809-e6bab2b3a431"
$GITHUB_REPO  = "dtudk/pythonsupport-scripts"
$CATEGORY     = "AUTOINSTALLS"
$EVENT_ACTION = "Event"
$EVENT_NAME   = "Log"

# === GDPR COMPLIANCE ===

function Is-Analytics-Disabled {
    # In CI mode, always enable analytics
    if (Is-CI-Mode) { return $false }

    $optOutFile = "$env:TEMP\piwik_analytics_choice"
    if (Test-Path $optOutFile) {
        $choice = Get-Content $optOutFile -ErrorAction SilentlyContinue
        if ($choice -eq "opt-out") { return $true }
        elseif ($choice -eq "opt-in") { return $false }
    }
    return $false  # Default to enabled
}

function Show-Analytics-Choice-Dialog {
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

function Check-Analytics-Choice {
    if (Is-CI-Mode) { return }
    $optOutFile = "$env:TEMP\piwik_analytics_choice"
    if (-not (Test-Path $optOutFile)) {
        Show-Analytics-Choice-Dialog
    }
}

# === SIMPLE CI DETECTION ===

function Is-CI-Mode {
    return ($env:PIS_ENV -eq "CI") -or ($env:GITHUB_CI -eq "true") -or ($env:CI -eq "true")
}

# === HELPER FUNCTIONS ===

function Get-System-Info {
    $osName   = "Windows"
    $osVer    = (Get-CimInstance Win32_OperatingSystem).Version
    $osCode   = (Get-CimInstance Win32_OperatingSystem).Caption
    $arch     = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    $os       = "$osName $osVer ($osCode)"
    return @{
        OS          = $os
        OS_NAME     = $osName
        OS_VERSION  = $osVer
        OS_CODENAME = $osCode
        ARCH        = $arch
    }
}

function Get-Commit-SHA {
    # In CI environments, use GitHub environment variables
    if ($env:GITHUB_SHA) {
        return $env:GITHUB_SHA.Substring(0,7)
    }
    
    # Fallback to GitHub API
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://api.github.com/repos/$GITHUB_REPO/commits/main" -TimeoutSec 10

        $json = $response.Content | ConvertFrom-Json
        if ($json.sha) { return $json.sha.Substring(0,7) }
    } catch {}
    return "unknown"
}

function Get-URI {
    param ([int]$value)

    $sysinfo = Get-System-Info
    $commit_sha = Get-Commit-SHA

    $os = $sysinfo.OS
    $arch = $sysinfo.ARCH

    # URL encode the OS string to handle spaces and special characters
    $encoded_os = [System.Web.HttpUtility]::UrlEncode($os)

    return $PIWIK_URL + "?idsite=$SITE_ID&rec=1&e_c=$CATEGORY&e_a=$EVENT_ACTION&e_n=$EVENT_NAME&e_v=$value&dimension1=$encoded_os&dimension2=$arch&dimension3=$commit_sha"
}

# === LOGGING FUNCTIONS ===

function Piwik-Log {
    param([int]$value)

    Check-Analytics-Choice
    if (Is-Analytics-Disabled) {
        return
    }

    $uri = Get-URI $value

    # Ignore failure to log.
    try { Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 5 | Out-Null } catch {}
}

# === UTILITY FUNCTIONS ===

function Piwik-Get-Environment-Info {
    Write-Host "=== Piwik Environment Information ==="
    Write-Host "CI Mode: $(if (Is-CI-Mode) { 'Yes' } else { 'No' })"
    Write-Host "Piwik Category: $CATEGORY"

    $sysinfo = Get-System-Info
    Write-Host "Operating System: $($sysinfo.OS_NAME)"
    Write-Host "OS Version: $($sysinfo.OS_VERSION)"
    Write-Host "Architecture: $($sysinfo.ARCH)"
    Write-Host "Full OS String: $($sysinfo.OS)"
    Write-Host "Commit SHA: $(Get-Commit-SHA)"

    Write-Host "Analytics Choice:"
    if (Is-CI-Mode) {
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
    Write-Host "================================"
}

function Piwik-Test-Connection {
    Check-Analytics-Choice
    if (Is-Analytics-Disabled) {
        Write-Host "Analytics disabled - cannot test connection"
        return 1
    }
    Write-Host "Testing Piwik connection..."

    $uri = Get-URI "test-con"

    try {
        $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 202) {
            Write-Host "Piwik connection successful (HTTP $($response.StatusCode))"
            return 0
        } else {
            Write-Host "Piwik connection failed (HTTP $($response.StatusCode))"
            return 1
        }
    } catch {
        Write-Host "Piwik connection failed (exception)"
        return 1
    }
}

function Piwik-Opt-Out {
    "opt-out" | Set-Content "$env:TEMP\piwik_analytics_choice"
    Write-Host "Analytics disabled. No data will be collected."
}

function Piwik-Opt-In {
    "opt-in" | Set-Content "$env:TEMP\piwik_analytics_choice"
    Write-Host "Analytics enabled. Thank you for helping improve the installation process!"
}

function Piwik-Reset-Choice {
    Remove-Item "$env:TEMP\piwik_analytics_choice" -ErrorAction SilentlyContinue
    Write-Host "Analytics choice reset. You will be prompted again on next use."
}
