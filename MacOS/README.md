# DTU Python Support Scripts - macOS

This directory contains the complete macOS installation and support system for DTU (Technical University of Denmark) Python environments. The system provides automated installation, verification, and diagnostics for first-year students and other DTU programs.

## Simplified Architecture

The system follows a streamlined three-phase approach with integrated pre/post verification:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Pre-Check     │ → │   Installation   │ → │ Post-Verify     │
│                 │    │                 │    │                 │
│ • System Check  │    │ • Python 3.11   │    │ • Verification  │
│ • Detect Issues │    │ • VS Code Setup │    │ • Analytics     │
│ • Requirements  │    │ • DTU Packages  │    │ • Diagnostics   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Simplified Directory Structure

```
MacOS/
├── README.md                    # This file
├── install.sh                  # ⭐ SINGLE ENTRY POINT (contains full workflow)
└── Components/
    ├── Core/                   # Core installation logic
    │   ├── pre_install.sh      # Pre-installation system check
    │   └── post_install.sh     # Post-installation verification
    ├── Diagnostics/            # System diagnostics and reporting  
    │   ├── first_year_test.sh  # First-year setup validation
    │   └── simple_report.sh    # HTML diagnostic report generator
    ├── Python/                 # Python installation components
    │   ├── install.sh          # Python installation script
    │   └── first_year_setup.sh # First-year specific Python setup
    ├── VSC/                    # Visual Studio Code components
    │   └── install.sh          # VS Code installation script
    ├── Shared/                 # Shared utilities
    │   ├── simple_utils.sh     # Basic utilities and logging
    │   └── piwik_utility.sh    # Analytics and tracking
```

## 🚀 Super Simple Quick Start

### For End Users (Simplest)

**Local installation:**
```bash
./MacOS/install.sh
```

**One-line remote installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/install.sh)"
```
## Core Components

### `install.sh`
**Main Entry Point** - Simple installation with user confirmation
- Interactive installation prompt
- Calls the complete orchestrator workflow
- User-friendly with clear instructions

### `Components/Core/pre_install.sh`
**System Assessment** - Checks system before installation
- macOS version and requirements validation  
- Detects existing Python/VS Code/Conda installations
- Identifies conflicts and warns about issues
- Exports findings for comparison by post_install

### `Components/Core/post_install.sh`  
**Installation Verification** - Validates installation success
- Verifies Python 3.11 and required packages
- Confirms VS Code and Python extension
- Compares with pre-installation state
- Sends analytics and generates diagnostics
- Provides clear success/failure messaging

## Component Details

### Diagnostics
- **`first_year_test.sh`**: Validates Python 3.11, VS Code, DTU packages, and extensions
- **`simple_report.sh`**: Generates HTML reports with expandable sections and system info

### Python Installation  
- **`install.sh`**: Installs Python 3.11 via Miniforge with system-wide access
- **`first_year_setup.sh`**: Installs DTU packages (dtumathtools, pandas, scipy, etc.)

### VS Code Setup
- **`install.sh`**: Downloads VS Code, adds to PATH, installs Python extension

### Shared Utilities
- **`simple_utils.sh`**: Logging, error handling, analytics integration
- **`piwik_utility.sh`**: GDPR-compliant analytics with user consent and environment detection

## Key Simplifications

This streamlined architecture provides:

- **Single Entry Point**: `./install.sh` - one command for everything
- **Integrated Workflow**: Pre-check → Install → Post-verify in one flow  
- **Built-in Diagnostics**: Expandable HTML reports with system details
- **Privacy-First**: GDPR-compliant analytics with user consent
- **Self-Contained**: Inline tests reduce external dependencies
- **Clear Structure**: Core logic in `Components/Core/` directory

## Analytics & Privacy

**Anonymous Usage Analytics** with full GDPR compliance:
- Native macOS consent dialog on first run
- Tracks installation success/failure for improvements
- No personal information collected
- Full opt-out: `piwik_opt_out` or set `PIS_ENV="CI"`

## Diagnostic Reports

**Interactive HTML reports** with:
- Expandable sections for detailed terminal output
- Clear pass/fail indicators and system information  
- Email integration for support requests
- Professional DTU branding and styling

Reports saved as: `/tmp/dtu_installation_report_*.html`

## Development

### Quick Testing
```bash
# 1. Fork repository and set environment variables
export REMOTE_PS="your-username/pythonsupport-scripts"
export BRANCH_PS="your-feature-branch"

# 2. Test the complete workflow
./MacOS/install.sh

# 3. Check generated files
ls /tmp/dtu_*
```

### Debug Files
- `/tmp/dtu_install_*.log` - Installation logs
- `/tmp/dtu_pre_install_findings.env` - System state
- `/tmp/dtu_installation_report_*.html` - Diagnostic reports

## Requirements

**System**: macOS 10.14+, 2GB free space, internet connection  
**Architectures**: Intel (x86_64) and Apple Silicon (arm64) Macs

## Troubleshooting

**Common fixes:**
- Permission errors: `chmod +x MacOS/install.sh`
- Network issues: Try cellular hotspot if corporate network blocks downloads
- Existing installations: Pre-install check will detect and warn about conflicts

**Get help:**
- pythonsupport@dtu.dk  
- https://pythonsupport.dtu.dk
- https://pythonsupport.dtu.dk/install/macos/automated-error.html

## Updates

Re-run `./MacOS/install.sh` - the system detects existing installations and updates only what's needed.

## Contributing

1. Fork → Create branch → Test thoroughly → Submit PR
2. Test on both Intel and Apple Silicon Macs  
3. Update documentation for significant changes

---

**DTU Python Support Team** • pythonsupport@dtu.dk • https://pythonsupport.dtu.dk