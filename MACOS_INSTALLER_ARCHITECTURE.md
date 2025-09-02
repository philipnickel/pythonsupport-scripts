# macOS Installer Architecture Overview

## Core Principles

- **Single file installer**: Everything embedded, no network dependencies
- **GitHub Actions testing**: CI on latest macOS
- **Clear UI modes**: Separate CLI and GUI versions with distinct user experiences
- **Modular components**: Python, VS Code, packages as separate modules

## Architecture

```
pythonsupport-scripts/MacOS/
├── src/
│   ├── main.sh                  # Entry point
│   ├── lib/
│   │   ├── core.sh              # Core functions
│   │   ├── ui-cli.sh            # CLI prompts (read -p)
│   │   ├── ui-gui.sh            # GUI prompts (osascript)
│   │   └── config.sh            # Configuration
│   └── components/
│       ├── python.sh            # Miniforge installation
│       ├── vscode.sh            # VS Code installation
│       └── packages.sh          # DTU packages
├── build/
│   ├── create-cli-installer.sh  # Build CLI version
│   └── create-gui-installer.sh  # Build GUI version
├── .github/workflows/
│   └── test.yml                 # CI testing
└── dist/
    ├── dtu-installer-cli.sh     # CLI installer
    └── dtu-installer-gui.sh     # GUI installer
```

## Build Process

```bash
# Build both versions
./build/create-cli-installer.sh  # CLI version with read -p prompts
./build/create-gui-installer.sh  # GUI version with osascript dialogs

# Output:
# dist/dtu-installer-cli.sh - Terminal-only interface
# dist/dtu-installer-gui.sh - Native macOS dialogs
```

Each installer contains:
- Version info and configuration
- Core functions and chosen UI mode (CLI or GUI)
- Installation components (Python, VS Code, packages)
- Main execution logic

## Testing Strategy

**GitHub Actions CI**: Automatic testing on latest macOS with different scenarios

**Optional VirtualBuddy**: Local testing when needed for debugging

## Workflow

```bash
# 1. Edit and build
vim src/components/python.sh
./build/create-cli-installer.sh   # CLI version
./build/create-gui-installer.sh   # GUI version

# 2. Test via CI
git push  # GitHub Actions tests both versions on latest macOS
```

## Key Features

### UI Modes
- **CLI version**: All prompts use `read -p`, `read -s` for passwords
- **GUI version**: All prompts use `osascript` dialogs, alerts, file choosers
- **Clear separation**: No fallback logic, user chooses which version to download

### Configuration
- **Command flags**: `--dry-run`, `--prefix=PATH`, `--no-shell-init`
- **Environment variables**: `DTU_PYTHON_VERSION`, `DTU_INSTALL_PREFIX`

## Usage

```bash
# CLI version (for terminal users, SSH, automation)
curl -LO https://github.com/dtudk/pythonsupport-scripts/releases/latest/download/dtu-installer-cli.sh
chmod +x dtu-installer-cli.sh
./dtu-installer-cli.sh

# GUI version (for desktop users who prefer dialogs)
curl -LO https://github.com/dtudk/pythonsupport-scripts/releases/latest/download/dtu-installer-gui.sh
chmod +x dtu-installer-gui.sh
./dtu-installer-gui.sh
```

## Benefits

- **Single file**: No dependency chains or network issues
- **Offline capable**: Works after download
- **Tested**: CI on latest macOS
- **User choice**: CLI version for terminal users, GUI version for desktop users
