# VSC Components

Documentation for VSC installation scripts.

## VS Code Clean Uninstaller

**Description:** Completely removes Visual Studio Code and all user data according to official documentation

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/clean_uninstall.sh)"
```

**Notes:** Uses master utility system for consistent error handling and logging. Removes VS Code application, user settings folder (~/.vscode), and application support data (~/Library/Application Support/Code). Also handles Homebrew-installed VS Code. This follows the official VS Code uninstall documentation exactly.

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/clean_uninstall.sh)"
```

---

## VSCode Installation

**Description:** Installs Visual Studio Code on macOS with Python extension setup

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install.sh)"
```

**Requirements:** macOS system, Homebrew (for cask installation)

**Notes:** Uses master utility system for consistent error handling and logging. Configures remote repository settings and installs via Homebrew cask

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install.sh)"
```

---

## VSCode Extensions Installation

**Description:** Installs essential VSCode extensions for Python development

**Usage:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install_extensions.sh)"
```

**Requirements:** VSCode installed on system

**Notes:** Installs Python extension pack and other development tools

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install_extensions.sh)"
```

---

