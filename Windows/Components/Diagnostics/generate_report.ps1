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
    
    # Extract just the version number (e.g., "3.12.11" -> "3.12")
    $VersionMatch = $InstalledVersion -match "Python (\d+\.\d+)"
    $ExtractedVersion = if ($VersionMatch) { $matches[1] } else { $InstalledVersion }
    
    if (($ExtractedVersion -like "$ExpectedVersion*") -and ($PythonPath -like "*miniforge3*")) {
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
    
    # Full HTML with all interactive features (matching macOS version)
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
        .passed { color: #008835; }
        .failed { color: #E83F48; }
        .total { color: #990000; }
        
        .download-section { text-align: center; padding: 15px; background: #f5f5f5; border-bottom: 1px solid #ccc; }
        .download-button { padding: 12px 24px; border: 2px solid #990000; background: #ffffff; color: #990000; text-decoration: none; font-weight: bold; border-radius: 4px; cursor: pointer; transition: all 0.3s; font-size: 1em; }
        .download-button:hover { background: #990000; color: #ffffff; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        
        /* Modal Styles */
        .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.5); }
        .modal-content { background-color: #fefefe; margin: 5% auto; padding: 0; border: none; width: 90%; max-width: 600px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); animation: slideIn 0.3s ease-out; }
        @keyframes slideIn { from { opacity: 0; transform: translateY(-50px); } to { opacity: 1; transform: translateY(0); } }
        .modal-header { background: #990000; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .modal-header h2 { margin: 0; font-size: 1.4em; }
        .close { float: right; font-size: 28px; font-weight: bold; cursor: pointer; line-height: 1; }
        .close:hover { opacity: 0.7; }
        .modal-body { padding: 30px; }
        .step { display: flex; align-items: flex-start; margin-bottom: 25px; padding: 20px; background: #f8f9fa; border-radius: 6px; border-left: 4px solid #990000; }
        .step-number { background: #990000; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; margin-right: 15px; flex-shrink: 0; }
        .step-content { flex: 1; }
        .step-title { font-weight: bold; color: #333; margin-bottom: 8px; font-size: 1.1em; }
        .step-description { color: #666; line-height: 1.5; }
        .action-button { background: #990000; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-weight: bold; margin-top: 10px; transition: all 0.3s; }
        .action-button:hover { background: #b30000; transform: translateY(-1px); }
        
        .notice { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; margin: 20px; color: #856404; }
        .notice-title { font-weight: bold; margin-bottom: 5px; }
        
        .category-section { 
            margin: 20px 0; 
            padding: 0 20px;
        }
        
        .category-header { 
            font-size: 1.3em; 
            font-weight: bold; 
            color: #990000; 
            padding: 15px 0; 
            border-bottom: 2px solid #990000; 
            margin-bottom: 15px;
        }
        
        .category-container { 
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        
        .diagnostic-card {
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            overflow: hidden;
            transition: all 0.3s;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        
        .diagnostic-card:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        
        .diagnostic-header {
            padding: 12px 16px;
            cursor: pointer;
            user-select: none;
            background: #f8f9fa;
            transition: background-color 0.3s;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .diagnostic-header:hover {
            background: #e9ecef;
        }
        
        .diagnostic-info {
            display: flex;
            flex-direction: column;
            flex: 1;
        }
        
        .diagnostic-name {
            font-weight: 600;
            font-size: 1.1em;
            color: #333;
        }
        
        .diagnostic-expand-hint {
            font-size: 0.85em;
            color: #666;
            margin-top: 2px;
        }
        
        .diagnostic-details {
            display: none;
            background: #f8f9fa;
            padding: 16px;
            border-top: 1px solid #dee2e6;
        }
        
        .diagnostic-card.expanded .diagnostic-details {
            display: block;
            animation: slideDown 0.3s ease-out;
        }
        
        .diagnostic-log {
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', monospace;
            white-space: pre-wrap;
            line-height: 1.4;
            font-size: 0.9em;
            color: #333;
            max-height: 400px;
            overflow-y: auto;
            margin-bottom: 10px;
        }
        
        .copy-button {
            background: #666;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 0.9em;
            font-weight: bold;
            transition: all 0.3s;
            margin-top: 10px;
        }
        
        .copy-button:hover {
            background: #555;
            transform: translateY(-1px);
        }
        
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
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
        
        <div class="download-section">
            <button onclick="showEmailModal()" class="download-button">Email Support</button>
        </div>
        
        <!-- Email Support Modal -->
        <div id="emailModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <span class="close" onclick="closeEmailModal()">&times;</span>
                    <h2>Email Support Instructions</h2>
                </div>
                <div class="modal-body">
                    <div class="step">
                        <div class="step-number">1</div>
                        <div class="step-content">
                            <div class="step-title">Download Report</div>
                            <div class="step-description">Click the button below to download this diagnostic report to your computer. You'll need this file for the next step.</div>
                            <button onclick="downloadReport()" class="action-button">Download Report</button>
                        </div>
                    </div>
                    <div class="step">
                        <div class="step-number">2</div>
                        <div class="step-content">
                            <div class="step-title">Send Email</div>
                            <div class="step-description">Click below to open your email client with a pre-filled message to DTU Python Support. Attach the downloaded report file from Step 1.</div>
                            <button onclick="openEmail()" class="action-button">Open Email Client</button>
                            <button onclick="copyEmail()" class="action-button" style="margin-left: 10px; background: #666;">Copy Email Address</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="notice">
            <div class="notice-title">First Year Installation Diagnostics</div>
            This report shows the validation results for your DTU first year Python installation.
        </div>
        
        <div class="diagnostics">
            <div class="category-section">
                <div class="category-header">First Year Setup Validation</div>
                <div class="category-container">
                    <div class="diagnostic-card" onclick="toggleCard(this)">
                        <div class="diagnostic-header">
                            <div class="diagnostic-info">
                                <div class="diagnostic-name">Test Results</div>
                                <div class="diagnostic-expand-hint">Click to expand</div>
                            </div>
                        </div>
                        <div class="diagnostic-details">
                            <div class="diagnostic-log">$($testResults -replace '"', '\"')</div>
                            <button onclick="copyOutput(this, 'Test Results')" class="copy-button">Copy Output</button>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header">System Information</div>
                <div class="category-container">
                    <div class="diagnostic-card" onclick="toggleCard(this)">
                        <div class="diagnostic-header">
                            <div class="diagnostic-info">
                                <div class="diagnostic-name">System Details</div>
                                <div class="diagnostic-expand-hint">Click to expand</div>
                            </div>
                        </div>
                        <div class="diagnostic-details">
                            <div class="diagnostic-log">$($formattedSystemInfo -replace '"', '\"')</div>
                            <button onclick="copyOutput(this, 'System Details')" class="copy-button">Copy Output</button>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="category-section">
                <div class="category-header">Installation Log</div>
                <div class="category-container">
                    <div class="diagnostic-card" onclick="toggleCard(this)">
                        <div class="diagnostic-header">
                            <div class="diagnostic-info">
                                <div class="diagnostic-name">Complete Installation Output</div>
                                <div class="diagnostic-expand-hint">Click to expand</div>
                            </div>
                        </div>
                        <div class="diagnostic-details">
                            <div class="diagnostic-log">$($installLogContent -replace '"', '\"')</div>
                            <button onclick="copyOutput(this, 'Installation Log')" class="copy-button">Copy Output</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <script>
        function toggleCard(card) {
            card.classList.toggle('expanded');
        }
        
        function showEmailModal() {
            document.getElementById('emailModal').style.display = 'block';
        }
        
        function closeEmailModal() {
            document.getElementById('emailModal').style.display = 'none';
        }
        
        function downloadReport() {
            const reportContent = document.documentElement.outerHTML;
            const blob = new Blob([reportContent], { type: 'text/html' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'DTU_Python_Installation_Report_' + new Date().toISOString().slice(0,10) + '.html';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }
        
        function openEmail() {
            const subject = encodeURIComponent('DTU Python Installation Support Request');
            const body = encodeURIComponent('Python environment setup issue\\n\\nCourse: [PLEASE FILL OUT]\\n\\nDiagnostic report attached.\\n\\nComponents:\\n' + 
                '• Python: ' + (document.querySelector('.diagnostic-log').textContent.includes('PASS: Python') ? 'Working' : 'Issue') + '\\n' +
                '• Packages: ' + (document.querySelector('.diagnostic-log').textContent.includes('PASS: Python Environment') ? 'Working' : 'Issue') + '\\n' +
                '• VS Code: ' + (document.querySelector('.diagnostic-log').textContent.includes('PASS: VS Code') ? 'Working' : 'Issue') + '\\n\\n' +
                'Additional notes:\\nIf you have any additional notes\\n\\nThanks');
            
            window.location.href = 'mailto:pythonsupport@dtu.dk?subject=' + subject + '&body=' + body;
            closeEmailModal();
        }
        
        function copyEmail() {
            const email = 'pythonsupport@dtu.dk';
            navigator.clipboard.writeText(email).then(function() {
                // Change button text temporarily to show success
                const button = event.target;
                const originalText = button.textContent;
                button.textContent = 'Copied!';
                button.style.background = '#008835';
                setTimeout(function() {
                    button.textContent = originalText;
                    button.style.background = '#666';
                }, 2000);
            }).catch(function(err) {
                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = email;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                
                // Show success message
                const button = event.target;
                const originalText = button.textContent;
                button.textContent = 'Copied!';
                button.style.background = '#008835';
                setTimeout(function() {
                    button.textContent = originalText;
                    button.style.background = '#666';
                }, 2000);
            });
        }
        
        function copyOutput(button, sectionName) {
            // Stop event propagation to prevent card toggle
            event.stopPropagation();
            
            // Find the diagnostic-log content within the same card
            const card = button.closest('.diagnostic-card');
            const logContent = card.querySelector('.diagnostic-log');
            const textToCopy = logContent.textContent;
            
            navigator.clipboard.writeText(textToCopy).then(function() {
                // Change button text temporarily to show success
                const originalText = button.textContent;
                button.textContent = 'Copied!';
                button.style.background = '#008835';
                setTimeout(function() {
                    button.textContent = originalText;
                    button.style.background = '#666';
                }, 2000);
            }).catch(function(err) {
                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = textToCopy;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                
                // Show success message
                const originalText = button.textContent;
                button.textContent = 'Copied!';
                button.style.background = '#008835';
                setTimeout(function() {
                    button.textContent = originalText;
                    button.style.background = '#666';
                }, 2000);
            });
        }
        
        // Close modal when clicking outside of it
        window.onclick = function(event) {
            const modal = document.getElementById('emailModal');
            if (event.target == modal) {
                closeEmailModal();
            }
        }
        </script>
        
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
