# Offline Component Scripts - Changes Documentation

This document details the changes made to create offline versions of the Python Support component scripts for use in the package installer.

## Overview

The offline versions of the component scripts have been modified to work without network dependencies while maintaining the same core functionality. All remote utility loading and script fetching has been replaced with local file sourcing.

## Files Created

### Configuration
- `config/pkg_config.sh` - Central configuration file with environment variables

### Shared Utilities (Offline Versions)
- `components/Shared/master_utils.sh` - Offline master utility loader
- `components/Shared/utils.sh` - Offline shared utilities

### Component Scripts (Offline Versions)
- `components/Python/install.sh` - Offline Python/Miniconda installer
- `components/Python/first_year_setup.sh` - Offline first year Python setup
- `components/VSC/install.sh` - Offline VSCode installer

## Key Changes Made

### 1. Removed Network Dependencies

**Original Pattern:**
```bash
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"
```

**Offline Pattern:**
```bash
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
if [ -f "$SCRIPT_DIR/../Shared/master_utils.sh" ]; then
    source "$SCRIPT_DIR/../Shared/master_utils.sh"
else
    echo "ERROR: Cannot find master_utils.sh. Please ensure the script structure is intact."
    exit 1
fi
```

### 2. Local Configuration Loading

**Added to all scripts:**
- Local configuration loading from `config/pkg_config.sh`
- Fallback defaults when configuration is not available
- Environment variable detection for offline mode

### 3. Modified Remote Script Sourcing

**Original master_utils.sh:**
```bash
load_utility() {
    local util_name="$1"
    local util_script
    if util_script=$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS}/${BRANCH_PS}/MacOS/Components/Shared/${util_name}.sh" 2>/dev/null) && [ -n "$util_script" ]; then
        eval "$util_script"
        echo "$_prefix ✓ Loaded $util_name utilities"
    else
        echo "$_prefix ✗ Failed to load $util_name utilities"
    fi
}
```

**Offline master_utils.sh:**
```bash
load_local_utility() {
    local util_name="$1"
    local util_path="$SCRIPT_DIR/${util_name}.sh"
    
    if [ -f "$util_path" ]; then
        source "$util_path"
        echo "$_prefix ✓ Loaded $util_name utilities (local)"
        return 0
    else
        echo "$_prefix ✗ Failed to load $util_name utilities (file not found: $util_path)"
        return 1
    fi
}
```

### 4. Inline Utility Functions

Created essential utility functions inline within master_utils.sh to ensure core functionality is always available:
- `log_info()`, `log_error()`, `log_success()`
- `check_exit_code()`
- `exit_message()`
- `set_default_env()`
- `ensure_homebrew()`

### 5. Local Script References

**Original first_year_setup.sh:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Python/install.sh)"
```

**Offline first_year_setup.sh:**
```bash
if [ -f "$SCRIPT_DIR/install.sh" ]; then
    bash "$SCRIPT_DIR/install.sh"
    check_exit_code "Failed to install Python via local installer"
else
    log_error "Local Python installer not found at $SCRIPT_DIR/install.sh"
    exit_message
fi
```

## Configuration Variables

The `pkg_config.sh` file provides the following environment variables:

```bash
# Python version configuration
export PYTHON_VERSION_PS="3.11"

# Environment settings
export PIS_ENV="PKG"
export GITHUB_CI="false"

# Repository settings
export REMOTE_PS="dtudk/pythonsupport-scripts"
export BRANCH_PS="main"

# Package installer specific settings
export PKG_INSTALLER_MODE="true"
export OFFLINE_MODE="true"

# Logging prefix
export _prefix="PYS-PKG:"

# Homebrew and Conda paths
export HOMEBREW_PREFIX_INTEL="/usr/local"
export HOMEBREW_PREFIX_APPLE="/opt/homebrew"
export CONDA_PATH_INTEL="/usr/local/Caskroom/miniconda/base/bin"
export CONDA_PATH_APPLE="/opt/homebrew/Caskroom/miniconda/base/bin"

# Default settings
export CONDA_DEFAULT_ENV="base"
export PKG_VERSION="1.0"
export DISABLE_ANALYTICS="true"
export ANACONDA_ANON_USAGE="false"
export EXIT_ON_ERROR="true"
```

## Functionality Preserved

### Python Installation (install.sh)
- ✅ Homebrew installation and verification
- ✅ Miniconda installation via Homebrew cask
- ✅ Conda initialization for bash and zsh
- ✅ Conda configuration (channel management, analytics disable)
- ✅ Error handling and logging

### Python First Year Setup (first_year_setup.sh)
- ✅ Conda environment detection and setup
- ✅ Python version management
- ✅ Package installation (dtumathtools, pandas, scipy, statsmodels, uncertainties)
- ✅ Local Python installer fallback
- ✅ PATH configuration for conda

### VSCode Installation (install.sh)
- ✅ Homebrew dependency management
- ✅ VSCode installation detection
- ✅ Installation via Homebrew cask
- ✅ Environment setup and verification
- ✅ Command-line tool availability testing

### Shared Utilities
- ✅ Consistent logging functions
- ✅ Error handling and exit mechanisms
- ✅ Environment variable management
- ✅ Homebrew installation automation
- ✅ Conda environment configuration

## Functionality Removed/Modified

### Removed Network Dependencies
- ❌ Remote script fetching via `curl`
- ❌ Dynamic utility loading from GitHub
- ❌ Remote error handling module loading
- ❌ Piwik analytics integration
- ❌ Remote environment detection

### Modified for Offline Operation
- 🔄 Local file sourcing instead of remote URLs
- 🔄 Embedded essential utilities in master_utils.sh
- 🔄 Local configuration loading with fallbacks
- 🔄 Enhanced error messages for missing local files
- 🔄 Modified logging prefix to indicate package mode

## Usage in Package Installer

These offline scripts are designed to be included in the macOS package installer and work entirely from local files. They maintain the same installation behavior as the original scripts but operate without requiring internet connectivity for utility loading.

The scripts can still download software (Homebrew, Miniconda, VSCode) via their respective installation methods, but the Python Support utility framework operates entirely offline.

## Testing Considerations

When testing these offline scripts:

1. Ensure all local file paths are correct relative to the script locations
2. Verify that the configuration file is properly loaded
3. Test fallback behavior when configuration is missing
4. Confirm that error handling works without remote dependencies
5. Validate that all core functionality remains intact

## Migration Notes

To use these offline scripts in a package installer:

1. Include all files in the package with the correct directory structure
2. Ensure the relative paths between scripts are maintained
3. The configuration file should be customized for the specific deployment environment
4. Scripts should be made executable in the package installation process