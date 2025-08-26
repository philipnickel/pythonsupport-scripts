# Python Support Scripts

Welcome to the DTU Python Support installation scripts documentation. These tools help students set up complete Python development environments on macOS and Windows.

## Quick Start

### 🍎 MacOS

**Complete Installation (Recommended)**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/orchestrators/first_year_students.sh)"
```

**Individual Components**
```bash
# System diagnostics
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/run.sh)"

# Homebrew package manager
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Homebrew/install.sh)"

# Python environment
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"

# VS Code editor
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install.sh)"
```

### 🪟 Windows

Windows support is coming soon. Check back for updates.

## 📚 Documentation

All script documentation is automatically generated from the source code to ensure it stays current.

**MacOS Components:**
- **[Diagnostics →](macos/components/diagnostics.md)** - System compatibility checks and HTML report
- **[Homebrew →](generated/homebrew.md)** - Package manager installation
- **[Python →](generated/python.md)** - Python environment setup  
- **[VSCode →](generated/vsc.md)** - Code editor and extensions
- **[LaTeX →](generated/latex.md)** - Document preparation system
- **[Utilities →](generated/utilities.md)** - Shared utilities and analytics
- **[Orchestrators →](generated/orchestrators.md)** - Complete installation workflows

**Windows Components:**
- **[Components →](windows/components/index.md)** - Windows support (coming soon)

## 🛠️ What Gets Installed

- **Homebrew**: macOS package manager
- **Python**: Miniconda with conda environments  
- **VS Code**: Code editor with Python extensions
- **LaTeX**: Document preparation (optional)

## 💡 Support

- **Issues**: Report problems at [GitHub Issues](https://github.com/dtudk/pythonsupport-scripts/issues)
- **Email**: pythonsupport@dtu.dk
- **Office Hours**: Visit our support sessions
