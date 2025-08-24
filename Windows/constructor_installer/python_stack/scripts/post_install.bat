@echo off
REM Post-install script for DTU Python Stack - Windows
REM Handles Python environment configuration only

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
echo 3. Install VS Code separately if needed
echo 4. Refer to your course materials for usage guidance
echo.
echo Need help? Visit: https://pythonsupport.dtu.dk
echo.

exit /b 0