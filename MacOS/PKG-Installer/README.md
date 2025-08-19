# DTU Python Support - PKG Installer

**Simple PKG installer with 4-step guided flow for DTU Python environment setup.**

## 🎯 4-Step Installation Flow

This installer guides students through a structured process:

1. **📋 Introduction** - Explains what will be done in the following steps
2. **🔍 System Check** - Analyzes current Homebrew, Python, and VSCode installation status
3. **⚙️ Installation** - Installs via MacOS/Components/orchestrators/first_year_students.sh if all components are missing 
note: Runs the oneliner /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/orchestrators/first_year_students.sh)"
4. **✅ Verification** - Runs diagnostics to confirm everything works

## 🧠 Smart Detection

The installer checks for:
- **Homebrew** - Package manager
- **Python/Miniconda** - Python environment (prefers Miniconda over system Python)  
- **Packages** - Same as first_year_students.sh
- **Visual Studio Code** - Development environment including extensions

If something is already installed, it skips installation and goes straight to verification.

## 🚀 Quick Start

**To build the PKG installer:**
```bash
./build-pkg.sh
```

This creates: `build/DTUPythonSupport-1.0.0.pkg`

### 📦 Installer Features

- **Background Installation** - No Terminal windows, runs silently during PKG installation
- **Professional UI** - Welcome screen, progress indicators, and completion screen
- **Smart Detection** - Only installs missing components
- **Complete Logging** - Detailed logs at `/tmp/dtu-python-support-install.log`
- **User Context** - Runs installation as the actual user (not root)

### 🎯 User Experience

**Installation Flow:**
```
Double-click PKG → Welcome Screen → Installation Progress → Completion Screen
                     ↓
              (Background: system check, component installation, verification)
```

**What Happens Behind the Scenes:**
1. **Pre-install** - System compatibility checks
2. **Smart Detection** - Check for existing Homebrew, Python, VSCode
3. **Component Installation** - Install missing components only
4. **Verification** - Run diagnostics to ensure everything works
5. **Completion** - Show success screen with next steps

### 🛠️ Technical Details

- **Installation Script**: Runs the official DTU `first_year_students.sh` orchestrator
- **User Privileges**: PKG installer handles root privileges, then switches to user context
- **Error Handling**: Comprehensive error checking and logging
- **Progress Tracking**: Real-time progress updates in log files
