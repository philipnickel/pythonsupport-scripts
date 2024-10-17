

# Create a colorful banner
$text = "Welcome to the Python Support Health Check"
$textLength = $text.Length
$padding = 10

$leftPadding = " " * $padding
$rightPadding = " " * $padding
$topBottomSide = "*" * (($padding * 2) + 2 + $textLength)
$insideBoxWidth = " " * (($padding * 2) + $textLength)

$banner = @"
[1;34m
$topBottomSide
*$insideBoxWidth*
*[1;32m$leftPadding$text$rightPadding[1;34m*
*$insideBoxWidth*
$topBottomSide
[0m
"@

Write-Host $banner

$colorCodeGreen = "[1;42m"
$colorCodeRed = "[1;41m"
$resetColor = "[0m"  # Reset to default color

$healthCheckResults = 
[ordered]@{
    "python"            = @{
        "name"      = "Python"
        "installed" = $null
        "path"      = $null
        "version"   = $null
    }
    "conda"            = @{
        "name"      = "Conda"
        "installed" = $null
        "path"      = $null
        "version"   = $null
    }
    "code"              = @{
        "name"      = "Visual Studio Code"
        "installed" = $null
        "path"      = $null
        "version"   = $null
        "extensions" = @{
            "ms-python.python" = @{
                "name"      = "Python Extension"
                "installed" = $null
                "version"   = $null
            }
            "ms-toolsai.jupyter" = @{
                "name"      = "Jupyter Extension"
                "installed" = $null
                "version"   = $null
            }
        }
    }
    "firstYearPackages" = @{
        "dtumathtools"  = @{
            "name"      = "DTU Math Tools"
            "installed" = $null
            "path"      = $null
            "source"    = $null
            "version"   = $null
        }
        "pandas"        = @{
            "name"      = "Pandas"
            "installed" = $null
            "path"      = $null
            "source"    = $null
            "version"   = $null
        }
        "scipy"         = @{
            "name"      = "Scipy"
            "installed" = $null
            "path"      = $null
            "source"    = $null
            "version"   = $null
        }
        "statsmodels"   = @{
            "name"      = "Statsmodels"
            "installed" = $null
            "path"      = $null
            "source"    = $null
            "version"   = $null
        }
        "uncertainties" = @{
            "name"      = "Uncertainties"
            "installed" = $null
            "path"      = $null
            "source"    = $null
            "version"   = $null
        }
    }
}
# Getting keys for the required programs and packages
$allKeys = @($healthCheckResults.Keys.GetEnumerator() | ForEach-Object { $_ })
$requiredPrograms = $allKeys[0..($allKeys.Length - 2)]

$requiredPackages = @($healthCheckResults.firstYearPackages.Keys.GetEnumerator() | ForEach-Object { $_ })


# Check if the required programs are installed
foreach ($program in $requiredPrograms) {
    $programPath = where.exe $program
    if ($programPath) {
        $healthCheckResults.$program.installed = $true
        $healthCheckResults.$program.path = $programPath
        
        if ($program -eq "conda") {
            # Check if it's Miniconda or Anaconda
            $condaInstallPath = $healthCheckResults.conda.path

            if ($condaInstallPath -match "miniconda") {
                $healthCheckResults.conda.name = "Default Conda - Miniconda"
            } elseif ($condaInstallPath -match "anaconda") {
                $healthCheckResults.conda.name = "Default Conda - Anaconda"
            }

            # Get the conda version
            $condaVersion = & conda --version
            $healthCheckResults.conda.version = $condaVersion
        } else {
            $healthCheckResults.$program.version = & $program --version 2>&1
        }
    } else {
        $healthCheckResults.$program.installed = $false
        $healthCheckResults.$program.path = $null
        $healthCheckResults.$program.version = $null
    }

    # Check if the required extensions are installed
    if ($program -eq "code") {
        foreach ($extention in $healthCheckResults.code.extensions.Keys) {
            $extensionPath = code --list-extensions --show-versions | Select-String -Pattern $extention
            if ($extensionPath) {
                $healthCheckResults.code.extensions.$extention.installed = $true
                $healthCheckResults.code.extensions.$extention.version = ($extensionPath -split "@")[1]
            } else {
                $healthCheckResults.code.extensions.$extention.installed = $false
                $healthCheckResults.code.extensions.$extention.version = $null
            }
        }
    }
}

# Check if required packages are installed
foreach ($package in $requiredPackages) {
    
    if ($healthCheckResults.conda.install -eq $false) {
        $packageCheck = pip list | Select-String -Pattern $package
        $packageCheckResult = $null -ne $packageCheck
        if ($packageCheckResult) {
            $packageVersion = ($packageCheck -split "\s+")[1]
            $packageSource = "pip"
            $packagePath = python -c "import pandas;pandas.__file__"
        }

    }
    else {
        $packageCheck = conda list | Select-String -Pattern $package
        $packageCheckResult = $null -ne $packageCheck
        if ($packageCheckResult) {
            $packageVersion = ($packageCheck -split "\s+")[1]
            $packageSource = ($packageCheck -split "\s+")[-1]
            $packagePath = python -c "import $package;print($package.__file__)"
        }
    }
    $healthCheckResults.firstYearPackages.$package.installed = $packageCheckResult
    $healthCheckResults.firstYearPackages.$package.version = $packageVersion
    $healthCheckResults.firstYearPackages.$package.source = $packageSource  
    $healthCheckResults.firstYearPackages.$package.path = $packagePath

    $packageVersion = $null
    $packageSource = $null
    $packagePath = $null    
}



# Display the health check results
$displayWidth = 30


function Get-CondaEnvironments {
    Write-Host
    Write-Host "`nChecking for Conda enviroment and installations"
    Write-Host ("=" * $displayWidth)
    

    $condaInPath = Get-Command conda -ErrorAction SilentlyContinue # Check if conda is in the PATH
    if ($condaInPath) {
        $CenvFound = $false
        $condaEnvs = & conda info --envs 2>$null


        if ($condaEnvs -match "^\s*#") { # Check if any environments were found
            $envLines = $condaEnvs -split "`n" | Where-Object { $_ -match "^\s*[^#]" }

            if ($envLines.Count -gt 0) {
                Write-Host "`nConda environments found:"
                foreach ($line in $envLines) {
                    $envName = $line -replace '^\s*-\s*', '' -replace '\s+\S*$', ''
                    Write-Host $envName
                }
                $CenvFound = $true
            }
        }
        
        if (-not $CenvFound) {
            Write-Host "`nNo Conda environments found."
    }
    }

    # Check for Anaconda installations 
    $anacondaLocations = @(
        "$env:ProgramFiles\Anaconda3",
        "$env:ProgramFiles(x86)\Anaconda3",
        "$env:LOCALAPPDATA\Continuum\anaconda3",
        "$env:SystemDrive\Anaconda3",
        "$env:USERPROFILE\Anaconda3" 
    )

    $AenvFound = $false
    foreach ($location in $anacondaLocations) {
        if (Test-Path $location) {
            Write-Host "`nAnaconda installation found"
            $AenvFound = $true
        }
    }
    if (-not $AenvFound) {
        Write-Host "`nNo Anaconda installation found."
    }
}



function Test-PythonPackages {
    Write-Host "`n"
    Write-Host "`nVerifying Importation of Required Python Packages"
    Write-Host ("=" * $displayWidth)

    $result = python -c "
try:
    import dtumathtools, pandas, scipy, statsmodels, uncertainties
    print('Success')
except ImportError:
    print('Failed')
" 2>$null

    if ($result -eq 'Success') {
        Write-Host ("{0,-30} {1,-20}"  -f "Verification", "${colorCodeGreen}SUCCESS${resetColor}")
    } else {
        Write-Host ("{0,-30} {1,-20}"  -f "Verification", "${colorCodeRed}FAILED${resetColor}")
    }
    Write-Host "`n"
}



# Verbose output
function verboseOutput {
    Write-Output "Health Check Detailed Summary:"
    Write-Host ("=" * $displayWidth)

    # First year programs
    foreach ($program in $requiredPrograms) {
        $programResults = $healthCheckResults.$program.installed
        $programName = $healthCheckResults.$program.name
        $programVersion = $healthCheckResults.$program.version
        $programPath = $healthCheckResults.$program.path
    
        if ($programResults -eq $true) {
            $status = "INSTALLED"
            $colorCode = "[1;42m"  # White text on green background
        }
        elseif ($programResults -eq $false) {
            $status = "NOT INSTALLED"
            $colorCode = "[1;41m"  # White text on red background
        }
        else {
            $status = "STILL CHECKING"
            $colorCode = "[1;43m"  # White text on yellow background
        }
    
        $resetColor = "[0m"  # Reset to default color
        Write-Output "${programName}: ${colorCode}${status}${resetColor}"
        Write-Output "Version: $programVersion"
        Write-Output "Path: $programPath"
    }

    # First year extensions
    foreach ($extension in $healthCheckResults.code.extensions.Keys) {
        $extensionResults = $healthCheckResults.code.extensions.$extension.installed
        $extensionName = $healthCheckResults.code.extensions.$extension.name
        $extensionVersion = $healthCheckResults.code.extensions.$extension.version
    
        if ($extensionResults -eq $true) {
            $status = "INSTALLED"
            $colorCode = "[1;42m"  # White text on green background
        }
        elseif ($extensionResults -eq $false) {
            $status = "NOT INSTALLED"
            $colorCode = "[1;41m"  # White text on red background
        }
        else {
            $status = "STILL CHECKING"
            $colorCode = "[1;43m"  # White text on yellow background
        }
    
        $resetColor = "[0m"  # Reset to default color
        Write-Output "${extensionName}: ${colorCode}${status}${resetColor}"
        Write-Output "Version: $extensionVersion"
    }

    # First year packages
    foreach ($package in $requiredPackages) {
        $packageResults = $healthCheckResults.firstYearPackages.$package.installed
        $packageName = $healthCheckResults.firstYearPackages.$package.name
        $packageVersion = $healthCheckResults.firstYearPackages.$package.version
        $packagePath = $healthCheckResults.firstYearPackages.$package.path
        $packageSource = $healthCheckResults.firstYearPackages.$package.source
    
        if ($packageResults -eq $true) {
            $status = "INSTALLED"
            $colorCode = "[1;42m"  # White text on green background
        }
        elseif ($packageResults -eq $false) {
            $status = "NOT INSTALLED"
            $colorCode = "[1;41m"  # White text on red background
        }
        else {
            $status = "STILL CHECKING"
            $colorCode = "[1;43m"  # White text on yellow background
        }
    
        $resetColor = "[0m"  # Reset to default color
        Write-Output "${packageName}: ${colorCode}${status}${resetColor}"
        Write-Output "Version: $packageVersion"
        Write-Output "Source: $packageSource"
        Write-Output "Path: $packagePath"

    
    }
}

# Non-verbose output
$allinfo = [ordered]@{}
function nonVerboseOutput {
    Write-Output "Health Check Summary:"
    Write-Host ("=" * $displayWidth)
    
    foreach ($program in $requiredPrograms) {
        $programResults = $healthCheckResults.$program.installed
        $programName = $healthCheckResults.$program.name
        
        # First year programs
        if ($programResults -eq $true) {
            $status = "INSTALLED"
            $colorCode = "[1;42m"  # White text on green background
        }
        elseif ($programResults -eq $false) {
            $status = "NOT INSTALLED"
            $colorCode = "[1;41m"  # White text on red background
        }
        else {
            $status = "STILL CHECKING"
            $colorCode = "[1;43m"  # White text on yellow background
        }
    
        $resetColor = "[0m"  # Reset to default color
        $allinfo[$programName] = $colorCode+$status+$resetColor
        #Write-Output "${programName}: ${colorCode}${status}${resetColor}"
    }

    # First year extensions
    foreach ($extension in $healthCheckResults.code.extensions.Keys) {
        $extensionResults = $healthCheckResults.code.extensions.$extension.installed
        $extensionName = $healthCheckResults.code.extensions.$extension.name
    
        if ($extensionResults -eq $true) {
            $status = "INSTALLED"
            $colorCode = "[1;42m"  # White text on green background
        }
        elseif ($extensionResults -eq $false) {
            $status = "NOT INSTALLED"
            $colorCode = "[1;41m"  # White text on red background
        }
        else {
            $status = "STILL CHECKING"
            $colorCode = "[1;43m"  # White text on yellow background
        }
    
        $resetColor = "[0m"  # Reset to default color
        $allinfo[$extensionName] = $colorCode+$status+$resetColor
        #Write-Output "${extensionName}: ${colorCode}${status}${resetColor}"
    }
    
    # First year packages
    foreach ($package in $requiredPackages) {
        $packageResults = $healthCheckResults.firstYearPackages.$package.installed
        $packageName = $healthCheckResults.firstYearPackages.$package.name
    
        if ($packageResults -eq $true) {
            $status = "INSTALLED"
            $colorCode = "[1;42m"  # White text on green background
        }
        elseif ($packageResults -eq $false) {
            $status = "NOT INSTALLED"
            $colorCode = "[1;41m"  # White text on red background
        }
        else {
            $status = "STILL CHECKING"
            $colorCode = "[1;43m"  # White text on yellow background
        }
    
        $resetColor = "[0m"  # Reset to default color

        $allinfo[$packageName] = $colorCode+$status+$resetColor
        #Write-Output "${packageName}: ${colorCode}${status}${resetColor}"
    }

    Write-Output $allinfo
    Test-PythonPackages
    Get-CondaEnvironments
}

# Check if the script is run in verbose mode
if ($args[0] -contains "--verbose" -or $args[0] -contains "-v") {
    verboseOutput
}
else {
    nonVerboseOutput
}
