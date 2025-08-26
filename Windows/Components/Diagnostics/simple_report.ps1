# @doc
# @name: DTU Python Support Health Check
# @description: Quick health check for DTU Python Support installation
# @category: Diagnostics
# @usage: . .\health_check.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Fast verification of core components and common issues
# @/doc

param(
    [switch]$Verbose = $false,
    [switch]$AutoFix = $false
)

Write-Host "DTU Python Support - Health Check" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$healthIssues = @()
$healthStatus = $true

# Quick function to test and report
function Test-HealthItem {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FailureMessage,
        [scriptblock]$Fix = $null
    )
    
    Write-Host "Checking $Name... " -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "[OK] OK" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] FAIL" -ForegroundColor Red
            $script:healthIssues += "$Name : $FailureMessage"
            $script:healthStatus = $false
            
            if ($AutoFix -and $Fix) {
                Write-Host "  Attempting fix..." -ForegroundColor Yellow
                try {
                    & $Fix
                    Write-Host "  [FIXED] Fixed" -ForegroundColor Green
                } catch {
                    Write-Host "  [ERROR] Fix failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    } catch {
        Write-Host "✗ ERROR" -ForegroundColor Red
        $script:healthIssues += "$Name : $($_.Exception.Message)"
        $script:healthStatus = $false
    }
}

# Health checks
Test-HealthItem "Python Command" {
    try {
        $pythonTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "python --version" -Wait -PassThru -WindowStyle Hidden
        return $pythonTest.ExitCode -eq 0
    } catch { return $false }
} "Python not found in fresh shell PATH"

Test-HealthItem "Conda Command" {
    try {
        $condaTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "conda --version" -Wait -PassThru -WindowStyle Hidden
        return $condaTest.ExitCode -eq 0
    } catch { return $false }
} "Conda not found in fresh shell PATH"

Test-HealthItem "VSCode Command" {
    try {
        $codeTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "code --version" -Wait -PassThru -WindowStyle Hidden
        return $codeTest.ExitCode -eq 0
    } catch { return $false }
} "VSCode not found in fresh shell PATH" -Fix {
    # Try to add VSCode to PATH
    $vscodeLocations = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
        "${env:ProgramFiles}\Microsoft VS Code\bin",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin"
    )
    
    foreach ($location in $vscodeLocations) {
        if (Test-Path $location) {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notlike "*$location*") {
                [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$location", "User")
                $env:PATH = "$env:PATH;$location"
            }
            break
        }
    }
}

Test-HealthItem "First Year Environment" {
    try {
        $envTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "conda env list" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\health_envs.txt"
        if ($envTest.ExitCode -eq 0) {
            $envs = Get-Content "$env:TEMP\health_envs.txt" -Raw -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\health_envs.txt" -ErrorAction SilentlyContinue
            return $envs -like "*first_year*"
        }
        return $false
    } catch { return $false }
} "first_year conda environment not found in fresh shell" -Fix {
    conda create -n first_year python=3.11 -y
}

Test-HealthItem "Essential Packages" {
    try {
        $packagesTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "conda list -n first_year numpy pandas matplotlib" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\health_packages.txt"
        if ($packagesTest.ExitCode -eq 0) {
            $packages = Get-Content "$env:TEMP\health_packages.txt" -Raw -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\health_packages.txt" -ErrorAction SilentlyContinue
            return ($packages -like "*numpy*") -and ($packages -like "*pandas*") -and ($packages -like "*matplotlib*")
        }
        return $false
    } catch { return $false }
} "Essential packages missing from first_year environment in fresh shell" -Fix {
    conda install -n first_year -y numpy pandas matplotlib scipy scikit-learn jupyter ipython requests seaborn
}

Test-HealthItem "PowerShell Profile" {
    if (Test-Path $PROFILE.CurrentUserCurrentHost) {
        $content = Get-Content $PROFILE.CurrentUserCurrentHost -Raw
        return $content -like "*conda initialize*"
    }
    return $false
} "Conda not initialized in PowerShell profile" -Fix {
    conda init powershell
}

# System checks
Test-HealthItem "Disk Space" {
    $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($env:USERPROFILE).TrimEnd('\'))
    return ($drive.Free / 1GB) -gt 1
} "Less than 1GB free disk space available"

Test-HealthItem "Network Connectivity" {
    try {
        $response = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 5 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch { return $false }
} "Cannot reach GitHub (network/firewall issue)"

# Summary
Write-Host ""
Write-Host "Health Check Summary" -ForegroundColor White
Write-Host "===================" -ForegroundColor White

if ($healthStatus) {
    Write-Host "[OK] All health checks passed!" -ForegroundColor Green
    Write-Host "Your DTU Python Support installation is healthy." -ForegroundColor Green
} else {
    Write-Host "[FAIL] Health check failed with $($healthIssues.Count) issue(s):" -ForegroundColor Red
    foreach ($issue in $healthIssues) {
        Write-Host "  • $issue" -ForegroundColor Yellow
    }
    
    Write-Host ""
    if (-not $AutoFix) {
        Write-Host "Run with -AutoFix to attempt automatic repairs." -ForegroundColor Yellow
    }
    Write-Host "For detailed verification, run: .\verify_installation.ps1" -ForegroundColor Yellow
    Write-Host "For help, visit: https://pythonsupport.dtu.dk" -ForegroundColor Yellow
}

exit $(if ($healthStatus) { 0 } else { 1 })