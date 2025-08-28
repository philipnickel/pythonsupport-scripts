# @doc
# @name: DTU Python Support - Conda Uninstaller
# @description: Removes conda/miniforge/miniconda/anaconda installations and cleans up configurations
# @category: Core
# @usage: . .\uninstall_conda.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Removes conda distributions and cleans up conda init modifications
# @/doc

param(
    [switch]$UseGUI = $true,
    [switch]$Force = $false
)

# Load GUI dialogs if available
$useNativeDialogs = $false
if ($UseGUI) {
    try {
        $dialogsUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/Components/Shared/windows_dialogs.ps1"
        $dialogsScript = Invoke-WebRequest -Uri $dialogsUrl -UseBasicParsing
        Invoke-Expression $dialogsScript.Content
        $useNativeDialogs = $true
    }
    catch {
        Write-Host "Failed to load GUI dialogs, using terminal interface" -ForegroundColor Yellow
    }
}

Write-Host "DTU Python Support - Conda Uninstaller" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Find conda installations
$installationsFound = @()
$condaPaths = @()

# Check for conda installations
$possibleCondaPaths = @(
    "$env:USERPROFILE\miniforge3",
    "$env:USERPROFILE\miniconda3", 
    "$env:USERPROFILE\anaconda3",
    "$env:ProgramData\miniforge3",
    "$env:ProgramData\miniconda3",
    "$env:ProgramData\anaconda3"
)

foreach ($path in $possibleCondaPaths) {
    if (Test-Path $path) {
        $condaPaths += $path
        $installType = Split-Path $path -Leaf
        $location = if ($path -like "*ProgramData*") { "System" } else { "User" }
        $installationsFound += "• $installType ($location): $path"
    }
}

# Show what was found
if ($installationsFound.Count -eq 0) {
    $message = "No conda installations found to uninstall."
    if ($useNativeDialogs) {
        Show-InfoDialog -Title "Nothing to Uninstall" -Message $message
    } else {
        Write-Host $message -ForegroundColor Green
    }
    exit 0
}

Write-Host "Found installations:" -ForegroundColor White
foreach ($installation in $installationsFound) {
    Write-Host $installation -ForegroundColor Yellow
}
Write-Host ""

# Confirm uninstall
$message = "The following conda installations will be completely removed:`n`n" + 
           ($installationsFound -join "`n") +
           "`n`nThis will also clean up:`n" +
           "• PowerShell profiles and PATH variables`n" +
           "• Conda configuration files and environments`n" +
           "• Conda initialization from shell profiles`n" +
           "`nWARNING: This action cannot be undone!`n`n" +
           "Do you want to continue?"

$confirm = $false
if ($useNativeDialogs) {
    $confirm = Show-ConfirmationDialog -Title "Confirm Conda Uninstall" -Message $message
} else {
    Write-Host "This will completely remove all conda installations and clean up configurations." -ForegroundColor Yellow
    Write-Host "WARNING: This action cannot be undone!" -ForegroundColor Red
    Write-Host ""
    
    if (-not $Force) {
        $response = Read-Host "Do you want to continue? (y/N)"
        $confirm = $response -eq "y" -or $response -eq "Y"
    } else {
        $confirm = $true
        Write-Host "Force mode enabled - proceeding with uninstall..." -ForegroundColor Yellow
    }
}

if (-not $confirm) {
    $message = "Uninstall cancelled by user."
    if ($useNativeDialogs) {
        Show-InfoDialog -Title "Uninstall Cancelled" -Message $message
    } else {
        Write-Host $message -ForegroundColor Yellow
    }
    exit 0
}

# Start uninstall process
$uninstallResults = @{
    CondaRemoval = $false
    ConfigCleanup = $false
}

if ($useNativeDialogs) {
    Show-ProgressDialog -Title "DTU Python Support Uninstaller" -InitialMessage "Starting uninstall process..." -InstallScript {
        # Uninstall conda installations
        if ($condaPaths.Count -gt 0) {
            Update-ProgressDialog -Message "Removing Python/Conda installations..."
            
            foreach ($path in $condaPaths) {
                try {
                    $installType = Split-Path $path -Leaf
                    Write-Host "• Removing $installType installation: $path"
                    
                    if ($path -like "*ProgramData*") {
                        Write-Host "  ⚠  System installation detected - may require administrator privileges" -ForegroundColor Yellow
                    }
                    
                    if (Test-Path $path) {
                        Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                        Write-Host "  [OK] Successfully removed $path" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "  [ERROR] Failed to remove $path : $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            $uninstallResults.CondaRemoval = $true
        }



        # Clean up PowerShell profiles
        Update-ProgressDialog -Message "Cleaning up PowerShell profiles..."
        
        try {
            $profilePaths = @(
                $PROFILE.CurrentUserCurrentHost,
                $PROFILE.CurrentUserAllHosts,
                $PROFILE.AllUsersCurrentHost,
                $PROFILE.AllUsersAllHosts
            )
            
            foreach ($profilePath in $profilePaths) {
                if ($profilePath -and (Test-Path $profilePath)) {
                    Write-Host "• Cleaning PowerShell profile: $profilePath"
                    
                    # Create backup
                    $backupPath = "${profilePath}.backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                    Copy-Item $profilePath $backupPath -Force
                    
                    # Read and clean profile
                    $content = Get-Content $profilePath -Raw
                    
                    # Remove conda initialization blocks
                    $content = $content -replace '(?s)# >>> conda initialize >>>.*?# <<< conda initialize <<<\s*', ''
                    
                    # Remove conda-related lines
                    $lines = $content -split "`r?`n"
                    $cleanLines = $lines | Where-Object { 
                        $_ -notmatch 'conda|miniforge|miniconda|anaconda' 
                    }
                    
                    # Write cleaned content back
                    $cleanLines -join "`r`n" | Set-Content $profilePath -Force
                    
                    Write-Host "  [OK] Profile cleaned (backup: $backupPath)" -ForegroundColor Green
                }
            }
            $uninstallResults.ProfileCleanup = $true
            
        } catch {
            Write-Host "  [ERROR] Failed to clean profiles: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Clean up environment variables and PATH
        Update-ProgressDialog -Message "Cleaning up environment variables..."
        
        try {
            Write-Host "• Cleaning up PATH environment variable..."
            
            # Get current PATH variables
            $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            
            # Clean user PATH
            if ($userPath) {
                $cleanUserPath = ($userPath -split ';' | Where-Object { 
                    $_ -notmatch 'conda|miniforge|miniconda|anaconda'
                }) -join ';'
                [Environment]::SetEnvironmentVariable("PATH", $cleanUserPath, "User")
                Write-Host "  [OK] User PATH cleaned" -ForegroundColor Green
            }
            
            # Note: We don't modify machine PATH as it may require admin privileges
            Write-Host "  Note: Machine PATH not modified (may require administrator privileges)"
            
            # Remove conda-related environment variables
            $condaVars = @(
                "CONDA_DEFAULT_ENV", "CONDA_EXE", "CONDA_PREFIX", 
                "CONDA_PROMPT_MODIFIER", "CONDA_PYTHON_EXE", "CONDA_SHLVL"
            )
            
            foreach ($var in $condaVars) {
                if ([Environment]::GetEnvironmentVariable($var, "User")) {
                    [Environment]::SetEnvironmentVariable($var, $null, "User")
                    Write-Host "  [OK] Removed environment variable: $var" -ForegroundColor Green
                }
            }
            
            $uninstallResults.ConfigCleanup = $true
            
        } catch {
            Write-Host "  [ERROR] Failed to clean environment variables: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Clean up conda configuration directories
        Update-ProgressDialog -Message "Removing configuration files..."
        
        $configDirs = @(
            "$env:USERPROFILE\.conda",
            "$env:USERPROFILE\.condarc",
            "$env:USERPROFILE\.conda-env"
        )
        
        foreach ($dir in $configDirs) {
            if (Test-Path $dir) {
                try {
                    Write-Host "• Removing configuration: $dir"
                    Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
                    Write-Host "  [OK] Successfully removed $dir" -ForegroundColor Green
                } catch {
                    Write-Host "  [ERROR] Failed to remove $dir : $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }

        Update-ProgressDialog -Message "Uninstall completed!"
        Start-Sleep -Milliseconds 1000
    }
    
    # Show final summary
    Show-InstallationSummary -Results $uninstallResults
    
} else {
    # Terminal-based uninstall process
    Write-Host "Starting conda uninstall process..." -ForegroundColor Green
    
    # Remove conda installations using native uninstallers
    Write-Host "Removing conda installations..." -ForegroundColor Cyan
    
    if ($condaPaths.Count -gt 0) {
        foreach ($path in $condaPaths) {
            try {
                $installType = Split-Path $path -Leaf
                Write-Host "• Removing $installType installation: $path"
                
                if ($path -like "*ProgramData*") {
                    Write-Host "  ⚠  System installation detected - may require administrator privileges" -ForegroundColor Yellow
                }
                
                # Try to use native uninstaller first
                $uninstallerPath = "$path\Uninstall-$installType.exe"
                if (Test-Path $uninstallerPath) {
                    Write-Host "  Using native uninstaller: $uninstallerPath"
                    $process = Start-Process -FilePath $uninstallerPath -ArgumentList "/S" -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        Write-Host "  [OK] Native uninstaller completed successfully" -ForegroundColor Green
                    } else {
                        Write-Host "  [WARNING] Native uninstaller failed, removing manually" -ForegroundColor Yellow
                        Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                    }
                } else {
                    Write-Host "  No native uninstaller found, removing manually"
                    Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                }
                
                Write-Host "  [OK] Successfully removed $installType" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to remove $path : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        $uninstallResults.CondaRemoval = $true
    } else {
        Write-Host "• No conda installations found to remove"
    }
    
    # Clean up any remaining conda configuration
    Write-Host "Cleaning up remaining configuration..." -ForegroundColor Cyan
    
    try {
        # Clean up conda configuration directories
        $configDirs = @(
            "$env:USERPROFILE\.conda",
            "$env:USERPROFILE\.condarc",
            "$env:USERPROFILE\.conda-env"
        )
        
        foreach ($dir in $configDirs) {
            if (Test-Path $dir) {
                try {
                    Write-Host "• Removing configuration: $dir"
                    Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
                    Write-Host "  [OK] Successfully removed $dir" -ForegroundColor Green
                } catch {
                    Write-Host "  [ERROR] Failed to remove $dir : $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        
        $uninstallResults.ConfigCleanup = $true
        
    } catch {
        Write-Host "  [ERROR] Failed to clean configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[OK] Conda uninstall completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor White
    Write-Host "• Conda installations: $(if ($uninstallResults.CondaRemoval) { '[OK] Removed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.CondaRemoval) { 'Green' } else { 'Red' })
    Write-Host "• Configuration cleanup: $(if ($uninstallResults.ConfigCleanup) { '[OK] Completed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.ConfigCleanup) { 'Green' } else { 'Red' })
    Write-Host ""
    Write-Host "Important notes:" -ForegroundColor Yellow
    Write-Host "• Native uninstallers were used where available for proper cleanup"
    Write-Host "• You may need to restart your terminal for changes to take full effect"
    Write-Host ""
}

Write-Host "You can now reinstall conda if needed." -ForegroundColor Green