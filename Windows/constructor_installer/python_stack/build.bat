@echo off
REM Build script for DTU Python Stack Windows Installer

echo === DTU Python Stack Windows Constructor Build ===

REM Get script directory and create builds directory
set BUILD_DIR=builds
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Clean previous builds
del /Q "%BUILD_DIR%\*.exe" >nul 2>&1

echo Building installer...
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
)

exit /b 0