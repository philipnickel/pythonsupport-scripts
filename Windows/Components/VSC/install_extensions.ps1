# @doc
# @name: VSCode Extensions Installation
# @description: Installs essential VSCode extensions for Python development
# @category: IDE
# @usage: . .\install_extensions.ps1
# @requirements: VSCode must be installed and 'code' command available
# @notes: Installs Python development extensions and other useful tools
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

Write-LogInfo "Installing VSCode extensions for Python development"

# Check if VSCode CLI is available
Write-LogInfo "Checking VSCode CLI availability..."
try {
    $codeVersion = & code --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "VSCode CLI is available: $($codeVersion[0])"
    }
    else {
        Write-LogError "VSCode CLI is not available. Please ensure VSCode is installed and 'code' command is in PATH"
        Exit-Message
    }
}
catch {
    Write-LogError "VSCode CLI is not available: $($_.Exception.Message)"
    Exit-Message
}

# Define extensions to install
$extensions = @(
    # Python development
    "ms-python.python",
    "ms-python.pylint",
    "ms-python.black-formatter",
    "ms-python.isort",
    "ms-python.flake8",
    "ms-python.mypy-type-checker",
    
    # Jupyter support
    "ms-toolsai.jupyter",
    "ms-toolsai.jupyter-keymap",
    "ms-toolsai.jupyter-renderers",
    
    # Git integration
    "eamodio.gitlens",
    
    # File management
    "ms-vscode.vscode-json",
    "yzhang.markdown-all-in-one",
    
    # Themes and icons
    "PKief.material-icon-theme",
    "zhuangtongfa.Material-theme",
    
    # Productivity
    "formulahendry.auto-rename-tag",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    
    # Python specific
    "kevinrose.vscode-python-indent",
    "ms-python.vscode-pylance"
)

Write-LogInfo "Installing $($extensions.Count) VSCode extensions..."

$successCount = 0
$failedCount = 0

foreach ($extension in $extensions) {
    Write-LogInfo "Installing extension: $extension"
    try {
        & code --install-extension $extension
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "Extension $extension installed successfully"
            $successCount++
        }
        else {
            Write-LogWarning "Failed to install extension $extension"
            $failedCount++
        }
    }
    catch {
        Write-LogWarning "Failed to install extension $extension : $($_.Exception.Message)"
        $failedCount++
    }
}

# Summary
Write-LogInfo "Extension installation summary:"
Write-LogInfo "  Successfully installed: $successCount"
if ($failedCount -gt 0) {
    Write-LogWarning "  Failed to install: $failedCount"
}

# Configure VSCode settings for Python development
Write-LogInfo "Configuring VSCode settings for Python development..."

$vscodeSettingsPath = "$env:APPDATA\Code\User\settings.json"

try {
    # Create settings directory if it doesn't exist
    $settingsDir = Split-Path $vscodeSettingsPath -Parent
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }
    
    # Default Python settings
    $pythonSettings = @{
        "python.defaultInterpreterPath" = "python"
        "python.linting.enabled" = $true
        "python.linting.pylintEnabled" = $true
        "python.formatting.provider" = "black"
        "python.sortImports.args" = @("--profile", "black")
        "editor.formatOnSave" = $true
        "editor.codeActionsOnSave" = @{
            "source.organizeImports" = $true
        }
        "python.terminal.activateEnvironment" = $true
        "jupyter.askForKernelRestart" = $false
        "files.autoSave" = "onFocusChange"
    }
    
    # Load existing settings if they exist
    if (Test-Path $vscodeSettingsPath) {
        $existingSettings = Get-Content $vscodeSettingsPath | ConvertFrom-Json
        $existingSettings.PSObject.Properties | ForEach-Object {
            $pythonSettings[$_.Name] = $_.Value
        }
    }
    
    # Save settings
    $pythonSettings | ConvertTo-Json -Depth 10 | Set-Content $vscodeSettingsPath
    Write-LogSuccess "VSCode settings configured successfully"
}
catch {
    Write-LogWarning "Failed to configure VSCode settings: $($_.Exception.Message)"
}

Write-LogSuccess "VSCode extensions installation completed!"
Write-LogInfo "You can now use VSCode with enhanced Python development features"
