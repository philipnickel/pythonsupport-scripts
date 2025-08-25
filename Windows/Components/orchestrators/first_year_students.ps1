# @doc
# @name: First Year Students Setup
# @description: Complete installation orchestrator for DTU first year students - installs Python, VSCode, and configures development environment
# @category: Orchestrator
# @usage: . .\first_year_students.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Orchestrates all component installations and configurations.
# @/doc

Write-Host "First year students orchestrator started"

# Initialize result tracking
$results = @{
    Python = $false
    VSCode = $false
    FirstYearSetup = $false
}

# Install Python using component
Write-Host "Installing Python..."
try {
    $pythonScriptUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/install.ps1"
    $pythonScript = Invoke-WebRequest -Uri $pythonScriptUrl -UseBasicParsing
    Invoke-Expression $pythonScript.Content
    $results.Python = $true
    Write-Host "Python installation completed successfully"
}
catch {
    Write-Host "Python installation failed: $($_.Exception.Message)"
    $results.Python = $false
}

# Install VSCode using component
Write-Host "Installing VSCode..."
try {
    $vscodeScriptUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/VSC/install.ps1"
    $vscodeScript = Invoke-WebRequest -Uri $vscodeScriptUrl -UseBasicParsing
    Invoke-Expression $vscodeScript.Content
    $results.VSCode = $true
    Write-Host "VSCode installation completed successfully"
}
catch {
    Write-Host "VSCode installation failed: $($_.Exception.Message)"
    $results.VSCode = $false
}

# Run first year python setup (install specific version and packages)
if ($results.Python) {
    Write-Host "Running first year Python environment setup..."
    try {
        $firstYearScriptUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/first_year_setup.ps1"
        $firstYearScript = Invoke-WebRequest -Uri $firstYearScriptUrl -UseBasicParsing
        Invoke-Expression $firstYearScript.Content
        $results.FirstYearSetup = $true
        Write-Host "First year Python setup completed successfully"
    }
    catch {
        Write-Host "First year Python setup failed: $($_.Exception.Message)"
        $results.FirstYearSetup = $false
    }
}
else {
    Write-Host "Skipping first year Python setup due to Python installation failure"
    $results.FirstYearSetup = $false
}

# Check results and provide appropriate feedback
Write-Host "Installation Summary:"
Write-Host "  Python: $($results.Python ? '✓' : '✗')"
Write-Host "  VSCode: $($results.VSCode ? '✓' : '✗')"
Write-Host "  First Year Setup: $($results.FirstYearSetup ? '✓' : '✗')"

if (-not $results.Python) {
    Write-Host "Python installation failed"
    exit 1
}
elseif (-not $results.VSCode) {
    Write-Host "VSCode installation failed"
    exit 1
}
elseif (-not $results.FirstYearSetup) {
    Write-Host "First year Python setup failed"
    exit 1
}
else {
    Write-Host "All installations completed successfully!"
}

# Track overall success/failure
$allSuccessful = $results.Values -notcontains $false
if ($allSuccessful) {
    Write-Host "All components installed successfully"
}
else {
    Write-Host "Some components failed to install"
}

# Final verification
Write-Host "Running final verification..."

# Verify conda
try {
    $condaVersion = conda --version
    Write-Host "Conda verification: $condaVersion"
}
catch {
    Write-Host "Conda verification failed"
}

# Verify VSCode
try {
    $codeVersion = & code --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "VSCode verification: $($codeVersion[0])"
    }
    else {
        Write-Host "VSCode verification failed"
    }
}
catch {
    Write-Host "VSCode verification failed: $($_.Exception.Message)"
}

# Verify Python and packages
try {
    conda activate first_year
    $pythonVersion = python --version
    Write-Host "Python verification: $pythonVersion"
    
    # Test package imports
    $testScript = @"
import dtumathtools, pandas, scipy, statsmodels, uncertainties
print("All required packages imported successfully!")
"@
    $testScript | python
    Write-Host "Package verification: All packages imported successfully"
}
catch {
    Write-Host "Python/package verification failed: $($_.Exception.Message)"
}

Write-Host "Script has finished. You may now close the terminal..."

# Final step: provide user with next steps
Write-Host "Next steps:"
Write-Host "1. Restart your terminal/PowerShell to ensure all PATH changes take effect"
Write-Host "2. Open VSCode and start coding with Python!"
Write-Host "3. Use 'conda activate first_year' to activate the Python environment"
Write-Host "4. Visit https://pythonsupport.dtu.dk for additional resources"

Write-Host "Windows first year students setup completed!"
