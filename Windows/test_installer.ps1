# @doc
# @name: DTU Python Support Windows Installer Test Suite
# @description: Comprehensive test suite for validating Windows installer functionality
# @category: Testing
# @usage: . .\test_installer.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Tests installer components in isolation and integration scenarios
# @/doc

param(
    [string]$TestLevel = "Basic", # Basic, Full, Integration
    [switch]$CleanInstall = $false,
    [string]$LogPath = "$env:TEMP\dtu_installer_test.log",
    [string]$Branch = "main"
)

# Initialize test results
$testResults = @{
    StartTime = Get-Date
    TestLevel = $TestLevel
    Branch = $Branch
    System = @{
        OS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
        Architecture = $env:PROCESSOR_ARCHITECTURE
        PowerShell = $PSVersionTable.PSVersion.ToString()
        User = $env:USERNAME
        IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    Tests = @()
    OverallResult = $true
    Issues = @()
}

# Logging function
function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $LogPath -Value $logMessage
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message }
    }
}

# Test function
function Invoke-Test {
    param(
        [string]$TestName,
        [string]$Description,
        [scriptblock]$TestScript,
        [string]$Category = "General"
    )
    
    Write-TestLog "Running test: $TestName" "INFO"
    $testStart = Get-Date
    
    try {
        $result = & $TestScript
        $duration = (Get-Date) - $testStart
        
        $testRecord = @{
            Name = $TestName
            Description = $Description
            Category = $Category
            Result = $result
            Duration = $duration.TotalSeconds
            StartTime = $testStart
            Issues = @()
        }
        
        if ($result) {
            Write-TestLog "✓ $TestName: PASS ($($duration.TotalSeconds.ToString("F2"))s)" "SUCCESS"
        } else {
            Write-TestLog "✗ $TestName: FAIL ($($duration.TotalSeconds.ToString("F2"))s)" "ERROR"
            $script:testResults.OverallResult = $false
        }
        
        $script:testResults.Tests += $testRecord
        return $result
        
    } catch {
        $duration = (Get-Date) - $testStart
        $errorMessage = $_.Exception.Message
        
        Write-TestLog "✗ $TestName: ERROR - $errorMessage ($($duration.TotalSeconds.ToString("F2"))s)" "ERROR"
        
        $testRecord = @{
            Name = $TestName
            Description = $Description
            Category = $Category
            Result = $false
            Duration = $duration.TotalSeconds
            StartTime = $testStart
            Issues = @($errorMessage)
        }
        
        $script:testResults.Tests += $testRecord
        $script:testResults.OverallResult = $false
        $script:testResults.Issues += "$TestName : $errorMessage"
        
        return $false
    }
}

Write-Host "DTU Python Support - Windows Installer Test Suite" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Test Level: $TestLevel" -ForegroundColor Gray
Write-Host "Branch: $Branch" -ForegroundColor Gray
Write-Host "Log Path: $LogPath" -ForegroundColor Gray
Write-Host ""

Write-TestLog "Starting DTU Python Support Windows Installer Test Suite"
Write-TestLog "Test Level: $TestLevel, Branch: $Branch"
Write-TestLog "System: $($testResults.System.OS), Arch: $($testResults.System.Architecture), PS: $($testResults.System.PowerShell)"

# Clean environment if requested
if ($CleanInstall) {
    Write-TestLog "Clean install requested - removing existing installation"
    
    Invoke-Test "Pre-Clean Environment" "Remove existing DTU installation for clean testing" {
        try {
            $uninstallUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/Components/Core/uninstall.ps1"
            $uninstallScript = Invoke-WebRequest -Uri $uninstallUrl -UseBasicParsing
            Invoke-Expression $uninstallScript.Content -Force
            return $true
        } catch {
            Write-TestLog "Clean environment failed: $($_.Exception.Message)" "WARNING"
            return $true # Continue with tests even if clean fails
        }
    } "Setup"
}

# Basic Tests
Write-Host "Running Basic Tests..." -ForegroundColor White

Invoke-Test "Download AutoInstall Script" "Verify main AutoInstall.ps1 can be downloaded" {
    try {
        $autoInstallUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/AutoInstall.ps1"
        $response = Invoke-WebRequest -Uri $autoInstallUrl -UseBasicParsing -TimeoutSec 30
        return $response.StatusCode -eq 200 -and $response.Content.Length -gt 1000
    } catch {
        Write-TestLog "Failed to download AutoInstall.ps1: $($_.Exception.Message)" "ERROR"
        return $false
    }
} "Download"

Invoke-Test "Download GUI Dialogs" "Verify GUI dialogs script can be downloaded" {
    try {
        $dialogsUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/Components/Shared/gui_dialogs.ps1"
        $response = Invoke-WebRequest -Uri $dialogsUrl -UseBasicParsing -TimeoutSec 30
        return $response.StatusCode -eq 200 -and $response.Content.Length -gt 1000
    } catch {
        Write-TestLog "Failed to download gui_dialogs.ps1: $($_.Exception.Message)" "ERROR"
        return $false
    }
} "Download"

Invoke-Test "Download Components" "Verify all installer components can be downloaded" {
    $componentUrls = @(
        "Windows/Components/orchestrators/first_year_students.ps1",
        "Windows/Components/Python/install.ps1",
        "Windows/Components/Python/first_year_setup.ps1", 
        "Windows/Components/VSC/install.ps1",
        "Windows/Components/Shared/error_handling.ps1"
    )
    
    $failedDownloads = @()
    
    foreach ($component in $componentUrls) {
        try {
            $url = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/$component"
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15
            if ($response.StatusCode -ne 200 -or $response.Content.Length -lt 100) {
                $failedDownloads += $component
            }
        } catch {
            $failedDownloads += $component
            Write-TestLog "Failed to download $component : $($_.Exception.Message)" "ERROR"
        }
    }
    
    if ($failedDownloads.Count -gt 0) {
        Write-TestLog "Failed to download components: $($failedDownloads -join ', ')" "ERROR"
        return $false
    }
    
    return $true
} "Download"

Invoke-Test "System Requirements Check" "Verify system meets minimum requirements" {
    $issues = @()
    
    # PowerShell version
    if ($PSVersionTable.PSVersion -lt [Version]"5.1") {
        $issues += "PowerShell version too old"
    }
    
    # Windows version
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        $issues += "Windows version not supported"
    }
    
    # Disk space
    try {
        $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($env:USERPROFILE).TrimEnd('\'))
        if (($drive.Free / 1GB) -lt 2) {
            $issues += "Insufficient disk space"
        }
    } catch {
        $issues += "Could not check disk space"
    }
    
    # Network
    try {
        $response = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -ne 200) {
            $issues += "Network connectivity issues"
        }
    } catch {
        $issues += "Network connectivity test failed"
    }
    
    if ($issues.Count -gt 0) {
        Write-TestLog "System requirements issues: $($issues -join ', ')" "ERROR"
        return $false
    }
    
    return $true
} "System"

# Full Tests (include actual installation)
if ($TestLevel -eq "Full" -or $TestLevel -eq "Integration") {
    Write-Host "Running Full Installation Tests..." -ForegroundColor White
    
    Invoke-Test "Python Installation" "Test Python/Miniforge installation component" {
        try {
            $pythonUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/Components/Python/install.ps1"
            $pythonScript = Invoke-WebRequest -Uri $pythonUrl -UseBasicParsing
            
            # Set environment for testing
            $env:REMOTE_PS = "dtudk/pythonsupport-scripts"
            $env:BRANCH_PS = $Branch
            $env:PYTHON_VERSION_PS = "3.11"
            
            Invoke-Expression $pythonScript.Content
            
            # Verify installation
            $pythonWorks = $false
            $condaWorks = $false
            
            try {
                python --version | Out-Null
                $pythonWorks = $LASTEXITCODE -eq 0
            } catch { }
            
            try {
                conda --version | Out-Null
                $condaWorks = $LASTEXITCODE -eq 0
            } catch { }
            
            return $pythonWorks -and $condaWorks
            
        } catch {
            Write-TestLog "Python installation failed: $($_.Exception.Message)" "ERROR"
            return $false
        }
    } "Installation"
    
    Invoke-Test "First Year Setup" "Test first year Python environment setup" {
        try {
            $setupUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/Components/Python/first_year_setup.ps1"
            $setupScript = Invoke-WebRequest -Uri $setupUrl -UseBasicParsing
            
            Invoke-Expression $setupScript.Content
            
            # Check if first_year environment exists
            $envs = conda env list 2>&1
            return $envs -like "*first_year*"
            
        } catch {
            Write-TestLog "First year setup failed: $($_.Exception.Message)" "ERROR"
            return $false
        }
    } "Installation"
    
    Invoke-Test "VSCode Installation" "Test Visual Studio Code installation" {
        try {
            $vscodeUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/Components/VSC/install.ps1"
            $vscodeScript = Invoke-WebRequest -Uri $vscodeUrl -UseBasicParsing
            
            Invoke-Expression $vscodeScript.Content
            
            # Check if VSCode is available
            try {
                code --version | Out-Null
                return $LASTEXITCODE -eq 0
            } catch {
                # Check if installed but not in PATH
                $vscodeLocations = @(
                    "$env:LOCALAPPDATA\Programs\Microsoft VS Code",
                    "${env:ProgramFiles}\Microsoft VS Code",
                    "${env:ProgramFiles(x86)}\Microsoft VS Code"
                )
                
                foreach ($location in $vscodeLocations) {
                    if (Test-Path $location) {
                        return $true
                    }
                }
                return $false
            }
            
        } catch {
            Write-TestLog "VSCode installation failed: $($_.Exception.Message)" "ERROR"
            return $false
        }
    } "Installation"
}

# Integration Tests
if ($TestLevel -eq "Integration") {
    Write-Host "Running Integration Tests..." -ForegroundColor White
    
    Invoke-Test "Full AutoInstall Integration" "Test complete AutoInstall.ps1 workflow" {
        try {
            # Run the full AutoInstall script in non-interactive mode
            $autoInstallUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/AutoInstall.ps1"
            $autoInstallScript = Invoke-WebRequest -Uri $autoInstallUrl -UseBasicParsing
            
            # Execute with GUI disabled and force mode
            $env:USE_GUI_DIALOGS = "false"
            & ([scriptblock]::Create($autoInstallScript.Content)) -UseGUI:$false
            
            # Run verification
            $verifyUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/Components/Diagnostics/verify_installation.ps1"
            $verifyScript = Invoke-WebRequest -Uri $verifyUrl -UseBasicParsing
            
            $verifyResult = & ([scriptblock]::Create($verifyScript.Content))
            return $LASTEXITCODE -eq 0
            
        } catch {
            Write-TestLog "Integration test failed: $($_.Exception.Message)" "ERROR"
            return $false
        }
    } "Integration"
    
    Invoke-Test "Uninstall Functionality" "Test complete uninstall workflow" {
        try {
            $uninstallUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/$Branch/Windows/Components/Core/uninstall.ps1"
            $uninstallScript = Invoke-WebRequest -Uri $uninstallUrl -UseBasicParsing
            
            & ([scriptblock]::Create($uninstallScript.Content)) -UseGUI:$false -Force
            
            # Verify uninstall
            $pythonRemoved = $true
            $condaRemoved = $true
            $vscodeRemoved = $true
            
            try {
                python --version | Out-Null
                if ($LASTEXITCODE -eq 0) { $pythonRemoved = $false }
            } catch { }
            
            try {
                conda --version | Out-Null
                if ($LASTEXITCODE -eq 0) { $condaRemoved = $false }
            } catch { }
            
            # VSCode might remain if installed system-wide
            return $pythonRemoved -and $condaRemoved
            
        } catch {
            Write-TestLog "Uninstall test failed: $($_.Exception.Message)" "ERROR"
            return $false
        }
    } "Integration"
}

# Test Summary
$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

Write-Host ""
Write-Host "Test Results Summary" -ForegroundColor White
Write-Host "===================" -ForegroundColor White

$passCount = ($testResults.Tests | Where-Object { $_.Result -eq $true }).Count
$failCount = ($testResults.Tests | Where-Object { $_.Result -eq $false }).Count
$totalTests = $testResults.Tests.Count

Write-Host "Total Tests: $totalTests" -ForegroundColor Gray
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Duration: $($testResults.Duration.ToString("F1"))s" -ForegroundColor Gray

if ($testResults.OverallResult) {
    Write-Host "Overall Result: ✓ PASS" -ForegroundColor Green
    Write-TestLog "All tests completed successfully" "SUCCESS"
} else {
    Write-Host "Overall Result: ✗ FAIL" -ForegroundColor Red
    Write-TestLog "Some tests failed - see log for details" "ERROR"
    
    if ($testResults.Issues.Count -gt 0) {
        Write-Host ""
        Write-Host "Issues Found:" -ForegroundColor Yellow
        foreach ($issue in $testResults.Issues) {
            Write-Host "  • $issue" -ForegroundColor Yellow
        }
    }
}

# Save test results
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath "$env:TEMP\dtu_test_results.json" -Encoding UTF8
Write-Host ""
Write-Host "Test log saved to: $LogPath" -ForegroundColor Gray
Write-Host "Test results saved to: $env:TEMP\dtu_test_results.json" -ForegroundColor Gray

exit $(if ($testResults.OverallResult) { 0 } else { 1 })