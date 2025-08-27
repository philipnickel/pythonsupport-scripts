# @doc
# @name: First Year Python Setup
# @description: Configures Python environment for first year students with required packages
# @category: Python
# @usage: . .\first_year_setup.ps1
# @requirements: conda must be installed and available in PATH
# @notes: Creates Python 3.11 environment with DTU-specific packages for first year students
# @/doc

Write-Host "First year Python environment setup"
Write-Host "Starting configuration process..."

# Check if conda is available
Write-Host "Checking conda availability..."
try {
    $condaVersion = conda --version
    Write-Host "Conda is available: $condaVersion"
}
catch {
    Write-Host "Conda is not available in PATH"
    throw "Conda is not available in PATH"
}

# Set Python version (default to 3.12 if not specified)
if (-not $env:PYTHON_VERSION_PS) {
    $env:PYTHON_VERSION_PS = "3.12"
}

Write-Host "Configuring Python $env:PYTHON_VERSION_PS environment..."

# Install Python 3.12 and required packages in base environment
Write-Host "Installing Python $env:PYTHON_VERSION_PS and required packages in base environment..."

try {
    # Install Python 3.12 and core packages in one command for speed
    Write-Host "Installing Python $env:PYTHON_VERSION_PS and core packages..."
    conda install -y "python=$env:PYTHON_VERSION_PS" dtumathtools pandas scipy statsmodels uncertainties
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install Python and packages"
        throw "Failed to install Python and packages"
    }
    
    Write-Host "Core packages installed successfully in base environment"
}
catch {
    Write-Host "Failed to install packages: $($_.Exception.Message)"
    throw "Failed to install packages"
}

Write-Host "First year Python environment setup completed successfully!"
Write-Host "You can now use Python $env:PYTHON_VERSION_PS with all required packages in the base environment"
