@echo off
setlocal

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install Windows.ps1" %*
set "INSTALL_EXIT_CODE=%ERRORLEVEL%"
echo.
if not "%INSTALL_EXIT_CODE%"=="0" pause
exit /b %INSTALL_EXIT_CODE%
