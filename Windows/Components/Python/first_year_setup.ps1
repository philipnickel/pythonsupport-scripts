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
    exit 1
}

# Set Python version (default to 3.11 if not specified)
if (-not $env:PYTHON_VERSION_PS) {
    $env:PYTHON_VERSION_PS = "3.11"
}

Write-Host "Configuring Python $env:PYTHON_VERSION_PS environment..."

# Install Python 3.11 and required packages in base environment
Write-Host "Installing Python $env:PYTHON_VERSION_PS and required packages in base environment..."

try {
    # Install Python 3.11 and all packages in one command for speed
    Write-Host "Installing Python $env:PYTHON_VERSION_PS and all required packages..."
    conda install --solver=classic -y "python=$env:PYTHON_VERSION_PS" pandas scipy statsmodels uncertainties jupyter ipykernel matplotlib seaborn numpy
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install Python and packages"
        exit 1
    }
    
    Write-Host "All packages installed successfully in base environment"
}
catch {
    Write-Host "Failed to install packages: $($_.Exception.Message)"
    exit 1
}

# Verify installation
Write-Host "Verifying installation..."

try {
    # Test Python version
    $pythonVersion = conda run python --version
    Write-Host "Python version: $pythonVersion"
    
    # Test package imports
    $testScript = @"
import sys
print(f"Python version: {sys.version}")

packages = ['pandas', 'scipy', 'statsmodels', 'uncertainties']
for package in packages:
    try:
        __import__(package)
        print(f"✓ {package} imported successfully")
    except ImportError as e:
        print(f"✗ {package} import failed: {e}")
        sys.exit(1)

print("All packages imported successfully!")
"@
    
    # Set environment variable to disable conda plugins and make it non-interactive
    $env:CONDA_NO_PLUGINS = "true"
    conda run python -c $testScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Package import test failed"
        exit 1
    }
    
    Write-Host "All packages verified successfully"
}
catch {
    Write-Host "Verification failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "First year Python environment setup completed successfully!"
Write-Host "You can now use Python $env:PYTHON_VERSION_PS with all required packages in the base environment"
