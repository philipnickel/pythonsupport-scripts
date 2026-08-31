@echo off
setlocal
title DTU Python Support

set "BUNDLE_ROOT=%~dp0.dtu-python-support"
set "LAUNCHER=%BUNDLE_ROOT%\pis-launcher-windows-amd64.exe"

if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "LAUNCHER=%BUNDLE_ROOT%\pis-launcher-windows-arm64.exe"
if /I "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "LAUNCHER=%BUNDLE_ROOT%\pis-launcher-windows-arm64.exe"

if not exist "%LAUNCHER%" (
    echo DTU Python Support is incomplete: missing launcher.
    echo Please download or rebuild the complete disk image.
    pause
    exit /b 1
)

set PS_OFFLINE=
set PS_REPO_URL=
set PS_REPO_USER=
set PS_BRANCH=
set PS_FORGE_URL=
set PS_VSCODE_URL=
set PS_ENV_INITIALIZED=
set PS_ENV=offline
set "PS_BUNDLE_ROOT=%BUNDLE_ROOT%"

"%LAUNCHER%" --bundle-root "%BUNDLE_ROOT%" %*
set "LAUNCHER_EXIT_CODE=%ERRORLEVEL%"
if not "%LAUNCHER_EXIT_CODE%"=="0" pause
exit /b %LAUNCHER_EXIT_CODE%
