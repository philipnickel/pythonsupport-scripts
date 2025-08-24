@echo off
REM Post-install script for DTU Python Stack - Windows
REM Handles Python environment + VS Code + Extensions + Diagnostics

echo [INFO] Starting DTU Python Development Environment post-install...

REM =============================================================================
REM Phase 1: Python Environment Setup
REM =============================================================================

echo [INFO] Configuring Python environment...

REM Basic conda configuration
conda config --set anaconda_anon_usage off >nul 2>&1 || echo [WARNING] Could not set anaconda_anon_usage
conda config --set auto_activate_base true >nul 2>&1 || echo [WARNING] Could not set auto_activate_base

REM Remove default channels to avoid commercial channel warnings
conda config --remove channels defaults >nul 2>&1 || echo [WARNING] Could not remove defaults channel
conda config --add channels conda-forge >nul 2>&1 || echo [WARNING] Could not add conda-forge channel

REM Shell integration - Windows Command Prompt and PowerShell
conda init cmd.exe >nul 2>&1 || echo [WARNING] Could not init cmd.exe
conda init powershell >nul 2>&1 || echo [WARNING] Could not init powershell

echo [SUCCESS] Python environment configured

REM =============================================================================
REM Phase 2: VS Code Installation
REM =============================================================================

echo [INFO] Installing Visual Studio Code...

set VSCODE_URL=https://code.visualstudio.com/sha/download?build=stable^&os=win32-x64-user
set VSCODE_INSTALLER=%TEMP%\vscode_installer.exe
set VSCODE_PATH=%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe

REM Check if already installed
if exist "%VSCODE_PATH%" (
    echo [INFO] VS Code already installed
) else (
    echo [INFO] Downloading VS Code...
    powershell -Command "try { Invoke-WebRequest -Uri '%VSCODE_URL%' -OutFile '%VSCODE_INSTALLER%' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Could not download VS Code ^(continuing anyway^)
    ) else (
        echo [INFO] Installing VS Code...
        "%VSCODE_INSTALLER%" /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath >nul 2>&1
        if errorlevel 1 (
            echo [WARNING] Could not install VS Code ^(continuing anyway^)
        ) else (
            echo [SUCCESS] VS Code installed successfully
        )
        del "%VSCODE_INSTALLER%" >nul 2>&1
    )
)

REM =============================================================================
REM Phase 3: VS Code Extensions Installation
REM =============================================================================

echo [INFO] Installing VS Code extensions...

REM Wait a moment for VS Code to be fully installed and available in PATH
timeout /t 3 >nul 2>&1

REM Check if code command is available
where code >nul 2>&1
if errorlevel 1 (
    REM Try to add VS Code to PATH manually for this session
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Microsoft VS Code\bin"
)

REM Install essential Python extensions
where code >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Installing extension: ms-python.python
    code --install-extension ms-python.python --force >nul 2>&1 || echo [WARNING] Could not install ms-python.python
    
    echo [INFO] Installing extension: ms-toolsai.jupyter
    code --install-extension ms-toolsai.jupyter --force >nul 2>&1 || echo [WARNING] Could not install ms-toolsai.jupyter
    
    echo [SUCCESS] VS Code extensions installed
) else (
    echo [WARNING] VS Code not available for extensions installation
)

REM =============================================================================
REM Installation Complete
REM =============================================================================

echo [SUCCESS] DTU Python Stack installation completed!
echo.
echo === Installation Summary ===
echo ✓ Python 3.11 with scientific packages ^(pandas, scipy, statsmodels, uncertainties, dtumathtools^)
echo ✓ Conda environment activated and shell integration configured
echo.
echo === Next Steps ===
echo 1. Restart your Command Prompt or PowerShell
echo 2. Test Python: python -c "import pandas, dtumathtools; print('Success!')"
echo 3. Test VS Code: code --version
echo 4. Refer to your course materials for usage guidance
echo.
echo Need help? Visit: https://pythonsupport.dtu.dk
echo.

exit /b 0