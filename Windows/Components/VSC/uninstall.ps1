# @doc
# @name: DTU Python Support - VS Code Uninstaller
# @description: Comprehensive uninstaller for Visual Studio Code
# @category: VSC
# @usage: .\uninstall.ps1
# @requirements: Windows 10/11, PowerShell 5.1+
# @notes: Removes VS Code and cleans up all user data and configurations
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

Write-Host "DTU Python Support - VS Code Uninstaller" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Find VS Code installations
$installationsFound = @()
$vscodePaths = @()

# Check for VS Code installations
$possibleVSCodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code",
    "$env:ProgramFiles\Microsoft VS Code",
    "$env:ProgramFiles(x86)\Microsoft VS Code"
)

foreach ($path in $possibleVSCodePaths) {
    if (Test-Path $path) {
        $vscodePaths += $path
        $location = if ($path -like "*LOCALAPPDATA*") { "User" } else { "System" }
        $installationsFound += "• Visual Studio Code ($location): $path"
    }
}

# Show what was found
if ($installationsFound.Count -eq 0) {
    $message = "No VS Code installations found to uninstall."
    if ($useNativeDialogs) {
        Show-InfoDialog -Title "Nothing to Uninstall" -Message $message
    } else {
        Write-Host $message -ForegroundColor Green
    }
    exit 0
}

Write-Host "Found VS Code installations:" -ForegroundColor White
foreach ($installation in $installationsFound) {
    Write-Host $installation -ForegroundColor Yellow
}
Write-Host ""

# Confirm uninstall
$message = "The following VS Code installations will be completely removed:`n`n" + 
           ($installationsFound -join "`n") +
           "`n`nThis will also clean up:`n" +
           "• User data directory (%APPDATA%\Code)`n" +
           "• User workspace settings (%USERPROFILE%\.vscode)`n" +
           "• VS Code extensions and configurations`n" +
           "• VS Code from PATH environment variable`n" +
           "• Start Menu shortcuts and desktop shortcuts`n" +
           "• File associations for .py files`n" +
           "`nWARNING: This action cannot be undone!`n`n" +
           "Do you want to continue?"

$confirm = $false
if ($useNativeDialogs) {
    $confirm = Show-ConfirmationDialog -Title "Confirm VS Code Uninstall" -Message $message
} else {
    Write-Host "This will completely remove all VS Code installations and clean up configurations." -ForegroundColor Yellow
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
    VSCodeRemoval = $false
    UserDataCleanup = $false
    ConfigCleanup = $false
    PathCleanup = $false
}

if ($useNativeDialogs) {
    # GUI-based uninstall process
    Show-ProgressDialog -Title "VS Code Uninstall Progress" -Message "Starting uninstall process..."
    
    # Remove VS Code installations
    Update-ProgressDialog -Message "Removing VS Code installations..."
    
    foreach ($path in $vscodePaths) {
        try {
            Write-Host "• Removing VS Code installation: $path"
            
            # Try to use uninstaller first if available
            $uninstallerPath = "$path\unins000.exe"
            
            if (Test-Path $uninstallerPath) {
                Write-Host "  Using VS Code uninstaller: $uninstallerPath"
                $process = Start-Process -FilePath $uninstallerPath -ArgumentList "/SILENT" -Wait -PassThru
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
    $uninstallResults.VSCodeRemoval = $true
    
    # Clean up user data directory
    Update-ProgressDialog -Message "Cleaning up user data..."
    
    try {
        $userDataPath = "$env:APPDATA\Code"
        if (Test-Path $userDataPath) {
            Write-Host "• Removing VS Code user data: $userDataPath"
            Remove-Item -Path $userDataPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Successfully removed user data" -ForegroundColor Green
        } else {
            Write-Host "• No VS Code user data found to remove"
        }
        $uninstallResults.UserDataCleanup = $true
        
    } catch {
        Write-Host "  [ERROR] Failed to remove user data: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Clean up workspace settings
    Update-ProgressDialog -Message "Cleaning up workspace settings..."
    
    try {
        $workspaceSettingsPath = "$env:USERPROFILE\.vscode"
        if (Test-Path $workspaceSettingsPath) {
            Write-Host "• Removing VS Code workspace settings: $workspaceSettingsPath"
            Remove-Item -Path $workspaceSettingsPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Successfully removed workspace settings" -ForegroundColor Green
        } else {
            Write-Host "• No VS Code workspace settings found to remove"
        }
        $uninstallResults.ConfigCleanup = $true
        
    } catch {
        Write-Host "  [ERROR] Failed to remove workspace settings: $($_.Exception.Message)" -ForegroundColor Red
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
                $_ -notmatch 'Microsoft VS Code'
            }) -join ';'
            [Environment]::SetEnvironmentVariable("PATH", $cleanUserPath, "User")
            Write-Host "  [OK] User PATH cleaned" -ForegroundColor Green
        }
        
        # Note: We don't modify machine PATH as it may require admin privileges
        Write-Host "  Note: Machine PATH not modified (may require administrator privileges)"
        
        $uninstallResults.PathCleanup = $true
        
    } catch {
        Write-Host "  [ERROR] Failed to clean environment variables: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Clean up Start Menu shortcuts
    Update-ProgressDialog -Message "Cleaning up Start Menu shortcuts..."
    
    $startMenuPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Visual Studio Code*",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft VS Code*"
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

    # Clean up desktop shortcuts
    Update-ProgressDialog -Message "Cleaning up desktop shortcuts..."
    
    $desktopShortcuts = @(
        "$env:USERPROFILE\Desktop\Visual Studio Code.lnk",
        "$env:USERPROFILE\Desktop\Microsoft VS Code.lnk"
    )
    
    foreach ($shortcut in $desktopShortcuts) {
        if (Test-Path $shortcut) {
            try {
                Write-Host "• Removing desktop shortcut: $shortcut"
                Remove-Item -Path $shortcut -Force -ErrorAction Stop
                Write-Host "  [OK] Successfully removed desktop shortcut" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to remove desktop shortcut: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Update-ProgressDialog -Message "Uninstall completed!"
    Start-Sleep -Milliseconds 1000
    
    # Show final summary
    Show-InstallationSummary -Results $uninstallResults
    
} else {
    # Terminal-based uninstall process
    Write-Host "Starting VS Code uninstall process..." -ForegroundColor Green
    
    # Remove VS Code installations
    Write-Host "Removing VS Code installations..." -ForegroundColor Cyan
    
    foreach ($path in $vscodePaths) {
        try {
            Write-Host "• Removing VS Code installation: $path"
            
            # Try to use uninstaller first if available
            $uninstallerPath = "$path\unins000.exe"
            
            if (Test-Path $uninstallerPath) {
                Write-Host "  Using VS Code uninstaller: $uninstallerPath"
                $process = Start-Process -FilePath $uninstallerPath -ArgumentList "/SILENT" -Wait -PassThru
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
    $uninstallResults.VSCodeRemoval = $true
    
    # Clean up user data directory
    Write-Host "Cleaning up user data..." -ForegroundColor Cyan
    
    try {
        $userDataPath = "$env:APPDATA\Code"
        if (Test-Path $userDataPath) {
            Write-Host "• Removing VS Code user data: $userDataPath"
            Remove-Item -Path $userDataPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Successfully removed user data" -ForegroundColor Green
        } else {
            Write-Host "• No VS Code user data found to remove"
        }
        $uninstallResults.UserDataCleanup = $true
        
    } catch {
        Write-Host "  [ERROR] Failed to remove user data: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Clean up workspace settings
    Write-Host "Cleaning up workspace settings..." -ForegroundColor Cyan
    
    try {
        $workspaceSettingsPath = "$env:USERPROFILE\.vscode"
        if (Test-Path $workspaceSettingsPath) {
            Write-Host "• Removing VS Code workspace settings: $workspaceSettingsPath"
            Remove-Item -Path $workspaceSettingsPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Successfully removed workspace settings" -ForegroundColor Green
        } else {
            Write-Host "• No VS Code workspace settings found to remove"
        }
        $uninstallResults.ConfigCleanup = $true
        
    } catch {
        Write-Host "  [ERROR] Failed to remove workspace settings: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Clean up environment variables and PATH
    Write-Host "Cleaning up environment variables..." -ForegroundColor Cyan
    
    try {
        Write-Host "• Cleaning up PATH environment variable..."
        
        # Get current PATH variables
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        
        # Clean user PATH
        if ($userPath) {
            $cleanUserPath = ($userPath -split ';' | Where-Object { 
                $_ -notmatch 'Microsoft VS Code'
            }) -join ';'
            [Environment]::SetEnvironmentVariable("PATH", $cleanUserPath, "User")
            Write-Host "  [OK] User PATH cleaned" -ForegroundColor Green
        }
        
        # Note: We don't modify machine PATH as it may require admin privileges
        Write-Host "  Note: Machine PATH not modified (may require administrator privileges)"
        
        $uninstallResults.PathCleanup = $true
        
    } catch {
        Write-Host "  [ERROR] Failed to clean environment variables: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Clean up Start Menu shortcuts
    Write-Host "Cleaning up Start Menu shortcuts..." -ForegroundColor Cyan
    
    $startMenuPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Visual Studio Code*",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft VS Code*"
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

    # Clean up desktop shortcuts
    Write-Host "Cleaning up desktop shortcuts..." -ForegroundColor Cyan
    
    $desktopShortcuts = @(
        "$env:USERPROFILE\Desktop\Visual Studio Code.lnk",
        "$env:USERPROFILE\Desktop\Microsoft VS Code.lnk"
    )
    
    foreach ($shortcut in $desktopShortcuts) {
        if (Test-Path $shortcut) {
            try {
                Write-Host "• Removing desktop shortcut: $shortcut"
                Remove-Item -Path $shortcut -Force -ErrorAction Stop
                Write-Host "  [OK] Successfully removed desktop shortcut" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to remove desktop shortcut: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "[OK] VS Code uninstall completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor White
    Write-Host "• VS Code installations: $(if ($uninstallResults.VSCodeRemoval) { '[OK] Removed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.VSCodeRemoval) { 'Green' } else { 'Red' })
    Write-Host "• User data cleanup: $(if ($uninstallResults.UserDataCleanup) { '[OK] Completed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.UserDataCleanup) { 'Green' } else { 'Red' })
    Write-Host "• Configuration cleanup: $(if ($uninstallResults.ConfigCleanup) { '[OK] Completed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.ConfigCleanup) { 'Green' } else { 'Red' })
    Write-Host "• PATH cleanup: $(if ($uninstallResults.PathCleanup) { '[OK] Completed' } else { '[FAIL] Failed' })" -ForegroundColor $(if ($uninstallResults.PathCleanup) { 'Green' } else { 'Red' })
    Write-Host ""
    Write-Host "Important notes:" -ForegroundColor Yellow
    Write-Host "• You may need to restart your terminal or system for PATH changes to take effect"
    Write-Host "• Machine-level PATH was not modified (requires administrator privileges)"
    Write-Host ""
}

Write-Host "You can now reinstall VS Code if needed." -ForegroundColor Green
