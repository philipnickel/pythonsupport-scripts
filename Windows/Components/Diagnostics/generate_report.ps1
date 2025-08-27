# @doc
# @name: DTU Python Support - Comprehensive Installation Report Generator
# @description: Comprehensive installation report generator for DTU Python Support
# @category: Diagnostics
# @usage: .\generate_report.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Generates detailed HTML report with system info, test results, and install log
# @/doc

param(
    [switch]$Verbose = $false,
    [switch]$NoBrowser = $false,
    [string]$InstallLog = ""
)

# Collect all system information and detected components
function Get-SystemInfo {
    Write-Host "DEBUG: Starting Get-SystemInfo function" -ForegroundColor Yellow
    
    try {
        # Refresh environment variables to pick up any PATH changes from installation
        Write-Host "DEBUG: Refreshing environment variables..." -ForegroundColor Yellow
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    # Add common installation paths that might not be in PATH yet
    Write-Host "DEBUG: Adding common installation paths to PATH..." -ForegroundColor Yellow
    $commonPaths = @(
        "$env:USERPROFILE\miniforge3",
        "$env:USERPROFILE\miniforge3\Scripts",
        "$env:USERPROFILE\miniforge3\Library\bin",
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
        "${env:ProgramFiles}\Microsoft VS Code\bin",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path -and $env:PATH -notlike "*$path*") {
            Write-Host "DEBUG: Adding to PATH: $path" -ForegroundColor Yellow
            $env:PATH = "$env:PATH;$path"
        }
    }
    
    # Self-contained configuration - try external first, fall back to defaults
    $RemotePS = if ($env:REMOTE_PS) { $env:REMOTE_PS } else { "dtudk/pythonsupport-scripts" }
    $BranchPS = if ($env:BRANCH_PS) { $env:BRANCH_PS } else { "main" }
    Write-Host "DEBUG: RemotePS=$RemotePS, BranchPS=$BranchPS" -ForegroundColor Yellow
    
    $ConfigURL = "https://raw.githubusercontent.com/$RemotePS/$BranchPS/Windows/config.ps1"
    $ConfigFile = "$env:TEMP\sysinfo_config_$PID.ps1"
    Write-Host "DEBUG: ConfigURL=$ConfigURL" -ForegroundColor Yellow
    Write-Host "DEBUG: ConfigFile=$ConfigFile" -ForegroundColor Yellow
    
    try {
        Write-Host "DEBUG: Attempting to download config file..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $ConfigURL -OutFile $ConfigFile -UseBasicParsing | Out-Null
        if (Test-Path $ConfigFile) {
            Write-Host "DEBUG: Config file downloaded successfully, sourcing it..." -ForegroundColor Yellow
            . $ConfigFile
            Remove-Item $ConfigFile -Force
            Write-Host "DEBUG: Config file sourced and cleaned up" -ForegroundColor Yellow
        } else {
            Write-Host "DEBUG: Config file not found after download attempt" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "DEBUG: Failed to download config file, using defaults: $($_.Exception.Message)" -ForegroundColor Yellow
        # Continue with defaults
    }
    
    # Ensure we always have defaults
    $PythonVersionDTU = if ($env:PYTHON_VERSION_DTU) { $env:PYTHON_VERSION_DTU } else { "3.12" }
    $DTUPackages = if ($env:DTU_PACKAGES) { $env:DTU_PACKAGES -split ',' } else { @("dtumathtools", "pandas", "scipy", "statsmodels", "uncertainties") }
    Write-Host "DEBUG: PythonVersionDTU=$PythonVersionDTU" -ForegroundColor Yellow
    Write-Host "DEBUG: DTUPackages=$($DTUPackages -join ', ')" -ForegroundColor Yellow
    
    Write-Host "DEBUG: Starting system information collection..." -ForegroundColor Yellow
    Write-Output "=== System Information ==="
    Write-Output "Operating System: $($PSVersionTable.OS) ($([System.Environment]::OSVersion.VersionString))"
    Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Output "Architecture: $([System.Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE'))"
    Write-Output ""
    
    Write-Host "DEBUG: Collecting hardware information..." -ForegroundColor Yellow
    Write-Output "=== Hardware Information ==="
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    Write-Host "DEBUG: Computer system info collected" -ForegroundColor Yellow
    Write-Output "Model: $($computerSystem.Model)"
    Write-Output "Processor: $($computerSystem.Name)"
    Write-Output "Memory: $([math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)) GB"
    Write-Output ""
    
    Write-Host "DEBUG: Collecting Python environment information..." -ForegroundColor Yellow
    Write-Output "=== Python Environment ==="
    
    # Try multiple methods to find Python
    Write-Host "DEBUG: Getting python path..." -ForegroundColor Yellow
    $pythonPath = $null
    $pythonVersion = $null
    
    # Method 1: Try direct command
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($pythonPath) {
        Write-Host "DEBUG: Python found via command: $pythonPath" -ForegroundColor Yellow
        $pythonVersion = python --version 2>$null
    }
    
    # Method 2: Try miniforge Python directly
    if (-not $pythonPath -or $pythonPath -notlike "*miniforge*") {
        $miniforgePython = "$env:USERPROFILE\miniforge3\python.exe"
        if (Test-Path $miniforgePython) {
            Write-Host "DEBUG: Using miniforge Python directly: $miniforgePython" -ForegroundColor Yellow
            $pythonPath = $miniforgePython
            $pythonVersion = & $miniforgePython --version 2>$null
        }
    }
    
    # Method 3: Try with refreshed PATH (for post-installation)
    if (-not $pythonPath) {
        Write-Host "DEBUG: Trying with refreshed PATH..." -ForegroundColor Yellow
        $refreshedPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = $refreshedPath
        $pythonPath = Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if ($pythonPath) {
            Write-Host "DEBUG: Python found after PATH refresh: $pythonPath" -ForegroundColor Yellow
            $pythonVersion = python --version 2>$null
        }
    }
    
    Write-Host "DEBUG: Final Python path: $pythonPath" -ForegroundColor Yellow
    Write-Host "DEBUG: Final Python version: $pythonVersion" -ForegroundColor Yellow
    
    # Try multiple methods to find conda
    Write-Host "DEBUG: Getting conda path..." -ForegroundColor Yellow
    $condaPath = $null
    $condaVersion = $null
    $condaBase = $null
    
    # Method 1: Try direct command
    $condaPath = Get-Command conda -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($condaPath) {
        Write-Host "DEBUG: Conda found via command: $condaPath" -ForegroundColor Yellow
        $condaVersion = conda --version 2>$null
        $condaBase = conda info --base 2>$null
    }
    
    # Method 2: Try miniforge conda directly
    if (-not $condaPath) {
        $miniforgeConda = "$env:USERPROFILE\miniforge3\Scripts\conda.exe"
        if (Test-Path $miniforgeConda) {
            Write-Host "DEBUG: Using miniforge conda directly: $miniforgeConda" -ForegroundColor Yellow
            $condaPath = $miniforgeConda
            $condaVersion = & $miniforgeConda --version 2>$null
            $condaBase = & $miniforgeConda info --base 2>$null
        }
    }
    
    # Method 3: Try with refreshed PATH (for post-installation)
    if (-not $condaPath) {
        Write-Host "DEBUG: Trying conda with refreshed PATH..." -ForegroundColor Yellow
        $refreshedPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = $refreshedPath
        $condaPath = Get-Command conda -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if ($condaPath) {
            Write-Host "DEBUG: Conda found after PATH refresh: $condaPath" -ForegroundColor Yellow
            $condaVersion = conda --version 2>$null
            $condaBase = conda info --base 2>$null
        }
    }
    
    Write-Host "DEBUG: Final conda path: $condaPath" -ForegroundColor Yellow
    Write-Host "DEBUG: Final conda version: $condaVersion" -ForegroundColor Yellow
    Write-Host "DEBUG: Final conda base: $condaBase" -ForegroundColor Yellow
    
    Write-Output "Python Location: $(if ($pythonPath) { $pythonPath } else { 'Not found' })"
    Write-Output "Python Version: $(if ($pythonVersion) { $pythonVersion } else { 'Not found' })"
    Write-Output "Conda Location: $(if ($condaPath) { $condaPath } else { 'Not found' })"
    Write-Output "Conda Version: $(if ($condaVersion) { $condaVersion } else { 'Not found' })"
    Write-Output "Conda Base: $(if ($condaBase) { $condaBase } else { 'Not found' })"
    Write-Output ""
    
    Write-Output "=== DTU Configuration ==="
    Write-Output "Expected Python Version: $PythonVersionDTU"
    Write-Output "Required DTU Packages: $($DTUPackages -join ', ')"
    Write-Output ""
    
    Write-Host "DEBUG: Collecting VS Code information..." -ForegroundColor Yellow
    Write-Output "=== VS Code Environment ==="
    
    # Try multiple methods to find VS Code
    Write-Host "DEBUG: Getting VS Code path..." -ForegroundColor Yellow
    $codePath = $null
    $codeVersion = $null
    
    # Method 1: Try direct command
    $codePath = Get-Command code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($codePath) {
        Write-Host "DEBUG: VS Code found via command: $codePath" -ForegroundColor Yellow
        $codeVersion = code --version 2>$null | Select-Object -First 1
    }
    
    # Method 2: Try common VS Code installation paths
    if (-not $codePath) {
        $vscodePaths = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
            "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
            "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
        )
        
        foreach ($vscPath in $vscodePaths) {
            if (Test-Path $vscPath) {
                Write-Host "DEBUG: VS Code found at: $vscPath" -ForegroundColor Yellow
                $codePath = $vscPath
                $codeVersion = & $vscPath --version 2>$null | Select-Object -First 1
                break
            }
        }
    }
    
    # Method 3: Try with refreshed PATH (for post-installation)
    if (-not $codePath) {
        Write-Host "DEBUG: Trying VS Code with refreshed PATH..." -ForegroundColor Yellow
        $refreshedPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = $refreshedPath
        $codePath = Get-Command code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if ($codePath) {
            Write-Host "DEBUG: VS Code found after PATH refresh: $codePath" -ForegroundColor Yellow
            $codeVersion = code --version 2>$null | Select-Object -First 1
        }
    }
    
    Write-Host "DEBUG: Final VS Code path: $codePath" -ForegroundColor Yellow
    Write-Host "DEBUG: Final VS Code version: $codeVersion" -ForegroundColor Yellow
    
    Write-Output "VS Code Location: $(if ($codePath) { $codePath } else { 'Not found' })"
    Write-Output "VS Code Version: $(if ($codeVersion) { $codeVersion } else { 'Not found' })"
    Write-Output "Installed Extensions:"
    
    # Get VS Code extensions using the found path
    Write-Host "DEBUG: Getting VS Code extensions..." -ForegroundColor Yellow
    $extensions = @()
    if ($codePath) {
        $extensions = & $codePath --list-extensions 2>$null | Select-Object -First 10
    }
    Write-Host "DEBUG: Found $($extensions.Count) VS Code extensions" -ForegroundColor Yellow
    if ($extensions) {
        $extensions | ForEach-Object { Write-Output "  $_" }
    } else {
        Write-Output "  No extensions found"
    }
    
    # Return comprehensive system info object
    $systemInfo = @{
        # System information
        OS = "$($PSVersionTable.OS) ($([System.Environment]::OSVersion.VersionString))"
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Architecture = [System.Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE')
        
        # Hardware information
        ComputerModel = $computerSystem.Model
        Processor = $computerSystem.Name
        Memory = "$([math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)) GB"
        
        # Python environment
        PythonPath = $pythonPath
        PythonVersion = $pythonVersion
        CondaPath = $condaPath
        CondaVersion = $condaVersion
        CondaBase = $condaBase
        MiniforgePython = "$env:USERPROFILE\miniforge3\python.exe"
        
        # VS Code environment
        VSCodePath = $codePath
        VSCodeVersion = $codeVersion
        VSCodeExtensions = $extensions
        
        # Configuration
        PythonVersionDTU = $PythonVersionDTU
        DTUPackages = $DTUPackages
    }
    
    return $systemInfo
    } catch {
        Write-Host "DEBUG: Error in Get-SystemInfo: $($_.Exception.Message)" -ForegroundColor Yellow
        throw
    }
}

# Generate formatted system information output
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

# Run first year test - all required verifications
function Test-FirstYearSetup {
    param([hashtable]$SystemInfo)
    
    Write-Host "DEBUG: Starting Test-FirstYearSetup function" -ForegroundColor Yellow
    Write-Output "=== First Year Setup Test ==="
    Write-Output ""
    
    $miniforgeFailed = $false
    $pythonFailed = $false
    $packagesFailed = $false
    $vscodeFailed = $false
    $extensionsFailed = $false
    $condaInitFailed = $false
    
    # Test 1: Miniforge Installation
    Write-Host "DEBUG: Testing Miniforge Installation..." -ForegroundColor Yellow
    Write-Output "Testing Miniforge Installation..."
    $miniforgePath = "$env:USERPROFILE\miniforge3"
    Write-Host "DEBUG: Miniforge path: $miniforgePath" -ForegroundColor Yellow
    Write-Host "DEBUG: Miniforge path exists: $(Test-Path $miniforgePath)" -ForegroundColor Yellow
    Write-Host "DEBUG: Conda command available: $(if ($SystemInfo.CondaPath) { 'Yes' } else { 'No' })" -ForegroundColor Yellow
    if ((Test-Path $miniforgePath) -and $SystemInfo.CondaPath) {
        Write-Output "PASS: Miniforge installed at $miniforgePath"
    } else {
        Write-Output "FAIL: Miniforge not found or conda command not available"
        $miniforgeFailed = $true
    }
    Write-Output ""
    
    # Test 2: Python Version (from miniforge)
    Write-Output "Testing Python Version..."
    $ExpectedVersion = "3.12"
    
    # Use the Python info we already detected
    $InstalledVersion = $SystemInfo.PythonVersion
    $PythonPath = $SystemInfo.PythonPath
    
    if ($InstalledVersion -like "$ExpectedVersion*" -and $PythonPath -like "*miniforge3*") {
        Write-Output "PASS: Python $InstalledVersion from miniforge"
    } else {
        Write-Output "FAIL: Expected Python $ExpectedVersion from miniforge, found $InstalledVersion at $PythonPath"
        $pythonFailed = $true
    }
    Write-Output ""
    
    # Test 3: DTU Packages
    Write-Host "DEBUG: Testing DTU Packages..." -ForegroundColor Yellow
    Write-Output "Testing DTU Packages..."
    
    # Use the Python path we already detected
    $PythonCmd = $SystemInfo.PythonPath
    
    if ($PythonCmd) {
        Write-Host "DEBUG: Attempting to import DTU packages using: $PythonCmd" -ForegroundColor Yellow
        $packageTest = & $PythonCmd -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('All packages imported successfully')" 2>$null
        Write-Host "DEBUG: Package test exit code: $LASTEXITCODE" -ForegroundColor Yellow
        Write-Host "DEBUG: Package test output: $packageTest" -ForegroundColor Yellow
        if ($LASTEXITCODE -eq 0) {
            Write-Output "PASS: All DTU packages imported successfully"
        } else {
            Write-Output "FAIL: Some DTU packages failed to import"
            $packagesFailed = $true
        }
    } else {
        Write-Output "FAIL: No Python available for package testing"
        $packagesFailed = $true
    }
    Write-Output ""
    
    # Test 4: VS Code
    Write-Output "Testing VS Code..."
    $codeTest = $null
    
    # Use the VS Code path we already detected
    if ($SystemInfo.VSCodePath) {
        $codeTest = & $SystemInfo.VSCodePath --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "PASS: VS Code $($codeTest | Select-Object -First 1)"
        } else {
            Write-Output "FAIL: VS Code not available"
            $vscodeFailed = $true
        }
    } else {
        Write-Output "FAIL: VS Code not available"
        $vscodeFailed = $true
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
                $extensionsFailed = $true
            }
        } else {
            Write-Output "FAIL: Python extension missing"
            $extensionsFailed = $true
        }
    } else {
        Write-Output "FAIL: VS Code not available for extension testing"
        $extensionsFailed = $true
    }
    Write-Output ""
    
    # Test 6: Conda Base Environment Activation
    Write-Output "Testing Conda Base Environment Activation..."
    
    if (Get-Command conda -ErrorAction SilentlyContinue) {
        Write-Output "PASS: Conda command is available"
        
        # Check if we're in base environment
        if ($env:CONDA_DEFAULT_ENV -eq "base" -or $env:CONDA_PROMPT_MODIFIER -like "(base)*") {
            Write-Output "PASS: Conda base environment is active"
        } else {
            Write-Output "WARNING: Conda base environment not active (this may be normal in fresh shell)"
        }
        
        # Test conda availability in a fresh PowerShell session
        $condaTest = powershell.exe -Command "conda --version" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "PASS: Conda is available in new PowerShell sessions"
        } else {
            Write-Output "FAIL: Conda not available in new PowerShell sessions"
            $condaInitFailed = $true
        }
    } else {
        Write-Output "FAIL: Conda command not available"
        $condaInitFailed = $true
    }
    
    Write-Output ""
    Write-Output "════════════════════════════════════════"
    
    # Overall result
    $failCount = 0
    if ($miniforgeFailed) { $failCount++ }
    if ($pythonFailed) { $failCount++ }
    if ($packagesFailed) { $failCount++ }
    if ($vscodeFailed) { $failCount++ }
    if ($extensionsFailed) { $failCount++ }
    if ($condaInitFailed) { $failCount++ }
    
    if ($failCount -eq 0) {
        Write-Output "OVERALL RESULT: PASS - All components working"
        return 0
    } else {
        Write-Output "OVERALL RESULT: FAIL - $failCount component(s) failed"
        return 1
    }
}

# Generate HTML report
function New-HTMLReport {
    param(
        [hashtable]$SystemInfo,
        [string]$FormattedSystemInfo,
        [string]$TestResults
    )
    
    Write-Host "DEBUG: Starting New-HTMLReport function" -ForegroundColor Yellow
    $outputFile = "$env:TEMP\dtu_installation_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Write-Host "DEBUG: Output file: $outputFile" -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "DEBUG: Timestamp: $timestamp" -ForegroundColor Yellow
    
    # Use the passed parameters instead of re-running functions
    $formattedSystemInfo = $FormattedSystemInfo
    $testResults = $TestResults
    $testExitCode = $LASTEXITCODE
    Write-Host "DEBUG: Using passed system info and test results" -ForegroundColor Yellow
    
    # Parse test results for summary counts (exclude header and overall result lines)
    $passCount = ($testResults -split "`n" | Where-Object { $_ -like "PASS:*" }).Count
    $failCount = ($testResults -split "`n" | Where-Object { $_ -like "FAIL:*" }).Count
    $totalCount = $passCount + $failCount
    
    # Generate professional status message
    if ($failCount -eq 0 -and $totalCount -gt 0) {
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
    Write-Host "DEBUG: Processing install log..." -ForegroundColor Yellow
    if ($InstallLog -and (Test-Path $InstallLog)) {
        Write-Host "DEBUG: Install log found at: $InstallLog" -ForegroundColor Yellow
        $installLogContent = Get-Content $InstallLog -Raw -ErrorAction SilentlyContinue
        if ($installLogContent) {
            Write-Host "DEBUG: Install log content loaded successfully" -ForegroundColor Yellow
        } else {
            Write-Host "DEBUG: Install log file is empty or unreadable" -ForegroundColor Yellow
            $installLogContent = "Installation log file is empty or unreadable"
        }
    } elseif ($env:INSTALL_LOG -and (Test-Path $env:INSTALL_LOG)) {
        Write-Host "DEBUG: Install log found in environment variable: $env:INSTALL_LOG" -ForegroundColor Yellow
        $installLogContent = Get-Content $env:INSTALL_LOG -Raw -ErrorAction SilentlyContinue
        if ($installLogContent) {
            Write-Host "DEBUG: Install log content loaded successfully" -ForegroundColor Yellow
        } else {
            Write-Host "DEBUG: Install log file is empty or unreadable" -ForegroundColor Yellow
            $installLogContent = "Installation log file is empty or unreadable"
        }
    } else {
        Write-Host "DEBUG: No install log found" -ForegroundColor Yellow
        $installLogContent = "Installation log not available"
    }
    
    Write-Host "DEBUG: Generating HTML content..." -ForegroundColor Yellow
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
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
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
                '• Packages: ' + (document.querySelector('.diagnostic-log').textContent.includes('PASS: All DTU packages') ? 'Working' : 'Issue') + '\\n' +
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

    Write-Host "DEBUG: Writing HTML file..." -ForegroundColor Yellow
    $htmlContent | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "DEBUG: HTML file written successfully" -ForegroundColor Yellow
    
    return $outputFile, $testExitCode
}

# Main execution
function Main {
    Write-Host "DEBUG: Starting Main function" -ForegroundColor Yellow
    Write-Host "Generating installation report..." -ForegroundColor Cyan
    
    try {
        Write-Host "DEBUG: Collecting system information..." -ForegroundColor Yellow
        # Collect all system information once
        $systemInfo = Get-SystemInfo
        Write-Host "DEBUG: System information collected" -ForegroundColor Yellow
        
        Write-Host "DEBUG: Formatting system information..." -ForegroundColor Yellow
        # Generate formatted system info output
        $formattedSystemInfo = Format-SystemInfo -SystemInfo $systemInfo | Out-String
        Write-Host "DEBUG: System information formatted" -ForegroundColor Yellow
    } catch {
        Write-Host "DEBUG: Error collecting system information: $($_.Exception.Message)" -ForegroundColor Yellow
        # Create minimal system info if collection fails
        $systemInfo = @{
            OS = "Unknown"
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            Architecture = "Unknown"
            ComputerModel = "Unknown"
            Processor = "Unknown"
            Memory = "Unknown"
            PythonPath = $null
            PythonVersion = $null
            CondaPath = $null
            CondaVersion = $null
            CondaBase = $null
            MiniforgePython = "$env:USERPROFILE\miniforge3\python.exe"
            VSCodePath = $null
            VSCodeVersion = $null
            VSCodeExtensions = @()
            PythonVersionDTU = "3.12"
            DTUPackages = @("dtumathtools", "pandas", "scipy", "statsmodels", "uncertainties")
        }
        Write-Host "DEBUG: Created fallback system info hashtable" -ForegroundColor Yellow
        $formattedSystemInfo = Format-SystemInfo -SystemInfo $systemInfo | Out-String
        Write-Host "DEBUG: Fallback system info formatted" -ForegroundColor Yellow
    }
    
    try {
        Write-Host "DEBUG: Running tests..." -ForegroundColor Yellow
        # Run tests using the collected system info
        $testResults = Test-FirstYearSetup -SystemInfo $systemInfo 2>&1 | Out-String
        $testExitCode = $LASTEXITCODE
        Write-Host "DEBUG: Tests completed with exit code: $testExitCode" -ForegroundColor Yellow
    } catch {
        Write-Host "DEBUG: Error running tests: $($_.Exception.Message)" -ForegroundColor Yellow
        $testResults = "=== First Year Setup Test ===`nError running tests: $($_.Exception.Message)`n"
        $testExitCode = 1
    }
    
    # Display results in console
    Write-Host ""
    Write-Host $formattedSystemInfo
    Write-Host $testResults
    Write-Host ""
    
    try {
        Write-Host "DEBUG: About to generate HTML report..." -ForegroundColor Yellow
        # Generate HTML report
        $reportFile, $exitCode = New-HTMLReport -SystemInfo $systemInfo -FormattedSystemInfo $formattedSystemInfo -TestResults $testResults
        Write-Host "DEBUG: HTML report generation completed" -ForegroundColor Yellow
        
        Write-Host "Report generated: $reportFile" -ForegroundColor Green
        
        # Open report in browser
        if (-not $NoBrowser) {
            Write-Host "DEBUG: Opening report in browser..." -ForegroundColor Yellow
            Start-Process $reportFile
            Write-Host "Report opened in browser" -ForegroundColor Green
        }
    } catch {
        Write-Host "DEBUG: Error generating HTML report: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Failed to generate HTML report: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You can still view the console output above for diagnostic information." -ForegroundColor Yellow
        return 1
    }
    
    Write-Host "DEBUG: Main function completed" -ForegroundColor Yellow
    # Return the test exit code for Piwik logging
    return $testExitCode
}

# Only run main if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    # Set error action preference to continue so we can catch errors
    $ErrorActionPreference = "Continue"
    
    try {
        Write-Host "Starting DTU Python Support Diagnostics..." -ForegroundColor Green
        $exitCode = Main
    } catch {
        Write-Host ""
        Write-Host "FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        Write-Host ""
        Write-Host "This error occurred during script execution." -ForegroundColor Yellow
        Write-Host "Please report this issue to DTU Python Support." -ForegroundColor Yellow
        $exitCode = 1
    }
    
    Write-Host ""
    Write-Host "Script completed with exit code: $exitCode" -ForegroundColor Cyan
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    
    # Use a more reliable way to pause
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        # Fallback if ReadKey fails
        Write-Host "Press Enter to continue..."
        Read-Host
    }
    
    exit $exitCode
}
