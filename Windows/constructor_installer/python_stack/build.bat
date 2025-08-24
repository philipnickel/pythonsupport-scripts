@echo off
REM Build script for DTU Python Stack Windows Installer

echo === DTU Python Stack Windows Constructor Build ===

REM Get script directory
set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%builds

REM Check if constructor is available
where constructor >nul 2>&1
if errorlevel 1 (
    echo Installing Constructor...
    mamba install -c conda-forge constructor -y
    if errorlevel 1 (
        echo ERROR: Failed to install constructor
        exit /b 1
    )
)

echo Constructor: 
constructor --version

echo Building installer...

REM Create builds directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Clean previous builds
del /Q "%BUILD_DIR%\*.exe" 2>nul

REM Change to script directory and build
cd /d "%SCRIPT_DIR%"
constructor . --output-dir="%BUILD_DIR%"

if errorlevel 1 (
    echo ERROR: Constructor build failed
    exit /b 1
)

echo.
echo Build completed successfully!

REM Show the built installer
for %%f in ("%BUILD_DIR%\*.exe") do (
    echo Generated: %%~nxf
    echo Size: 
    dir "%%f" | find "%%~nxf"
)

exit /b 0