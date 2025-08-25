# @doc
# @name: First Year Students Setup
# @description: Complete installation orchestrator for DTU first year students - installs Python, VSCode, and configures development environment
# @category: Orchestrator
# @usage: . .\first_year_students.ps1
# @requirements: Windows 10/11, Internet connection, PowerShell 5.1+
# @notes: Uses master utility system for consistent error handling, logging, and user feedback. Orchestrates all component installations and configurations.
# @/doc

# Load master utilities
try {
    $masterUtilsUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Shared/master_utils.ps1"
    Invoke-Expression (Invoke-WebRequest -Uri $masterUtilsUrl -UseBasicParsing).Content
}
catch {
    Write-LogError "Failed to load master utilities: $($_.Exception.Message)"
    Exit-Message
}

Write-LogInfo "First year students orchestrator started"

# Initialize result tracking
$results = @{
    Python = $false
    VSCode = $false
    FirstYearSetup = $false
    Extensions = $false
}

# Install Python using component
Write-LogInfo "Installing Python..."
try {
    $pythonScriptUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/install.ps1"
    $pythonScript = Invoke-WebRequest -Uri $pythonScriptUrl -UseBasicParsing
    Invoke-Expression $pythonScript.Content
    $results.Python = $true
    Write-LogSuccess "Python installation completed successfully"
}
catch {
    Write-LogError "Python installation failed: $($_.Exception.Message)"
    $results.Python = $false
}

# Install VSCode using component
Write-LogInfo "Installing VSCode..."
try {
    $vscodeScriptUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/VSC/install.ps1"
    $vscodeScript = Invoke-WebRequest -Uri $vscodeScriptUrl -UseBasicParsing
    Invoke-Expression $vscodeScript.Content
    $results.VSCode = $true
    Write-LogSuccess "VSCode installation completed successfully"
}
catch {
    Write-LogError "VSCode installation failed: $($_.Exception.Message)"
    $results.VSCode = $false
}

# Run first year python setup (install specific version and packages)
if ($results.Python) {
    Write-LogInfo "Running first year Python environment setup..."
    try {
        $firstYearScriptUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Python/first_year_setup.ps1"
        $firstYearScript = Invoke-WebRequest -Uri $firstYearScriptUrl -UseBasicParsing
        Invoke-Expression $firstYearScript.Content
        $results.FirstYearSetup = $true
        Write-LogSuccess "First year Python setup completed successfully"
    }
    catch {
        Write-LogError "First year Python setup failed: $($_.Exception.Message)"
        $results.FirstYearSetup = $false
    }
}
else {
    Write-LogWarning "Skipping first year Python setup due to Python installation failure"
    $results.FirstYearSetup = $false
}

# Install VSCode extensions
if ($results.VSCode) {
    Write-LogInfo "Installing VSCode extensions for Python development..."
    try {
        $extensionsScriptUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/VSC/install_extensions.ps1"
        $extensionsScript = Invoke-WebRequest -Uri $extensionsScriptUrl -UseBasicParsing
        Invoke-Expression $extensionsScript.Content
        $results.Extensions = $true
        Write-LogSuccess "VSCode extensions installation completed successfully"
    }
    catch {
        Write-LogError "VSCode extensions installation failed: $($_.Exception.Message)"
        $results.Extensions = $false
    }
}
else {
    Write-LogWarning "Skipping VSCode extensions installation due to VSCode installation failure"
    $results.Extensions = $false
}

# Check results and provide appropriate feedback
Write-LogInfo "Installation Summary:"
Write-LogInfo "  Python: $($results.Python ? '✓' : '✗')"
Write-LogInfo "  VSCode: $($results.VSCode ? '✓' : '✗')"
Write-LogInfo "  First Year Setup: $($results.FirstYearSetup ? '✓' : '✗')"
Write-LogInfo "  Extensions: $($results.Extensions ? '✓' : '✗')"

if (-not $results.Python) {
    Write-LogError "Python installation failed"
    Exit-Message
}
elseif (-not $results.VSCode) {
    Write-LogError "VSCode installation failed"
    Exit-Message
}
elseif (-not $results.FirstYearSetup) {
    Write-LogError "First year Python setup failed"
    Exit-Message
}
elseif (-not $results.Extensions) {
    Write-LogWarning "VSCode extensions installation failed, but core installation succeeded"
    Write-LogInfo "You can install extensions manually later"
}
else {
    Write-LogSuccess "All installations completed successfully!"
}

# Track overall success/failure
$allSuccessful = $results.Values -notcontains $false
if ($allSuccessful) {
    Write-LogSuccess "All components installed successfully"
}
else {
    Write-LogWarning "Some components failed to install"
}

# Final verification
Write-LogInfo "Running final verification..."

# Verify conda
try {
    $condaVersion = conda --version
    Write-LogSuccess "Conda verification: $condaVersion"
}
catch {
    Write-LogError "Conda verification failed"
}

# Verify VSCode
try {
    $codeVersion = & code --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "VSCode verification: $($codeVersion[0])"
    }
    else {
        Write-LogError "VSCode verification failed"
    }
}
catch {
    Write-LogError "VSCode verification failed: $($_.Exception.Message)"
}

# Verify Python and packages
try {
    conda activate first_year
    $pythonVersion = python --version
    Write-LogSuccess "Python verification: $pythonVersion"
    
    # Test package imports
    $testScript = @"
import dtumathtools, pandas, scipy, statsmodels, uncertainties
print("All required packages imported successfully!")
"@
    $testScript | python
    Write-LogSuccess "Package verification: All packages imported successfully"
}
catch {
    Write-LogError "Python/package verification failed: $($_.Exception.Message)"
}

Write-LogInfo "Script has finished. You may now close the terminal..."

# Final step: provide user with next steps
Write-LogInfo "Next steps:"
Write-LogInfo "1. Restart your terminal/PowerShell to ensure all PATH changes take effect"
Write-LogInfo "2. Open VSCode and start coding with Python!"
Write-LogInfo "3. Use 'conda activate first_year' to activate the Python environment"
Write-LogInfo "4. Visit https://pythonsupport.dtu.dk for additional resources"

Write-LogSuccess "Windows first year students setup completed!"
