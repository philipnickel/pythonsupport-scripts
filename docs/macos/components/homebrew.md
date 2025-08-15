# Homebrew Component

Installs Homebrew package manager for macOS.

## What it does

1. **Installation Check**: Verifies if Homebrew is already installed
2. **Homebrew Installation**: Downloads and installs from official source
3. **Path Configuration**: Adds Homebrew to shell PATH
4. **Verification**: Tests that `brew` command works

## Requirements

- Officially very old macs are not supported - but works most of the time anyway.

---

## Scripts

### `install.sh`

Main installation script for Homebrew.

**Installation Process:**

- Downloads official Homebrew installation script
- Updates shell configuration files
- Refreshes environment variables

**Expected Outcome:**

- `brew` command available in PATH
- Homebrew installed in `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel)
- Shell profiles updated for future sessions

---

## Usage

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Homebrew/install.sh)"
```