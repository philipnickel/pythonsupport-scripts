# @doc
# @name: DTU Python Support - Installation Report Generator
# @description: Simplified installation report generator for DTU Python Support
# @category: Diagnostics
# @usage: .\generate_report.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Generates HTML report with system info and test results
# @/doc

param(
    [switch]$Verbose = $false,
    [switch]$NoBrowser = $false,
    [string]$InstallLog = ""
)

# Simple environment refresh for installer integration
function Refresh-Environment {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    # Add common installation paths
    $commonPaths = @(
        "$env:USERPROFILE\miniforge3",
        "$env:USERPROFILE\miniforge3\Scripts",
        "$env:USERPROFILE\miniforge3\Library\bin",
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
        "${env:ProgramFiles}\Microsoft VS Code\bin",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin"
    )
    
    foreach ($path in $commonPaths) {
        if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) {
            $env:PATH = "$env:PATH;$path"
        }
    }
}

# Collect system information
function Get-SystemInfo {
    Write-Host "  Refreshing environment variables..." -ForegroundColor Gray
    Refresh-Environment
    
    # Default configuration
    $PythonVersionDTU = "3.12"
    $DTUPackages = @("dtumathtools", "pandas", "scipy", "statsmodels", "uncertainties")
    
    Write-Host "  Detecting Python installation..." -ForegroundColor Gray
    
    # Find Python - prioritize conda Python
    $pythonPath = $null
    $pythonVersion = $null
    
    # First try to find conda Python specifically
    $condaPythonPath = "$env:USERPROFILE\miniforge3\python.exe"
    if (Test-Path $condaPythonPath) {
        Write-Host "    Found conda Python at: $condaPythonPath" -ForegroundColor Gray
        $pythonPath = $condaPythonPath
        $pythonVersion = & $condaPythonPath --version 2>$null
        Write-Host "    Python version: $pythonVersion" -ForegroundColor Gray
    } else {
        Write-Host "    Conda Python not found, checking PATH..." -ForegroundColor Gray
        # Fallback to any python in PATH
        try {
            $pythonPath = Get-Command python -ErrorAction Stop | Select-Object -ExpandProperty Source
            $pythonVersion = python --version 2>$null
            Write-Host "    Found Python in PATH: $pythonPath" -ForegroundColor Gray
            Write-Host "    Python version: $pythonVersion" -ForegroundColor Gray
        } catch { 
            Write-Host "    No Python found in PATH" -ForegroundColor Gray
        }
    }
    
    Write-Host "  Detecting conda installation..." -ForegroundColor Gray
    # Find conda
    $condaPath = $null
    $condaVersion = $null
    $condaBase = $null
    try {
        $condaPath = Get-Command conda -ErrorAction Stop | Select-Object -ExpandProperty Source
        $condaVersion = conda --version 2>$null
        $condaBase = conda info --base 2>$null
        Write-Host "    Found conda at: $condaPath" -ForegroundColor Gray
        Write-Host "    Conda version: $condaVersion" -ForegroundColor Gray
        Write-Host "    Conda base: $condaBase" -ForegroundColor Gray
    } catch { 
        Write-Host "    No conda found in PATH" -ForegroundColor Gray
    }
    
    Write-Host "  Detecting VS Code installation..." -ForegroundColor Gray
    # Find VS Code
    $codePath = $null
    $codeVersion = $null
    try {
        $codePath = Get-Command code -ErrorAction Stop | Select-Object -ExpandProperty Source
        $codeVersion = code --version 2>$null | Select-Object -First 1
        Write-Host "    Found VS Code at: $codePath" -ForegroundColor Gray
        Write-Host "    VS Code version: $codeVersion" -ForegroundColor Gray
    } catch { 
        Write-Host "    No VS Code found in PATH" -ForegroundColor Gray
    }
    
    # Get VS Code extensions
    $extensions = @()
    if ($codePath) {
        Write-Host "    Getting VS Code extensions..." -ForegroundColor Gray
        $extensions = & $codePath --list-extensions 2>$null | Select-Object -First 10
        Write-Host "    Found $($extensions.Count) VS Code extensions" -ForegroundColor Gray
    }
    
    # Get hardware info
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    
    # Return system info object
    return @{
        OS = "$($PSVersionTable.OS) ($([System.Environment]::OSVersion.VersionString))"
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Architecture = [System.Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE')
        ComputerModel = $computerSystem.Model
        Processor = $computerSystem.Name
        Memory = "$([math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)) GB"
        PythonPath = $pythonPath
        PythonVersion = $pythonVersion
        CondaPath = $condaPath
        CondaVersion = $condaVersion
        CondaBase = $condaBase
        VSCodePath = $codePath
        VSCodeVersion = $codeVersion
        VSCodeExtensions = $extensions
        PythonVersionDTU = $PythonVersionDTU
        DTUPackages = $DTUPackages
    }
}

# Format system information for display
function Format-SystemInfo {
    param([hashtable]$SystemInfo)
    
    Write-Output "=== System Information ==="
    Write-Output "Operating System: $($SystemInfo.OS)"
    Write-Output "PowerShell Version: $($SystemInfo.PowerShellVersion)"
    Write-Output "Architecture: $($SystemInfo.Architecture)"
    Write-Output ""
    
    Write-Output "=== Hardware Information ==="
    Write-Output "Model: $($SystemInfo.ComputerModel)"
    Write-Output "Processor: $($SystemInfo.Processor)"
    Write-Output "Memory: $($SystemInfo.Memory)"
    Write-Output ""
    
    Write-Output "=== Python Environment ==="
    Write-Output "Python Location: $(if ($SystemInfo.PythonPath) { $SystemInfo.PythonPath } else { 'Not found' })"
    Write-Output "Python Version: $(if ($SystemInfo.PythonVersion) { $SystemInfo.PythonVersion } else { 'Not found' })"
    Write-Output "Conda Location: $(if ($SystemInfo.CondaPath) { $SystemInfo.CondaPath } else { 'Not found' })"
    Write-Output "Conda Version: $(if ($SystemInfo.CondaVersion) { $SystemInfo.CondaVersion } else { 'Not found' })"
    Write-Output "Conda Base: $(if ($SystemInfo.CondaBase) { $SystemInfo.CondaBase } else { 'Not found' })"
    Write-Output ""
    
    Write-Output "=== DTU Configuration ==="
    Write-Output "Expected Python Version: $($SystemInfo.PythonVersionDTU)"
    Write-Output "Required DTU Packages: $($SystemInfo.DTUPackages -join ', ')"
    Write-Output ""
    
    Write-Output "=== VS Code Environment ==="
    Write-Output "VS Code Location: $(if ($SystemInfo.VSCodePath) { $SystemInfo.VSCodePath } else { 'Not found' })"
    Write-Output "VS Code Version: $(if ($SystemInfo.VSCodeVersion) { $SystemInfo.VSCodeVersion } else { 'Not found' })"
    Write-Output "Installed Extensions:"
    if ($SystemInfo.VSCodeExtensions) {
        $SystemInfo.VSCodeExtensions | ForEach-Object { Write-Output "  $_" }
    } else {
        Write-Output "  No extensions found"
    }
}

# Run first year tests
function Test-FirstYearSetup {
    param([hashtable]$SystemInfo)
    
    Write-Output "=== First Year Setup Test ==="
    Write-Output ""
    
    $failCount = 0
    
    # Test 1: Miniforge Installation
    Write-Output "Testing Miniforge Installation..."
    $miniforgePath = "$env:USERPROFILE\miniforge3"
    if ((Test-Path $miniforgePath) -and ($SystemInfo.CondaPath)) {
        Write-Output "PASS: Miniforge installed at $miniforgePath"
    } else {
        Write-Output "FAIL: Miniforge not found or conda command not available"
        $failCount++
    }
    Write-Output ""
    
    # Test 2: Python Version
    Write-Output "Testing Python Version..."
    $ExpectedVersion = "3.12"
    $InstalledVersion = $SystemInfo.PythonVersion
    $PythonPath = $SystemInfo.PythonPath
    
    if (($InstalledVersion -like "$ExpectedVersion*") -and ($PythonPath -like "*miniforge3*")) {
        Write-Output "PASS: Python $InstalledVersion from miniforge"
    } else {
        Write-Output "FAIL: Expected Python $ExpectedVersion from miniforge, found $InstalledVersion at $PythonPath"
        $failCount++
    }
    Write-Output ""
    
    # Test 3: DTU Packages
    Write-Output "Testing DTU Packages..."
    
    # Try to use conda Python with environment activation
    $condaPythonPath = "$env:USERPROFILE\miniforge3\python.exe"
    $condaScriptsPath = "$env:USERPROFILE\miniforge3\Scripts"
    
    if (Test-Path $condaPythonPath) {
        # Use conda Python directly
        $PythonCmd = $condaPythonPath
        Write-Output "Using conda Python: $PythonCmd"
        
        $packageTest = & $PythonCmd -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('All packages imported successfully')" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "PASS: All DTU packages imported successfully"
        } else {
            Write-Output "FAIL: Some DTU packages failed to import"
            $failCount++
        }
    } elseif ($SystemInfo.PythonPath) {
        # Fallback to detected Python
        $PythonCmd = $SystemInfo.PythonPath
        Write-Output "Using fallback Python: $PythonCmd"
        
        $packageTest = & $PythonCmd -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('All packages imported successfully')" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "PASS: All DTU packages imported successfully"
        } else {
            Write-Output "FAIL: Some DTU packages failed to import"
            $failCount++
        }
    } else {
        Write-Output "FAIL: No Python available for package testing"
        $failCount++
    }
    Write-Output ""
    
    # Test 4: VS Code
    Write-Output "Testing VS Code..."
    if ($SystemInfo.VSCodePath) {
        $codeTest = & $SystemInfo.VSCodePath --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "PASS: VS Code $($codeTest | Select-Object -First 1)"
        } else {
            Write-Output "FAIL: VS Code not available"
            $failCount++
        }
    } else {
        Write-Output "FAIL: VS Code not available"
        $failCount++
    }
    Write-Output ""
    
    # Test 5: VS Code Extensions
    Write-Output "Testing VS Code Extensions..."
    if ($SystemInfo.VSCodePath) {
        $pythonExtension = & $SystemInfo.VSCodePath --list-extensions 2>$null | Where-Object { $_ -eq "ms-python.python" }
        if ($pythonExtension) {
            Write-Output "PASS: Python extension installed"
            $jupyterExtension = & $SystemInfo.VSCodePath --list-extensions 2>$null | Where-Object { $_ -eq "ms-toolsai.jupyter" }
            if ($jupyterExtension) {
                Write-Output "PASS: Jupyter extension installed"
            } else {
                Write-Output "FAIL: Jupyter extension missing"
                $failCount++
            }
        } else {
            Write-Output "FAIL: Python extension missing"
            $failCount++
        }
    } else {
        Write-Output "FAIL: VS Code not available for extension testing"
        $failCount++
    }
    Write-Output ""
    
    # Test 6: Conda Availability
    Write-Output "Testing Conda Availability..."
    if (Get-Command conda -ErrorAction SilentlyContinue) {
        Write-Output "PASS: Conda command is available"
        $condaTest = powershell.exe -Command "conda --version" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "PASS: Conda is available in new PowerShell sessions"
        } else {
            Write-Output "FAIL: Conda not available in new PowerShell sessions"
            $failCount++
        }
    } else {
        Write-Output "FAIL: Conda command not available"
        $failCount++
    }
    
    Write-Output ""
    Write-Output "════════════════════════════════════════"
    
    if ($failCount -eq 0) {
        Write-Output "OVERALL RESULT: PASS - All components working"
        return 0
    } else {
        Write-Output "OVERALL RESULT: FAIL - $failCount component(s) failed"
        return 1
    }
}

# Generate HTML report (simplified)
function New-HTMLReport {
    param(
        [hashtable]$SystemInfo,
        [string]$FormattedSystemInfo,
        [string]$TestResults,
        [string]$InstallLog = ""
    )
    
    $outputFile = "$env:TEMP\dtu_installation_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Parse test results for summary
    $passCount = ($testResults -split "`n" | Where-Object { $_ -like "PASS:*" }).Count
    $failCount = ($testResults -split "`n" | Where-Object { $_ -like "FAIL:*" }).Count
    $totalCount = $passCount + $failCount
    
    # Status message
    if (($failCount -eq 0) -and ($totalCount -gt 0)) {
        $statusMessage = "Everything is set up and working correctly"
        $statusClass = "status-success"
    } elseif ($failCount -eq 1) {
        $statusMessage = "Setup is mostly complete with one issue to resolve"
        $statusClass = "status-warning"
    } elseif ($failCount -gt 1) {
        $statusMessage = "Several setup issues need to be resolved"
        $statusClass = "status-error"
    } else {
        $statusMessage = "No tests completed"
        $statusClass = "status-unknown"
    }
    
    # Read installation log if available
    if (($InstallLog) -and (Test-Path $InstallLog)) {
        $installLogContent = Get-Content $InstallLog -Raw -ErrorAction SilentlyContinue
    } elseif (($env:INSTALL_LOG) -and (Test-Path $env:INSTALL_LOG)) {
        $installLogContent = Get-Content $env:INSTALL_LOG -Raw -ErrorAction SilentlyContinue
    } else {
        $installLogContent = "Installation log not available"
    }
    
    # Simplified HTML (keeping the existing structure but removing complex features)
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DTU Python Installation Support - First Year</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #000000; background: #DADADA; padding: 20px; margin: 0; }
        .container { max-width: 1000px; margin: 0 auto; background: #ffffff; border: 1px solid #ccc; }
        header { background: #990000; color: #ffffff; padding: 30px 20px; display: flex; align-items: center; gap: 25px; }
        .header-left { flex-shrink: 0; }
        .header-content { flex: 1; }
        .dtu-logo { height: 50px; filter: brightness(0) invert(1); }
        h1 { font-size: 1.9em; margin: 0; line-height: 1.2; font-weight: bold; }
        .subtitle { font-size: 1.2em; margin-top: 8px; opacity: 0.9; font-weight: normal; }
        .timestamp { font-size: 0.9em; margin-top: 12px; opacity: 0.8; }
        .summary { display: flex; justify-content: center; padding: 30px; background: #f5f5f5; border-bottom: 1px solid #ccc; }
        .status-message { text-align: center; }
        .status-text { font-size: 1.4em; font-weight: 600; margin-bottom: 5px; }
        .status-details { font-size: 0.9em; color: #666; }
        .status-success .status-text { color: #008835; }
        .status-warning .status-text { color: #f57c00; }
        .status-error .status-text { color: #E83F48; }
        .status-unknown .status-text { color: #666; }
        .category-section { margin: 20px 0; padding: 0 20px; }
        .category-header { font-size: 1.3em; font-weight: bold; color: #990000; padding: 15px 0; border-bottom: 2px solid #990000; margin-bottom: 15px; }
        .diagnostic-card { background: white; border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden; margin-bottom: 15px; }
        .diagnostic-header { padding: 12px 16px; background: #f8f9fa; font-weight: 600; font-size: 1.1em; color: #333; }
        .diagnostic-details { padding: 16px; background: #f8f9fa; border-top: 1px solid #dee2e6; }
        .diagnostic-log { font-family: 'Consolas', 'Monaco', 'Courier New', monospace; white-space: pre-wrap; line-height: 1.4; font-size: 0.9em; color: #333; max-height: 400px; overflow-y: auto; }
        footer { text-align: center; padding: 20px; background: #990000; color: #ffffff; }
        footer p { margin: 5px 0; }
        .footer-logo { height: 30px; margin: 10px 0; filter: brightness(0) invert(1); }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="header-left">
                <img src="https://designguide.dtu.dk/-/media/subsites/designguide/design-basics/logo/dtu_logo_corporate_red_rgb.png" 
                     alt="DTU Logo" class="dtu-logo" onerror="this.style.display='none'">
            </div>
            <div class="header-content">
                <h1>DTU Python Installation Support</h1>
                <div class="subtitle">Installation Summary</div>
                <div class="timestamp">Generated on: $timestamp</div>
            </div>
        </header>
        
        <div class="summary">
            <div class="status-message $statusClass">
                <div class="status-text">$statusMessage</div>
                <div class="status-details">$passCount of $totalCount components working properly</div>
            </div>
        </div>
        
        <div class="diagnostics">
            <div class="category-section">
                <div class="category-header">First Year Setup Validation</div>
                <div class="diagnostic-card">
                    <div class="diagnostic-header">Test Results</div>
                    <div class="diagnostic-details">
                        <div class="diagnostic-log">$($testResults -replace '"', '\"')</div>
                    </div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header">System Information</div>
                <div class="diagnostic-card">
                    <div class="diagnostic-header">System Details</div>
                    <div class="diagnostic-details">
                        <div class="diagnostic-log">$($formattedSystemInfo -replace '"', '\"')</div>
                    </div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header">Installation Log</div>
                <div class="diagnostic-card">
                    <div class="diagnostic-header">Complete Installation Output</div>
                    <div class="diagnostic-details">
                        <div class="diagnostic-log">$($installLogContent -replace '"', '\"')</div>
                    </div>
                </div>
            </div>
        </div>
        
        <footer>
            <img src="https://designguide.dtu.dk/-/media/subsites/designguide/design-basics/logo/dtu_logo_corporate_red_rgb.png" 
                 alt="DTU Logo" class="footer-logo" onerror="this.style.display='none'">
            <p><strong>DTU Python Installation Support</strong></p>
            <p>Technical University of Denmark | Danmarks Tekniske Universitet</p>
        </footer>
    </div>
</body>
</html>
"@

    $htmlContent | Out-File -FilePath $outputFile -Encoding UTF8
    return $outputFile, $LASTEXITCODE
}

# Main execution
function Main {
    Write-Host "Starting DTU Python Support Diagnostics..." -ForegroundColor Green
    Write-Host ""
    
    try {
        # Step 1: Collect system information
        Write-Host "Step 1/4: Collecting system information..." -ForegroundColor Cyan
        $systemInfo = Get-SystemInfo
        Write-Host "✓ System information collected" -ForegroundColor Green
        
        # Step 2: Format system information
        Write-Host "Step 2/4: Formatting system information..." -ForegroundColor Cyan
        $formattedSystemInfo = Format-SystemInfo -SystemInfo $systemInfo | Out-String
        Write-Host "✓ System information formatted" -ForegroundColor Green
        
        # Step 3: Run diagnostic tests
        Write-Host "Step 3/4: Running diagnostic tests..." -ForegroundColor Cyan
        $testResults = Test-FirstYearSetup -SystemInfo $systemInfo 2>&1 | Out-String
        $testExitCode = $LASTEXITCODE
        Write-Host "✓ Diagnostic tests completed" -ForegroundColor Green
        
        # Display results in console
        Write-Host ""
        Write-Host "=== CONSOLE OUTPUT ===" -ForegroundColor Yellow
        Write-Host $formattedSystemInfo
        Write-Host $testResults
        Write-Host "=====================" -ForegroundColor Yellow
        Write-Host ""
        
        # Step 4: Generate HTML report
        Write-Host "Step 4/4: Generating HTML report..." -ForegroundColor Cyan
        $reportFile, $exitCode = New-HTMLReport -SystemInfo $systemInfo -FormattedSystemInfo $formattedSystemInfo -TestResults $testResults -InstallLog $InstallLog
        
        Write-Host "✓ HTML report generated: $reportFile" -ForegroundColor Green
        
        # Open report in browser
        if (-not $NoBrowser) {
            Write-Host "Opening report in browser..." -ForegroundColor Cyan
            Start-Process $reportFile
            Write-Host "✓ Report opened in browser" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "=== DIAGNOSTICS COMPLETE ===" -ForegroundColor Green
        return $testExitCode
    } catch {
        Write-Host "❌ Failed to generate report: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        return 1
    }
}

# Only run main if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference = "Continue"
    
    try {
        Write-Host "Starting DTU Python Support Diagnostics..." -ForegroundColor Green
        $exitCode = Main
    } catch {
        Write-Host "FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $exitCode = 1
    }
    
    Write-Host "Script completed with exit code: $exitCode" -ForegroundColor Cyan
    
    # Keep terminal open for one-liner usage
    Write-Host "Press Enter to continue..." -ForegroundColor Yellow
    Read-Host
    
    # Prevent script from exiting and closing terminal
    Write-Host "Script finished. Terminal will remain open." -ForegroundColor Green
}
