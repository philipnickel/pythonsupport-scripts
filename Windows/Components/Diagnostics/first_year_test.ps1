# @doc
# @name: DTU Python Support Installation Verification
# @description: Verifies that all DTU Python Support components are correctly installed and configured
# @category: Diagnostics
# @usage: . .\verify_installation.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Comprehensive verification of Python, VSCode, packages, and environment configuration
# @/doc

param(
    [switch]$Detailed = $false,
    [switch]$FixIssues = $false,
    [string]$OutputFormat = "Console", # Console, Json, Html
    [string]$OutputPath = $null
)

# Load error handling utilities
try {
    $errorHandlingUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/Components/Shared/error_handling.ps1"
    $errorHandlingScript = Invoke-WebRequest -Uri $errorHandlingUrl -UseBasicParsing
    Invoke-Expression $errorHandlingScript.Content
}
catch {
    Write-Host "Warning: Could not load error handling utilities" -ForegroundColor Yellow
}

Write-Host "DTU Python Support - Installation Verification" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Initialize verification results
$verificationResults = @{
    OverallStatus = $false
    Timestamp = Get-Date
    Computer = $env:COMPUTERNAME
    User = $env:USERNAME
    Components = @{
        Python = @{
            Status = $false
            Version = $null
            Location = $null
            Issues = @()
            Details = @{}
        }
        Conda = @{
            Status = $false
            Version = $null
            Location = $null
            Issues = @()
            Details = @{}
        }
        VSCode = @{
            Status = $false
            Version = $null
            Location = $null
            Issues = @()
            Details = @{}
        }
        Environment = @{
            Status = $false
            Issues = @()
            Details = @{}
        }
        Packages = @{
            Status = $false
            Issues = @()
            Details = @{}
        }
    }
}

# Function to test component and record results
function Test-Component {
    param(
        [string]$ComponentName,
        [scriptblock]$TestScript
    )
    
    Write-Host "Testing $ComponentName..." -ForegroundColor Yellow
    
    try {
        $result = & $TestScript
        if ($result) {
            Write-Host "  [PASS] $ComponentName: PASS" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $ComponentName: FAIL" -ForegroundColor Red
        }
        return $result
    }
    catch {
        Write-Host "  [ERROR] $ComponentName: ERROR - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test Python installation
Write-Host "1. Verifying Python Installation" -ForegroundColor White
$pythonResult = Test-Component "Python" {
    $pythonCommands = @("python", "python3")
    $pythonFound = $false
    
    foreach ($cmd in $pythonCommands) {
        try {
            # Test in a fresh PowerShell process to simulate what a user would see
            $pythonTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "& { $cmd --version; exit `$LASTEXITCODE }" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\python_test.txt" -RedirectStandardError "$env:TEMP\python_error.txt"
            
            if ($pythonTest.ExitCode -eq 0) {
                $pythonVersion = Get-Content "$env:TEMP\python_test.txt" -Raw -ErrorAction SilentlyContinue
                if ($pythonVersion) {
                    $verificationResults.Components.Python.Status = $true
                    $verificationResults.Components.Python.Version = $pythonVersion.Trim()
                    
                    # Get location in fresh shell too
                    $locationTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "& { (Get-Command $cmd -ErrorAction SilentlyContinue).Source }" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\python_location.txt"
                    $pythonLocation = Get-Content "$env:TEMP\python_location.txt" -Raw -ErrorAction SilentlyContinue
                    if ($pythonLocation) {
                        $verificationResults.Components.Python.Location = $pythonLocation.Trim()
                    }
                    
                    $pythonFound = $true
                    break
                }
            }
        }
        catch {
            continue
        }
        finally {
            # Clean up temp files
            Remove-Item "$env:TEMP\python_test.txt" -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\python_error.txt" -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\python_location.txt" -ErrorAction SilentlyContinue
        }
    }
    
    if (-not $pythonFound) {
        $verificationResults.Components.Python.Issues += "Python command not found in fresh shell PATH"
    }
    
    return $pythonFound
}

# Test Conda installation
Write-Host "2. Verifying Conda Installation" -ForegroundColor White
$condaResult = Test-Component "Conda" {
    try {
        # Test in a fresh PowerShell process
        $condaTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "& { conda info --json; exit `$LASTEXITCODE }" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\conda_test.txt" -RedirectStandardError "$env:TEMP\conda_error.txt"
        
        if ($condaTest.ExitCode -eq 0) {
            $condaInfo = Get-Content "$env:TEMP\conda_test.txt" -Raw -ErrorAction SilentlyContinue
            if ($condaInfo) {
                try {
                    $condaData = $condaInfo | ConvertFrom-Json
                    $verificationResults.Components.Conda.Status = $true
                    $verificationResults.Components.Conda.Version = $condaData.conda_version
                    $verificationResults.Components.Conda.Location = $condaData.conda_prefix
                    $verificationResults.Components.Conda.Details = @{
                        DefaultEnvironment = $condaData.default_prefix
                        EnvironmentsDir = $condaData.envs_dirs
                        PlatformArch = $condaData.platform
                    }
                    return $true
                }
                catch {
                    $verificationResults.Components.Conda.Issues += "Failed to parse conda info JSON: $($_.Exception.Message)"
                }
            }
        }
        else {
            $errorOutput = Get-Content "$env:TEMP\conda_error.txt" -Raw -ErrorAction SilentlyContinue
            $verificationResults.Components.Conda.Issues += "Conda command failed in fresh shell: $errorOutput"
        }
    }
    catch {
        $verificationResults.Components.Conda.Issues += "Conda test error: $($_.Exception.Message)"
    }
    finally {
        # Clean up temp files
        Remove-Item "$env:TEMP\conda_test.txt" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\conda_error.txt" -ErrorAction SilentlyContinue
    }
    
    $verificationResults.Components.Conda.Issues += "Conda not found or not working properly in fresh shell"
    return $false
}

# Test VSCode installation
Write-Host "3. Verifying Visual Studio Code Installation" -ForegroundColor White
$vscodeResult = Test-Component "VSCode" {
    try {
        # Test in a fresh PowerShell process
        $codeTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "& { code --version; exit `$LASTEXITCODE }" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\vscode_test.txt" -RedirectStandardError "$env:TEMP\vscode_error.txt"
        
        if ($codeTest.ExitCode -eq 0) {
            $codeVersion = Get-Content "$env:TEMP\vscode_test.txt" -Raw -ErrorAction SilentlyContinue
            if ($codeVersion) {
                $versionLines = $codeVersion.Trim() -split "`n"
                $verificationResults.Components.VSCode.Status = $true
                $verificationResults.Components.VSCode.Version = $versionLines[0].Trim()
                
                # Get location in fresh shell
                $locationTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "& { (Get-Command code -ErrorAction SilentlyContinue).Source }" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\vscode_location.txt"
                $codeLocation = Get-Content "$env:TEMP\vscode_location.txt" -Raw -ErrorAction SilentlyContinue
                if ($codeLocation) {
                    $verificationResults.Components.VSCode.Location = $codeLocation.Trim()
                }
                
                return $true
            }
        }
        else {
            # VSCode command might not be in PATH, check installation directories
            $vscodeLocations = @(
                "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
                "${env:ProgramFiles}\Microsoft VS Code\bin\code.cmd",
                "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
            )
            
            foreach ($location in $vscodeLocations) {
                if (Test-Path $location) {
                    $verificationResults.Components.VSCode.Status = $true
                    $verificationResults.Components.VSCode.Location = $location
                    $verificationResults.Components.VSCode.Issues += "VSCode found but not accessible in fresh shell PATH"
                    return $true
                }
            }
        }
    }
    catch {
        $verificationResults.Components.VSCode.Issues += "VSCode test error: $($_.Exception.Message)"
    }
    finally {
        # Clean up temp files
        Remove-Item "$env:TEMP\vscode_test.txt" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\vscode_error.txt" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\vscode_location.txt" -ErrorAction SilentlyContinue
    }
    
    $verificationResults.Components.VSCode.Issues += "Visual Studio Code not found in fresh shell"
    return $false
}

# Test Environment Configuration
Write-Host "4. Verifying Environment Configuration" -ForegroundColor White
$envResult = Test-Component "Environment" {
    $issues = @()
    
    # Check PATH for Python and conda
    $pathElements = $env:PATH -split ';'
    $hasPythonPath = $false
    $hasCondaPath = $false
    
    foreach ($element in $pathElements) {
        if ($element -like "*python*" -or $element -like "*conda*" -or $element -like "*miniforge*") {
            if ($element -like "*python*") { $hasPythonPath = $true }
            if ($element -like "*conda*" -or $element -like "*miniforge*") { $hasCondaPath = $true }
        }
    }
    
    if (-not $hasPythonPath) {
        $issues += "Python not found in PATH"
    }
    if (-not $hasCondaPath) {
        $issues += "Conda not found in PATH"
    }
    
    # Check PowerShell profile for conda initialization
    $profileInitialized = $false
    if (Test-Path $PROFILE.CurrentUserCurrentHost) {
        $profileContent = Get-Content $PROFILE.CurrentUserCurrentHost -Raw
        if ($profileContent -like "*conda initialize*") {
            $profileInitialized = $true
        }
    }
    
    if (-not $profileInitialized) {
        $issues += "Conda not initialized in PowerShell profile"
    }
    
    # Check first_year environment
    try {
        $envTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "& { conda env list; exit `$LASTEXITCODE }" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\conda_envs.txt" -RedirectStandardError "$env:TEMP\conda_envs_error.txt"
        
        if ($envTest.ExitCode -eq 0) {
            $condaEnvs = Get-Content "$env:TEMP\conda_envs.txt" -Raw -ErrorAction SilentlyContinue
            if ($condaEnvs -and ($condaEnvs -like "*first_year*")) {
                $verificationResults.Components.Environment.Details.FirstYearEnv = $true
            } else {
                $issues += "first_year conda environment not found in fresh shell"
            }
        } else {
            $issues += "Could not check conda environments in fresh shell"
        }
        
        # Clean up temp files
        Remove-Item "$env:TEMP\conda_envs.txt" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\conda_envs_error.txt" -ErrorAction SilentlyContinue
    }
    catch {
        $issues += "Could not check conda environments: $($_.Exception.Message)"
    }
    
    $verificationResults.Components.Environment.Issues = $issues
    $verificationResults.Components.Environment.Details = @{
        PathHasPython = $hasPythonPath
        PathHasConda = $hasCondaPath
        ProfileInitialized = $profileInitialized
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        ExecutionPolicy = (Get-ExecutionPolicy -Scope CurrentUser).ToString()
    }
    
    return $issues.Count -eq 0
}

# Test Essential Packages
Write-Host "5. Verifying Essential Packages" -ForegroundColor White
$packagesResult = Test-Component "Packages" {
    $requiredPackages = @(
        "numpy", "pandas", "matplotlib", "seaborn", "scipy", 
        "scikit-learn", "jupyter", "ipython", "requests"
    )
    
    $missingPackages = @()
    $installedPackages = @()
    
    try {
        # Try to activate first_year environment and check packages in fresh shell
        $packagesTest = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command", "& { conda list -n first_year; exit `$LASTEXITCODE }" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\conda_packages.txt" -RedirectStandardError "$env:TEMP\conda_packages_error.txt"
        
        if ($packagesTest.ExitCode -eq 0) {
            $condaList = Get-Content "$env:TEMP\conda_packages.txt" -Raw -ErrorAction SilentlyContinue
            if ($condaList) {
                foreach ($package in $requiredPackages) {
                    if ($condaList -like "*$package*") {
                        $installedPackages += $package
                    } else {
                        $missingPackages += $package
                    }
                }
            } else {
                $verificationResults.Components.Packages.Issues += "Could not read conda package list from fresh shell"
                return $false
            }
        } else {
            $errorOutput = Get-Content "$env:TEMP\conda_packages_error.txt" -Raw -ErrorAction SilentlyContinue
            $verificationResults.Components.Packages.Issues += "Could not access first_year environment in fresh shell: $errorOutput"
            return $false
        }
        
        # Clean up temp files
        Remove-Item "$env:TEMP\conda_packages.txt" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\conda_packages_error.txt" -ErrorAction SilentlyContinue
    }
    catch {
        $verificationResults.Components.Packages.Issues += "Failed to check packages: $($_.Exception.Message)"
        return $false
    }
    
    $verificationResults.Components.Packages.Details = @{
        Required = $requiredPackages
        Installed = $installedPackages
        Missing = $missingPackages
    }
    
    if ($missingPackages.Count -gt 0) {
        $verificationResults.Components.Packages.Issues += "Missing packages: $($missingPackages -join ', ')"
    }
    
    return $missingPackages.Count -eq 0
}

# Calculate overall status
$componentStatuses = @(
    $verificationResults.Components.Python.Status,
    $verificationResults.Components.Conda.Status,
    $verificationResults.Components.VSCode.Status,
    $verificationResults.Components.Environment.Status,
    $verificationResults.Components.Packages.Status
)

$verificationResults.OverallStatus = ($componentStatuses | Where-Object { $_ -eq $false }).Count -eq 0

# Display summary
Write-Host ""
Write-Host "Verification Summary" -ForegroundColor White
Write-Host "===================" -ForegroundColor White

$statusColor = if ($verificationResults.OverallStatus) { "Green" } else { "Red" }
$statusText = if ($verificationResults.OverallStatus) { "PASS" } else { "FAIL" }
Write-Host "Overall Status: $statusText" -ForegroundColor $statusColor

Write-Host ""
foreach ($componentName in $verificationResults.Components.Keys) {
    $component = $verificationResults.Components[$componentName]
    $status = if ($component.Status) { "[PASS]" } else { "[FAIL]" }
    $color = if ($component.Status) { "Green" } else { "Red" }
    
    Write-Host "$status $componentName" -ForegroundColor $color
    
    if ($component.Version) {
        Write-Host "  Version: $($component.Version)" -ForegroundColor Gray
    }
    if ($component.Location) {
        Write-Host "  Location: $($component.Location)" -ForegroundColor Gray
    }
    
    if ($component.Issues.Count -gt 0 -and ($Detailed -or -not $component.Status)) {
        Write-Host "  Issues:" -ForegroundColor Yellow
        foreach ($issue in $component.Issues) {
            Write-Host "    • $issue" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
}

# Offer to fix issues if requested
if ($FixIssues -and -not $verificationResults.OverallStatus) {
    Write-Host "Attempting to fix detected issues..." -ForegroundColor Yellow
    
    # Fix conda initialization in PowerShell profile
    if ($verificationResults.Components.Environment.Issues -contains "Conda not initialized in PowerShell profile") {
        try {
            Write-Host "Initializing conda in PowerShell profile..."
            conda init powershell
            Write-Host "  [OK] Conda initialization completed" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERROR] Failed to initialize conda: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Install missing packages
    if ($verificationResults.Components.Packages.Details.Missing.Count -gt 0) {
        try {
            $missingList = $verificationResults.Components.Packages.Details.Missing -join ' '
            Write-Host "Installing missing packages in first_year environment: $missingList"
            conda install -n first_year -y $missingList
            Write-Host "  [OK] Packages installation completed" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERROR] Failed to install packages: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Generate output if requested
if ($OutputPath -and $OutputFormat) {
    switch ($OutputFormat.ToLower()) {
        "json" {
            $verificationResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "Verification results saved to: $OutputPath (JSON format)" -ForegroundColor Green
        }
        "html" {
            # Generate basic HTML report
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>DTU Python Support - Verification Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .pass { color: green; } .fail { color: red; }
        .issues { background: #fff3cd; padding: 10px; margin: 10px 0; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>DTU Python Support - Verification Report</h1>
    <p><strong>Overall Status:</strong> <span class="$(if ($verificationResults.OverallStatus) { 'pass' } else { 'fail' })">$statusText</span></p>
    <p><strong>Generated:</strong> $($verificationResults.Timestamp)</p>
    <p><strong>Computer:</strong> $($verificationResults.Computer) | <strong>User:</strong> $($verificationResults.User)</p>
    
    <h2>Component Status</h2>
    <table>
        <tr><th>Component</th><th>Status</th><th>Version</th><th>Issues</th></tr>
"@
            
            foreach ($componentName in $verificationResults.Components.Keys) {
                $component = $verificationResults.Components[$componentName]
                $statusClass = if ($component.Status) { "pass" } else { "fail" }
                $statusSymbol = if ($component.Status) { "[PASS]" } else { "[FAIL]" }
                $issues = if ($component.Issues.Count -gt 0) { $component.Issues -join "; " } else { "None" }
                
                $html += "<tr><td>$componentName</td><td class='$statusClass'>$statusSymbol</td><td>$($component.Version)</td><td>$issues</td></tr>"
            }
            
            $html += @"
    </table>
</body>
</html>
"@
            
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "Verification results saved to: $OutputPath (HTML format)" -ForegroundColor Green
        }
    }
}

# Return exit code based on verification status
if ($verificationResults.OverallStatus) {
    Write-Host "All components verified successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Verification failed. Please review the issues above." -ForegroundColor Red
    Write-Host "For help, visit: https://pythonsupport.dtu.dk" -ForegroundColor Yellow
    exit 1
}