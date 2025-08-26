# @doc
# @name: Master Utility Loader
# @description: Loads all Python Support utilities for Windows
# @category: Utilities
# @usage: . .\master_utils.ps1
# @requirements: PowerShell 5.1+, Windows 10/11
# @notes: Sources all utility modules in a single operation
# @/doc

# Master utility loader for Python Support Scripts - Windows
# This script loads all utility modules at once

# Standard prefix for all Python Support scripts
$script:Prefix = "PYS:"

# Set defaults only if environment variables are not already set
if (-not $env:REMOTE_PS) {
    $env:REMOTE_PS = "dtudk/pythonsupport-scripts"
}
if (-not $env:BRANCH_PS) {
    $env:BRANCH_PS = "main"
}

# Function to safely load a utility script
function Load-Utility {
    param(
        [string]$UtilName
    )
    
    try {
        $utilUrl = "https://raw.githubusercontent.com/$env:REMOTE_PS/$env:BRANCH_PS/Windows/Components/Shared/$UtilName.ps1"
        $utilScript = Invoke-WebRequest -Uri $utilUrl -UseBasicParsing -ErrorAction Stop
        if ($utilScript.Content) {
            # Execute in global scope to make functions available
            $scriptBlock = [ScriptBlock]::Create($utilScript.Content)
            & $scriptBlock
            Write-Host "$Prefix ✓ Loaded $UtilName utilities"
            return $true
        }
    }
    catch {
        Write-Host "$Prefix ✗ Failed to load $UtilName utilities"
        return $false
    }
}

# Load all utilities at once
function Load-AllUtilities {
    Write-Host "$Prefix Loading Python Support utilities from $env:REMOTE_PS/$env:BRANCH_PS..."
    
    # Load utilities in dependency order
    Load-Utility "error_handling"
    Load-Utility "environment"
    Load-Utility "dependencies"
    
    Write-Host "$Prefix ✓ All utilities loaded successfully"
}

# Load all utilities
Load-AllUtilities

# Set up default environment
try {
    Set-DefaultEnv
}
catch {
    # Ignore if function doesn't exist yet
}
