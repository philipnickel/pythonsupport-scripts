# macOS DTU Python PKG Installer

Build system for creating macOS installer packages for DTU Python environment.

## Quick Start

```bash
# From repository root:
make              # Build local test
make build-ci     # Build for CI/CD
make build-prod   # Build production
```

## Directory Structure

```
pkg_installer/
├── src/                          # Source files
│   ├── build.sh                  # Main build script
│   ├── Distribution.xml          # PKG configuration
│   ├── Scripts/                  # Installation scripts
│   │   ├── preinstall.sh
│   │   └── postinstall.sh
│   ├── resources/                # Installer resources
│   │   ├── installerText/        # RTF files for UI
│   │   ├── images/               # Visual assets
│   │   └── browserSummary/       # Post-install HTML
│   ├── metadata/                 # Configuration
│   │   ├── config.sh             # Main config
│   │   ├── .version              # Version tracking
│   │   └── environments/         # Environment configs
│   └── payload/                  # Files to install (if any)
├── builds/                       # Output PKG files
└── CONFIGURATION.md              # Detailed config docs
```

## Environments

All environments now behave the same (full features, version increment):

- **local_testing**: Local development builds
- **github_ci**: CI/CD automated builds  
- **production**: Official releases

See [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration options.