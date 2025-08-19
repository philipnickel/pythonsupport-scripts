# DTU Python Support - GUI Applications

This directory contains the graphical user interface applications for DTU Python Support tools.

## 🏗️ Architecture

### Current Production App: `DTUPythonSupportFull.app`
A comprehensive modular macOS application built with AppleScript providing:

- **Modular Architecture**: 6 independent component scripts
- **Multiple Installation Types**: First Year, Advanced, Custom
- **Diagnostic Integration**: Uses existing `/MacOS/Components/Diagnostics/` scripts
- **Post-Installation Verification**: Automatic diagnostics after installation
- **Environment Repair Tools**: Fix common configuration issues
- **Comprehensive Reporting**: System analysis and export capabilities

### Components

#### Core Application
- `DTUPythonSupportFull.applescript` - Main application entry point
- `build_full_app.sh` - Build script for the full application

#### Modular Scripts (`/Scripts/`)
- `gui_controller.applescript` - Central UI flow controller
- `diagnostics_manager.applescript` - Diagnostic operations manager
- `installation_manager.applescript` - Installation workflow manager  
- `report_manager.applescript` - System reporting and export
- `repair_manager.applescript` - Environment troubleshooting
- `settings_manager.applescript` - User preferences and configuration

#### Archive (`/Archive/`)
- Previous simple GUI implementations for reference

## 🚀 Building the Application

```bash
# Build the full modular application
./build_full_app.sh

# This creates DTUPythonSupportFull.app with:
# - All 6 modular AppleScript components
# - Bundled diagnostic shell scripts from /MacOS/Components/Diagnostics/
# - Proper application metadata and permissions
```

## 🎯 Features

### Quick Start Menu
- **Check System**: Fast diagnostic overview
- **Install Python**: First-year student setup
- **Fix Issues**: Automatic environment repair

### Full Menu System
- **Diagnostics**: Quick/Full/Component-based checks
- **Installation**: Multiple installation workflows with verification
- **Advanced**: System reports, environment repair, settings

### Integration
- **Direct integration** with `/MacOS/Components/Diagnostics/Components/*.sh`
- **Post-installation verification** runs diagnostics after each installation
- **Component-based architecture** allows for easy maintenance and updates

## 📱 User Experience Flow

```
Welcome Screen → Quick Start or Full Menu
    │
    ├─ Quick Start → Check/Install/Repair → Results
    │
    └─ Full Menu → Diagnostics/Installation/Advanced
                      │
                      └─ Installation → Post-Installation Verification
```

## 🔧 Development Notes

### Adding New Components
1. Create new AppleScript in `/Scripts/`
2. Add to `build_full_app.sh` components array
3. Load in appropriate manager script
4. Rebuild with `./build_full_app.sh`

### Installation Integration
The installation workflows are currently placeholder implementations. To complete:
1. Replace placeholder functions in `installation_manager.applescript`
2. Connect to actual installation scripts
3. Test post-installation verification flow

### Diagnostic Integration
The diagnostic components already integrate with existing shell scripts in `/MacOS/Components/Diagnostics/Components/`. This provides:
- Consistent diagnostic results across CLI and GUI
- Reuse of existing robust diagnostic logic
- Easy maintenance of diagnostic components

## 📋 Application Details

- **Name**: DTU Python Support - Full Edition
- **Bundle ID**: dk.dtu.pythonsupport.full
- **Version**: 2.0.0
- **Components**: 6 AppleScript modules + 7 shell diagnostic scripts
- **Size**: ~516KB
- **Architecture**: Modular, scalable design