# Windows Installation Scripts

Python development environment setup for Windows systems.

## Quick Start

For first-year DTU students:

```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/main/Windows/install.ps1" -UseBasicParsing).Content
```

**Note**: Run in PowerShell as Administrator. If you have an existing conda installation, you'll be prompted to uninstall it manually first.

---

## Current Status

Windows support is fully functional with modular component system:

- ✅ Python (Miniforge) installation
- ✅ Visual Studio Code with Python extension
- ✅ Automated package installation (dtumathtools, pandas, scipy, statsmodels, uncertainties)
- ✅ One-liner installation approach
- ✅ Native Windows dialogs for user interaction

---

## System Requirements

- **Windows**: Windows 10 or later
- **Architecture**: x64 systems
- **Storage**: ~4GB free space for full installation
- **Network**: Internet connection for downloads
- **Permissions**: Administrator rights may be required

---

## Components

Windows uses a modular component system:

- **Python**: Miniforge installation with Python 3.12
- **VSCode**: Visual Studio Code with Python extension
- **Packages**: DTU-specific packages (dtumathtools, pandas, scipy, statsmodels, uncertainties)

---

## Features

- **One-liner installation**: No need to download .bat files
- **Existing conda detection**: Automatically detects and prompts for manual removal
- **Native Windows UI**: Uses Windows.Forms dialogs for user interaction
- **CI/CD testing**: Comprehensive GitHub Actions testing with matrix scenarios
- **Security conscious**: Avoids .bat files that trigger Windows security warnings

---

## Development Status

- ✅ **Complete**: Modular component system
- ✅ **Complete**: Windows-specific orchestrators
- ✅ **Complete**: GitHub Actions testing for Windows
- ✅ **Complete**: One-liner installation approach

---

## Contributing

Windows component development is welcome! Follow the patterns established in the macOS components.