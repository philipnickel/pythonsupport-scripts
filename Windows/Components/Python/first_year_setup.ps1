# @doc
# @name: First Year Python Setup
# @description: Configures Python environment for first year students with required packages
# @category: Python
# @usage: . .\first_year_setup.ps1
# @requirements: conda must be installed and available in PATH
# @notes: Creates Python 3.11 environment with DTU-specific packages for first year students
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

Write-LogInfo "First year Python environment setup"
Write-LogInfo "Starting configuration process..."

# Check if conda is available
Write-LogInfo "Checking conda availability..."
try {
    $condaVersion = conda --version
    Write-LogSuccess "Conda is available: $condaVersion"
}
catch {
    Write-LogError "Conda is not available in PATH"
    Exit-Message
}

# Set Python version (default to 3.11 if not specified)
if (-not $env:PYTHON_VERSION_PS) {
    $env:PYTHON_VERSION_PS = "3.11"
}

Write-LogInfo "Configuring Python $env:PYTHON_VERSION_PS environment..."

# Create or update base environment with required packages
Write-LogInfo "Installing required packages in base environment..."

$packages = @(
    "python=$env:PYTHON_VERSION_PS",
    "pandas",
    "scipy", 
    "statsmodels",
    "uncertainties",
    "dtumathtools",
    "jupyter",
    "ipykernel",
    "matplotlib",
    "seaborn",
    "numpy"
)

try {
    # Install packages in base environment
    $packageString = $packages -join " "
    conda install -y $packageString
    Check-ExitCode "Failed to install packages in base environment"
    
    Write-LogSuccess "Packages installed successfully in base environment"
}
catch {
    Write-LogError "Failed to install packages: $($_.Exception.Message)"
    Exit-Message
}

# Create first year environment
$envName = "first_year"
Write-LogInfo "Creating first year environment: $envName"

try {
    # Check if environment already exists
    $envExists = conda env list | Select-String "^$envName\s"
    
    if ($envExists) {
        Write-LogInfo "Environment $envName already exists, updating..."
        conda env update -n $envName -f "$env:USERPROFILE\miniforge3\envs\$envName\environment.yml" 2>$null
    }
    else {
        Write-LogInfo "Creating new environment $envName..."
        conda create -n $envName python=$env:PYTHON_VERSION_PS -y
        Check-ExitCode "Failed to create environment $envName"
    }
}
catch {
    Write-LogError "Failed to create/update environment: $($_.Exception.Message)"
    Exit-Message
}

# Install packages in first year environment
Write-LogInfo "Installing packages in $envName environment..."

try {
    conda activate $envName
    conda install -n $envName -y $packageString
    Check-ExitCode "Failed to install packages in $envName environment"
    
    Write-LogSuccess "Packages installed successfully in $envName environment"
}
catch {
    Write-LogError "Failed to install packages in $envName environment: $($_.Exception.Message)"
    Exit-Message
}

# Install Jupyter kernel for the environment
Write-LogInfo "Installing Jupyter kernel for $envName environment..."
try {
    conda activate $envName
    python -m ipykernel install --user --name $envName --display-name "Python $env:PYTHON_VERSION_PS (First Year)"
    Check-ExitCode "Failed to install Jupyter kernel"
    
    Write-LogSuccess "Jupyter kernel installed successfully"
}
catch {
    Write-LogError "Failed to install Jupyter kernel: $($_.Exception.Message)"
    Exit-Message
}

# Verify installation
Write-LogInfo "Verifying installation..."

try {
    # Test Python version
    conda activate $envName
    $pythonVersion = python --version
    Write-LogInfo "Python version: $pythonVersion"
    
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
    Check-ExitCode "Package import test failed"
    
    Write-LogSuccess "All packages verified successfully"
}
catch {
    Write-LogError "Verification failed: $($_.Exception.Message)"
    Exit-Message
}

# Configure conda to activate first year environment by default
Write-LogInfo "Configuring conda to activate first year environment by default..."
try {
    # Add activation to PowerShell profile
    $profilePath = Set-PowerShellProfile
    $activationLine = "conda activate $envName"
    
    if (-not (Select-String -Path $profilePath -Pattern $activationLine -Quiet)) {
        Add-Content -Path $profilePath -Value "`n# Auto-activate first year environment`n$activationLine"
        Write-LogSuccess "Added auto-activation to PowerShell profile"
    }
    else {
        Write-LogInfo "Auto-activation already configured"
    }
}
catch {
    Write-LogWarning "Failed to configure auto-activation: $($_.Exception.Message)"
}

# Set up environment variables
Write-LogInfo "Setting up environment variables..."
try {
    $env:CONDA_DEFAULT_ENV = $envName
    Write-LogSuccess "Environment variables configured"
}
catch {
    Write-LogWarning "Failed to set environment variables: $($_.Exception.Message)"
}

Write-LogSuccess "First year Python environment setup completed successfully!"
Write-LogInfo "You can now use Python $env:PYTHON_VERSION_PS with all required packages"
Write-LogInfo "To activate the environment manually, run: conda activate $envName"
