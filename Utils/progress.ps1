#!/usr/bin/env pwsh
# @doc
# @name: Progress UI (Windows)
# @description: Progress wrapper used by the Windows orchestration scripts
# @category: Utils
# @usage: . ./Utils/progress.ps1  (defines the `progress` function)
# @requirements: PowerShell 5.1+
# @notes: Minimal mirror of Utils/progress.sh. The full-screen TUI (typewriter
#   intro, spinner, scrolling log box) is intentionally left out for now and
#   can be developed in parallel - the `progress` call signature is final.
# @/doc

$ErrorActionPreference = "Stop"

# Mirror of PROGRESS_LOG_FILE in progress.sh (default: $env:TEMP\dtu_log.txt)
$script:PROGRESS_LOG_FILE = $env:PROGRESS_LOG_FILE
if (-not $script:PROGRESS_LOG_FILE) {
    $tmpBase = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
    $script:PROGRESS_LOG_FILE = Join-Path $tmpBase "dtu_log.txt"
}

function script:Show-ProgressIntro {
    # Same wording as progress_intro_lines() in progress.sh
    # TODO(parallel TUI workstream): typewriter effect like the macOS version
    Write-Host "  Welcome to the DTU Python Installation Support setup." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  This setup is for first-year DTU students."
    Write-Host "  It installs Conda, Python, the required course packages,"
    Write-Host "  and Visual Studio Code."
    Write-Host ""
    Write-Host "  It is intended for courses such as Mathematics 1a,"
    Write-Host "  Mathematics 1b, Statistics, Physics,"
    Write-Host "  and Computer Programming."
    Write-Host ""
    Write-Host "  You do not need much coding experience to complete this setup."
    Write-Host "  The installation will begin in a moment."
    Write-Host ""
}

# Params (same call shape as the bash version: progress "msg" <minutes> <cmd>):
# - Message: str
# - EstimatedMinutes: int
# - Command: scriptblock
function global:progress {
    param(
        [Parameter(Mandatory = $true, Position = 0)][string]$Message,
        [Parameter(Mandatory = $true, Position = 1)][int]$EstimatedMinutes,
        [Parameter(Mandatory = $true, Position = 2)][scriptblock]$Command
    )

    $logFile = $script:PROGRESS_LOG_FILE
    $firstStep = -not (Test-Path $logFile)

    Add-Content -Path $logFile -Value "[DTULOG]: $Message ($(Get-Date))"

    if ($firstStep) {
        Show-ProgressIntro
    }

    $duration = if ($EstimatedMinutes -eq 1) { "1 minute" } else { "$EstimatedMinutes minutes" }
    Write-Host "[$Message]"
    Write-Host "  Please do not interrupt this step - it may take up to $duration."

    # Transcript captures *everything* printed to the console (including
    # Write-Host) into the log file. If the host does not support
    # transcription, fall back to teeing the pipeline output only.
    $transcriptStarted = $false
    try {
        Start-Transcript -Path $logFile -Append | Out-Null
        $transcriptStarted = $true
    } catch { }

    $failed = $false
    $errorText = ""
    try {
        if ($transcriptStarted) {
            & $Command
        } else {
            & $Command 2>&1 | Tee-Object -FilePath $logFile -Append
        }
    } catch {
        $failed = $true
        $errorText = "$_"
    } finally {
        if ($transcriptStarted) {
            try { Stop-Transcript | Out-Null } catch { }
        }
    }

    Write-Host $Message

    if ($failed) {
        Add-Content -Path $logFile -Value "[DTULOG]: failure ($errorText)"
        Write-Host " ┗━ Failure." -ForegroundColor Red
        Write-Host "    Contact us by email or Discord:"
        Write-Host "    pythonsupport@dtu.dk | https://discord.gg/h8EVaV9ShP"
        Write-Host "    https://pythonsupport.dtu.dk/#reach-us"
        Write-Host "    Please include the file '$logFile'." -ForegroundColor Yellow
        throw "Step failed: $Message"
    }

    Add-Content -Path $logFile -Value "[DTULOG]: success"
    Write-Host " ┗━ Success!" -ForegroundColor Green
}

# Self-test: only runs when the file is executed directly, not when it is
# dot-sourced or loaded via Invoke-Expression (mirror of the BASH_SOURCE guard
# in progress.sh).
if ($PSCommandPath -and ($MyInvocation.InvocationName -ne '.')) {
    progress "Step 1/1: Installing XYZ" 15 {
        1..6 | ForEach-Object { Write-Host $_; Start-Sleep -Milliseconds 500 }
        throw "demo failure"
    }
}
