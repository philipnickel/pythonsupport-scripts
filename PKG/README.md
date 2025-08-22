# DTU Python Environment PKG Installer

This directory contains the macOS PKG installer for the DTU Python Environment.

## Architecture

**Download-and-Execute Approach**: The PKG contains minimal scripts that download and execute the same orchestrator used by the web-based installation.

### PKG Structure
```
DTU_Python_Environment.pkg
├── Scripts/
│   ├── preinstall   # Controller check, user dialogs
│   └── postinstall  # Download and execute orchestrator
├── Resources/
│   ├── welcome.txt  # Installation welcome message
│   └── background.png (optional)
└── Payload/ (empty) # No files installed, scripts only
```

### Key Features
- ✅ **Controller Integration**: Respects `macos_pkg=disabled` setting
- ✅ **Same Components**: Uses identical orchestrator as web installation  
- ✅ **Analytics Tracking**: Sets `PIS_INSTALL_METHOD="PKG"`
- ✅ **User Experience**: Native macOS installer with progress and dialogs
- ✅ **Error Handling**: Clear error messages and system logging

## Building the PKG

### Prerequisites
- macOS with Xcode command line tools
- Developer ID certificate (for distribution)

### Build Process
```bash
# Build PKG locally
cd PKG/
./build_pkg.sh

# Test locally  
sudo installer -pkg DTU_Python_Environment.pkg -target /

# Upload to GitHub releases
gh release create v1.0.0 DTU_Python_Environment.pkg
```

### Testing in CI
The PKG test job downloads the PKG from GitHub releases and runs the same verification tests as the orchestrator and legacy installations.

## Environment Variables
- `PIS_INSTALL_METHOD="PKG"` - For analytics differentiation
- `PYTHON_VERSION_PS="3.11"` - Target Python version
- `REMOTE_PS/BRANCH_PS` - Repository and branch for component downloads

## Distribution
1. Build PKG locally using `build_pkg.sh`
2. Upload to GitHub releases
3. CI automatically tests the latest release
4. Users download from GitHub releases page

## Troubleshooting
- **Installation logs**: Check Console.app for "DTU-Python-PKG" entries
- **Manual verification**: Run same tests as CI after PKG installation
- **Controller status**: Check main_controller.txt for disabled components