

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

$healthCheckResults = 
[ordered]@{
    "python"            = @{
        "name"      = "Python"
        "installed" = $null
        "path"      = $null
        "version"   = $null
    }
    "conda"             = @{
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
        $healthCheckResults.$program.version = & $program --version 2>&1
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
    Write-Host "`nChecking for Conda/Anaconda installations..."
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
        "$env:SystemDrive\Anaconda3"
    )

    $AenvFound = $false
    foreach ($location in $anacondaLocations) {
        if (Test-Path $location) {
            Write-Host "`nAnaconda installation found"
            
            # Get the list of environments
            $anacondaEnvs = & "$location\Scripts\conda.exe" info --envs 2>$null

            if ($anacondaEnvs -match "^\s*#") { # Extract environment names
                $envLines = $anacondaEnvs -split "`n" | Where-Object { $_ -match "^\s*[^#]" }

                if ($envLines.Count -gt 0) {
                    foreach ($line in $envLines) {
                        $envName = $line -replace '^\s*-\s*', '' -replace '\s+\S*$', ''
                        Write-Host $envName
                    }
                    $AenvFound = $true
                }
            }
        }
    }
    if (-not $AenvFound) {
        Write-Host "`nNo Anaconda installation found."
    } elseif (-not $AenvFound) {
        Write-Host "`nNo Anaconda environments found."
    }
}

function Get-CondaEnvironmentsVerbose {
    param (
        [string[]]$pn = @("dtumathtools", "scipy", "pandas", "statsmodels", "uncertainties")  # List of packages to check
    )

    Write-Host
    Write-Host "`nChecking for Conda/Anaconda installations..."
    Write-Host ("=" * $displayWidth)

    # Function to check if packages are installed in a given environment and display their versions
    function Test-PackagesInEnvironment {
        param (
            [string]$envName,
            [string]$condaPath
        )

        $colorCodeGreen = "[1;42m"
        $colorCodeRed = "[1;41m"
        $resetColor = "[0m"  # Reset to default color

        # Get the Python version for the environment
        $pythonVersion = & $condaPath run -n $envName python --version 2>$null

        Write-Host "`nEnvironment: $envName ($pythonVersion)"
        Write-Host ("----")

        # Print header for columns
        Write-Host ("{0,-20} {1,-15} {2,-10}" -f "Package", "Status", "Version")

        foreach ($packageName in $pn) {
            # List the package in the specific environment
            $packageCheck = & $condaPath list -n $envName $packageName 2>$null
            if ($packageCheck -match $packageName) {
                # Extract the package info line containing the version
                $packageInfo = $packageCheck | Where-Object { $_ -match $packageName }

                # Extract the version number from the package info
                $packageVersion = ($packageInfo -split '\s+') | Select-Object -Index 1
                
                if ($packageVersion) {
                    # Print aligned output with status and version
                    Write-Host ("{0,-20} {1,-20} {2,-10}" -f $packageName, "${colorCodeGreen}INSTALLED${resetColor}      ", $packageVersion)
                } else {
                    Write-Host ("{0,-20} {1,-20} {2,-10}" -f $packageName, "${colorCodeGreen}INSTALLED${resetColor}      ", "N/A")
                }
            } else {
                # Print not installed packages
                Write-Host ("{0,-20} {1,-15}" -f $packageName, "${colorCodeRed}NOT INSTALLED${resetColor}")
            }
        }
    }

    # Check if Conda is in the PATH
    $condaInPath = Get-Command conda -ErrorAction SilentlyContinue
    if ($condaInPath) {
        $CenvFound = $false
        # Get the list of environments
        $condaEnvs = & conda info --envs 2>$null

        # Check if any environments were found
        if ($condaEnvs -match "^\s*#") {
            # Extract environment names
            $envLines = $condaEnvs -split "`n" | Where-Object { $_ -match "^\s*[^#]" }

            if ($envLines.Count -gt 0) {
                Write-Host "`nConda environments found:"
                foreach ($line in $envLines) {
                    $envName = $line -replace '^\s*-\s*', '' -replace '\s+\S*$', ''
                    Test-PackagesInEnvironment -envName $envName -condaPath "conda"
                }
                $CenvFound = $true
            }
        }

        if (-not $CenvFound) {
            Write-Host "`nNo Conda environments found."
        }
    }

    # Check for Anaconda installations (in case conda is not in PATH)
    $anacondaLocations = @(
        "$env:ProgramFiles\Anaconda3",
        "$env:ProgramFiles(x86)\Anaconda3",
        "$env:LOCALAPPDATA\Continuum\anaconda3",
        "$env:SystemDrive\Anaconda3"
    )

    $AenvFound = $false
    foreach ($location in $anacondaLocations) {
        if (Test-Path $location) {
            Write-Host "`nAnaconda installation found"
            $AenvFound = $true
            
            # Get the list of environments
            $anacondaEnvs = & "$location\Scripts\conda.exe" info --envs 2>$null

            # Check if any environments were found
            if ($anacondaEnvs -match "^\s*#") {
                # Extract environment names
                $envLines = $anacondaEnvs -split "`n" | Where-Object { $_ -match "^\s*[^#]" }

                if ($envLines.Count -gt 0) {
                    Write-Host "`nAnaconda environments found:"
                    foreach ($line in $envLines) {
                        $envName = $line -replace '^\s*-\s*', '' -replace '\s+\S*$', ''
                        Test-PackagesInEnvironment -envName $envName -condaPath "$location\Scripts\conda.exe"
                    }
                    $AenvFound = $true
                }
            }
        }
    }
    
    if (-not $AenvFound) {
        Write-Host "`nNo Anaconda installation found."
    } elseif (-not $AenvFound) {
        Write-Host "`nNo Anaconda environments found."
    }
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
    Get-CondaEnvironments
}

# Check if the script is run in verbose mode
if ($args[0] -contains "--verbose" -or $args[0] -contains "-v") {
    verboseOutput
}
else {
    nonVerboseOutput
}

# Check for Conda environments and package specifictaion
if ($args[1] -contains "--ce" -or $args[1] -contains "-ce") {
    if ($args[2]) {
        Get-CondaEnvironmentsVerbose -pn @($args[2..($args.Length-1)])
    }
    else {
        Get-CondaEnvironmentsVerbose
    }
}