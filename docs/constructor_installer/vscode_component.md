# VSCode PKG Component (Phase 2)

This directory contains the VSCode PKG component for the DTU hybrid installer approach.

## Overview

Creates a standalone VSCode PKG installer that:
- Downloads VSCode directly from Microsoft
- Installs VSCode.app to `/Applications/`
- Sets up CLI tools (`code` command)
- Pre-installs Python development extensions
- Configures settings for Python development

## Files

- `build_vscode_pkg.sh` - Main PKG builder script
- `test_vscode_pkg.sh` - Testing script for PKG validation
- `extensions/` - Extension configurations
- `templates/` - Settings templates
- `scripts/` - Helper scripts
- `docs/` - Component documentation

## Usage

### Build VSCode PKG

```bash
./build_vscode_pkg.sh
```

This will:
1. Download latest VSCode from Microsoft
2. Create installation payload
3. Generate post-install script for extensions
4. Build final PKG installer

### Test VSCode PKG

```bash
./test_vscode_pkg.sh [path/to/pkg]
```

Tests:
- VSCode app installation
- CLI tool setup
- Extension installation
- Python integration

## What Gets Installed

### VSCode Application
- Full VSCode.app in `/Applications/`
- Symlinked `code` command in `/usr/local/bin/`
- System PATH integration

### Python Extensions
- `ms-python.python` - Python language support
- `ms-toolsai.jupyter` - Jupyter notebook support  
- `tomoki1207.pdf` - PDF viewer

### Configuration
- Python-optimized settings.json
- Default interpreter configuration
- Telemetry disabled
- Format on save enabled

## Integration with Constructor PKG

This VSCode PKG is designed to work alongside the constructor-based Python PKG:

1. **Independent Installation**: Can be installed separately or together
2. **Python Detection**: Will automatically detect constructor-installed Python
3. **Settings Optimization**: Pre-configured for DTU Python coursework
4. **No Homebrew**: Completely eliminates Homebrew dependency

## CI/CD Integration

GitHub Actions workflow automatically:
- Builds VSCode PKG on code changes
- Tests installation in clean macOS environment
- Validates all components work correctly
- Stores PKG artifacts for download

## Success Criteria

- ✅ VSCode app installs to correct location
- ✅ CLI command `code --version` works
- ✅ Python extensions are pre-installed
- ✅ Settings are optimized for Python development
- ✅ Works independently and with constructor Python PKG
- ✅ No Homebrew dependency

## Next Steps (Phase 3)

- Integration testing with constructor Python PKG
- Combined installer workflow
- Performance optimization
- Enterprise deployment testing