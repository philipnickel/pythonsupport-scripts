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

# Install Python 3.11 first
Write-Host "Installing Python $env:PYTHON_VERSION_PS..."
try {
    conda install -y "python=$env:PYTHON_VERSION_PS"
    Write-Host "Python $env:PYTHON_VERSION_PS installed successfully"
}
catch {
    Write-Host "Failed to install Python: $($_.Exception.Message)"
    exit 1
}

# Install required packages one by one to avoid conflicts
$packages = @("pandas", "scipy", "statsmodels", "uncertainties", "dtumathtools", "jupyter", "ipykernel", "matplotlib", "seaborn", "numpy")

Write-Host "Installing required packages..."
foreach ($package in $packages) {
    Write-Host "Installing $package..."
    try {
        conda install -y $package
        Write-Host "$package installed successfully"
    }
    catch {
        Write-Host "Failed to install $package"
        exit 1
    }
}

# Create first year environment
$envName = "first_year"
Write-Host "Creating first year environment: $envName"

try {
    # Check if environment already exists
    $envExists = conda env list | Select-String "^$envName\s"
    
    if ($envExists) {
        Write-Host "Environment $envName already exists, updating..."
        conda env update -n $envName -f "$env:USERPROFILE\miniforge3\envs\$envName\environment.yml" 2>$null
    }
    else {
        Write-Host "Creating new environment $envName..."
        conda create -n $envName python=$env:PYTHON_VERSION_PS -y
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to create environment $envName"
            exit 1
        }
    }
}
catch {
    Write-Host "Failed to create/update environment: $($_.Exception.Message)"
    exit 1
}

# Install packages in first year environment
Write-Host "Installing packages in $envName environment..."

try {
    conda activate $envName
    conda install -n $envName -y $packageString
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install packages in $envName environment"
        exit 1
    }
    
    Write-Host "Packages installed successfully in $envName environment"
}
catch {
    Write-Host "Failed to install packages in $envName environment: $($_.Exception.Message)"
    exit 1
}

# Install Jupyter kernel for the environment
Write-Host "Installing Jupyter kernel for $envName environment..."
try {
    conda activate $envName
    python -m ipykernel install --user --name $envName --display-name "Python $env:PYTHON_VERSION_PS (First Year)"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install Jupyter kernel"
        exit 1
    }
    
    Write-Host "Jupyter kernel installed successfully"
}
catch {
    Write-Host "Failed to install Jupyter kernel: $($_.Exception.Message)"
    exit 1
}

# Verify installation
Write-Host "Verifying installation..."

try {
    # Test Python version
    conda activate $envName
    $pythonVersion = python --version
    Write-Host "Python version: $pythonVersion"
    
    # Test package imports
    $testScript = @"
import sys
print(f"Python version: {sys.version}")

packages = ['dtumathtools', 'pandas', 'scipy', 'statsmodels', 'uncertainties']
for package in packages:
    try:
        __import__(package)
        print(f"✓ {package} imported successfully")
    except ImportError as e:
        print(f"✗ {package} import failed: {e}")
        sys.exit(1)

print("All packages imported successfully!")
"@
    
    $testScript | python
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
Write-Host "You can now use Python $env:PYTHON_VERSION_PS with all required packages"
Write-Host "To activate the environment manually, run: conda activate $envName"
