@echo off
REM DTU Python Support - First Year Students Installation
REM This batch file installs Python 3.12 with first year packages
REM
REM Usage: Double-click to run or execute from command line
REM
REM Requirements: Windows 10/11, Internet connection, PowerShell 5.1+

echo.
echo ========================================
echo DTU Python Support - First Year Setup
echo ========================================
echo.
echo This installer will set up:
echo   - Python 3.12 (Miniforge distribution)
echo   - Visual Studio Code
echo   - First year packages:
echo     * dtumathtools
echo     * pandas
echo     * scipy
echo     * statsmodels
echo     * uncertainties
echo   - Essential VS Code extensions
echo.

REM Check if PowerShell is available
powershell -Command "exit 0" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell 5.1 or later and try again.
    pause
    exit /b 1
)

REM Set PowerShell execution policy for current user
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" >nul 2>&1

REM Download and execute the main installer with first year configuration
echo.
echo Downloading and starting installation...
echo.

REM Create temporary PowerShell script for installation
set TEMP_PS_SCRIPT=%TEMP%\dtu_install_wrapper.ps1

echo $ErrorActionPreference = "Stop" > "%TEMP_PS_SCRIPT%"
echo try { >> "%TEMP_PS_SCRIPT%"
echo     $installerUrl = "https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/install.ps1" >> "%TEMP_PS_SCRIPT%"
echo     Write-Host "Downloading installer from: $installerUrl" -ForegroundColor Cyan >> "%TEMP_PS_SCRIPT%"
echo     $tempScript = Join-Path $env:TEMP "dtu_install_first_year.ps1" >> "%TEMP_PS_SCRIPT%"
echo     Invoke-WebRequest -Uri $installerUrl -OutFile $tempScript -UseBasicParsing >> "%TEMP_PS_SCRIPT%"
echo     Write-Host "Starting installation with first year configuration..." -ForegroundColor Green >> "%TEMP_PS_SCRIPT%"
echo     Write-Host "" >> "%TEMP_PS_SCRIPT%"
echo     ^& $tempScript -RemoteRepo "dtudk/pythonsupport-scripts" -Branch "main" -PythonVersion "3.12" -UseGUI:$false -Force >> "%TEMP_PS_SCRIPT%"
echo } catch { >> "%TEMP_PS_SCRIPT%"
echo     Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red >> "%TEMP_PS_SCRIPT%"
echo     Write-Host "" >> "%TEMP_PS_SCRIPT%"
echo     Write-Host "For help, visit: https://pythonsupport.dtu.dk" -ForegroundColor Yellow >> "%TEMP_PS_SCRIPT%"
echo     exit 1 >> "%TEMP_PS_SCRIPT%"
echo } >> "%TEMP_PS_SCRIPT%"

REM Execute the PowerShell script
powershell -ExecutionPolicy RemoteSigned -File "%TEMP_PS_SCRIPT%"
set INSTALL_EXIT_CODE=%errorlevel%

REM Clean up temporary script
del "%TEMP_PS_SCRIPT%" >nul 2>&1

if %INSTALL_EXIT_CODE% neq 0 (
    echo.
    echo Installation failed. Check the error messages above.
    echo For help, visit: https://pythonsupport.dtu.dk
    echo.
    pause
    exit /b %INSTALL_EXIT_CODE%
)

echo.
echo ========================================
echo Installation completed successfully!
echo ========================================
echo.
echo Next steps:
echo 1. Restart your PowerShell/Command Prompt
echo 2. Run: conda activate first_year
echo 3. Open VS Code and start coding!
echo.
echo For help and documentation:
echo https://pythonsupport.dtu.dk
echo.
pause