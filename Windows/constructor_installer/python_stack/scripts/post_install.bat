@echo off
REM Post-install script for DTU Python Stack - Windows
REM Handles Python environment configuration + VS Code installation

echo [INFO] Starting DTU Python Stack post-install...

REM =============================================================================
REM Python Environment Setup
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
REM VS Code Installation
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
    powershell -Command "Invoke-WebRequest -Uri '%VSCODE_URL%' -OutFile '%VSCODE_INSTALLER%' -UseBasicParsing -TimeoutSec 60" >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Could not download VS Code ^(network timeout^)
    ) else (
        echo [INFO] Installing VS Code...
        "%VSCODE_INSTALLER%" /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath >nul 2>&1
        if errorlevel 1 (
            echo [WARNING] Could not install VS Code
        ) else (
            echo [SUCCESS] VS Code installed successfully
            
            REM Brief wait for VS Code to be available
            timeout /t 2 >nul 2>&1
            
            REM Install essential extensions
            if exist "%VSCODE_PATH%" (
                echo [INFO] Installing Python extension...
                "%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd" --install-extension ms-python.python --force >nul 2>&1 || echo [WARNING] Could not install Python extension
            )
        )
        del "%VSCODE_INSTALLER%" >nul 2>&1
    )
)

REM =============================================================================
REM Installation Complete
REM =============================================================================

echo [SUCCESS] DTU Python Stack installation completed!
echo.
echo === Installation Summary ===
echo ✓ Python 3.11 with scientific packages ^(pandas, scipy, statsmodels, uncertainties, dtumathtools^)
echo ✓ Conda environment activated and shell integration configured
echo ✓ Visual Studio Code installation attempted
echo.
echo === Next Steps ===
echo 1. Restart your Command Prompt or PowerShell
echo 2. Test Python: python -c "import pandas, dtumathtools; print('Success!')"
echo 3. Open VS Code: code --version
echo 4. Refer to your course materials for usage guidance
echo.
echo Need help? Visit: https://pythonsupport.dtu.dk
echo.

exit /b 0