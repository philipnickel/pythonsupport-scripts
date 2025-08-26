@echo off
REM DTU Python Support - Windows GUI Installer Wrapper
REM Version: 1.0.0
REM 
REM This is a wrapper script that downloads and executes the main installer.
REM Users can download this file and double-click to run the installation.
REM 
REM Usage:
REM   Double-click this file to run the installer
REM   Or run: dtu-python-installer-windows-gui.bat

echo DTU Python Support - Windows GUI Installer
echo ===========================================
echo Downloading and starting the installation process...
echo.

REM Download and execute the main installer
powershell -Command "Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/install.ps1' -UseBasicParsing).Content"

REM The script will exit with the same code as the main installer
exit /b %ERRORLEVEL%
