@echo off
REM DTU Python Support - Advanced/Later Years Installation
REM This batch file installs Python 3.11 with extended packages
REM
REM Usage: Double-click to run or execute from command line
REM
REM Requirements: Windows 10/11, Internet connection, PowerShell 5.1+

echo.
echo ========================================
echo DTU Python Support - Advanced Setup
echo ========================================
echo.
echo This installer will set up:
echo   - Python 3.11 (Miniforge distribution)
echo   - Visual Studio Code
echo   - Advanced packages including:
echo     * All first year packages
echo     * matplotlib
echo     * seaborn
echo     * scikit-learn
echo     * jupyter
echo     * notebook
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

REM Download and execute the main installer with advanced configuration
echo.
echo Downloading and starting installation...
echo.

powershell -Command "& { ^
    $ErrorActionPreference = 'Stop'; ^
    try { ^
        $installerUrl = 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/install.ps1'; ^
        Write-Host 'Downloading installer from: ' -NoNewline; ^
        Write-Host $installerUrl -ForegroundColor Cyan; ^
        $tempScript = Join-Path $env:TEMP 'dtu_install_advanced.ps1'; ^
        Invoke-WebRequest -Uri $installerUrl -OutFile $tempScript -UseBasicParsing; ^
        Write-Host 'Starting installation with advanced configuration...' -ForegroundColor Green; ^
        Write-Host ''; ^
        & $tempScript -RemoteRepo 'dtudk/pythonsupport-scripts' -Branch 'main' -PythonVersion '3.11' -UseGUI:$false -Force; ^
        Write-Host ''; ^
        Write-Host 'Installing additional advanced packages...' -ForegroundColor Yellow; ^
        conda activate first_year; ^
        conda install -y matplotlib seaborn scikit-learn jupyter notebook ipykernel; ^
        Write-Host 'Advanced packages installed successfully!' -ForegroundColor Green; ^
    } catch { ^
        Write-Host 'Installation failed: ' -ForegroundColor Red -NoNewline; ^
        Write-Host $_.Exception.Message -ForegroundColor Red; ^
        Write-Host ''; ^
        Write-Host 'For help, visit: https://pythonsupport.dtu.dk' -ForegroundColor Yellow; ^
        exit 1; ^
    } ^
}"

if %errorlevel% neq 0 (
    echo.
    echo Installation failed. Check the error messages above.
    echo For help, visit: https://pythonsupport.dtu.dk
    echo.
    pause
    exit /b %errorlevel%
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
echo 4. To use Jupyter: jupyter notebook
echo.
echo For help and documentation:
echo https://pythonsupport.dtu.dk
echo.
pause