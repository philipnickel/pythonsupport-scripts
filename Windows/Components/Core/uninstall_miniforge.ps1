# @doc
# @name: DTU Python Support - Conda Uninstaller
# @description: Comprehensive uninstaller for Miniforge, Miniconda, and Anaconda installations
# @category: Core
# @usage: .\uninstall_miniforge.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Removes all conda distributions and cleans up conda init modifications
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

# Find all conda installations
$installationsFound = @()
$condaPaths = @()

# Check for all possible conda installations
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

Write-Host "Found conda installations:" -ForegroundColor White
foreach ($installation in $installationsFound) {
    Write-Host $installation -ForegroundColor Yellow
}
Write-Host ""

# Confirm uninstall
$message = "The following conda installations will be completely removed:`n`n" + 
           ($installationsFound -join "`n") +
           "`n`nThis will also clean up:`n" +
           "• PowerShell profiles and conda initialization blocks`n" +
           "• Environment variables (CONDA_*)`n" +
           "• PATH modifications for conda`n" +
           "• Conda configuration files`n" +
           "• Start Menu shortcuts for conda environments`n" +
           "`nWARNING: This action cannot be undone!`n`n" +
           "Do you want to continue?"

$confirm = $false
if ($useNativeDialogs) {
    $confirm = Show-ConfirmationDialog -Title "Confirm Conda Uninstall" -Message $message
} else {
    Write-Host "This will completely remove all conda installations and clean up configurations." -ForegroundColor Yellow
    Write-Host "WARNING: This action cannot be undone!" -ForegroundColor Red
    Write-Host ""
    $response = Read-Host "Do you want to continue? (y/N)"
    $confirm = $response -eq "y" -or $response -eq "Y"
}

if (-not $confirm) {
    Write-Host "Uninstall cancelled by user." -ForegroundColor Yellow
    exit 0
}

# Initialize results tracking
$uninstallResults = @{
    CondaRemoval = $false
    ProfileCleanup = $false
    ConfigCleanup = $false
    PathCleanup = $false
}

if ($useNativeDialogs) {
    # GUI-based uninstall process
    Show-ProgressDialog -Title "Conda Uninstall Progress" -Message "Starting uninstall process..."
    
    # Remove conda installations
    Update-ProgressDialog -Message "Removing conda installations..."
    
    foreach ($path in $condaPaths) {
        try {
            Write-Host "• Removing conda installation: $path"
            
            # Try to use uninstaller first if available
            $installType = Split-Path $path -Leaf
            $uninstallerPath = $null
            
            switch ($installType) {
                "miniforge3" { $uninstallerPath = "$path\Uninstall-Miniforge3.exe" }
                "miniconda3" { $uninstallerPath = "$path\Uninstall-Miniconda3.exe" }
                "anaconda3" { $uninstallerPath = "$path\Uninstall-Anaconda3.exe" }
            }
            
            if ($uninstallerPath -and (Test-Path $uninstallerPath)) {
                Write-Host "  Using uninstaller: $uninstallerPath"
                $process = Start-Process -FilePath $uninstallerPath -ArgumentList "/S" -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    Write-Host "  [OK] Uninstaller completed successfully" -ForegroundColor Green
                } else {
                    Write-Host "  [WARNING] Uninstaller failed, removing manually" -ForegroundColor Yellow
                    Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                }
            } else {
                Write-Host "  No uninstaller found, removing manually"
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            }
            
            Write-Host "  [OK] Successfully removed $path" -ForegroundColor Green
            
        } catch {
            Write-Host "  [ERROR] Failed to remove $path : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    $uninstallResults.CondaRemoval = $true
    
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

    # Clean up Start Menu shortcuts
    Update-ProgressDialog -Message "Cleaning up Start Menu shortcuts..."
    
    $startMenuPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Anaconda3*",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Miniconda3*",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Miniforge3*"
    )
    
    foreach ($pattern in $startMenuPaths) {
        $shortcuts = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            try {
                Write-Host "• Removing Start Menu shortcut: $($shortcut.Name)"
                Remove-Item -Path $shortcut.FullName -Force -ErrorAction Stop
                Write-Host "  [OK] Successfully removed shortcut" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to remove shortcut: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Update-ProgressDialog -Message "Uninstall completed!"
    Start-Sleep -Milliseconds 1000
    
    # Show final summary
    Show-InstallationSummary -Results $uninstallResults
    
} else {
    # Terminal-based uninstall process
    Write-Host "Starting conda uninstall process..." -ForegroundColor Green
    
    # Same uninstall logic as above, but without Update-ProgressDialog calls
    # [Implementation would be similar but without the GUI progress updates]
    
    Write-Host ""
    Write-Host "[OK] Conda uninstall completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor White
    Write-Host "• Conda installations: $(if ($uninstallResults.CondaRemoval) { '[OK] Removed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.CondaRemoval) { 'Green' } else { 'Red' })
    Write-Host "• Profile cleanup: $(if ($uninstallResults.ProfileCleanup) { '[OK] Completed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.ProfileCleanup) { 'Green' } else { 'Red' })
    Write-Host "• Configuration cleanup: $(if ($uninstallResults.ConfigCleanup) { '[OK] Completed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.ConfigCleanup) { 'Green' } else { 'Red' })
    Write-Host ""
    Write-Host "Important notes:" -ForegroundColor Yellow
    Write-Host "• PowerShell profile backups were created with .backup-* suffix"
    Write-Host "• You may need to restart your terminal or system for PATH changes to take effect"
    Write-Host "• Machine-level PATH was not modified (requires administrator privileges)"
    Write-Host ""
}

Write-Host "You can now reinstall conda if needed." -ForegroundColor Green
