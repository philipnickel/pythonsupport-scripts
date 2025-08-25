# Python Support Scripts

📚 **[View Complete Documentation](https://philipnickel.github.io/pythonsupport-scripts/)**

This repository contains automated installation scripts for Python development environments and associated tools for macOS and Windows.

## Quick Installation

### macOS
Open Terminal (⌘ + Space, search "Terminal") and run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/Miniforge/MacOS/install.sh)"
```

This installs:
- Python 3.11 with DTU mathematical tools
- Visual Studio Code with Python extension
- Complete diagnostic and verification system

### Windows
Open PowerShell as Administrator and run:
```powershell
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows_AutoInstall.ps1' -UseBasicParsing).Content}"
```

## Diagnostics

Check your Python environment with targeted diagnostic profiles:

### First Year Students (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash -s -- --profile first_year
```

### Advanced Users (Full Diagnostics)
```bash
curl -fsSL https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/MacOS/Components/Diagnostics/generate_report.sh | bash -s -- --profile comprehensive
```

## LaTeX Support (Experimental)

For converting Jupyter notebooks to PDF in VS Code:

### macOS
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Latex/Install.sh)"
```

### Windows
```powershell
PowerShell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/Windows/Latex/Install.ps1' -UseBasicParsing).Content}"
```

## Health Check

### Windows
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/HealthCheck/Windows/Health_Check.ps1' -UseBasicParsing).Content
```

### macOS
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/refs/heads/main/HealthCheck/MacOS/Health_Check.sh) -v"
```

## Support

- 🌐 **Website**: https://pythonsupport.dtu.dk
- 📧 **Email**: pythonsupport@dtu.dk
- 📚 **Documentation**: https://philipnickel.github.io/pythonsupport-scripts/
