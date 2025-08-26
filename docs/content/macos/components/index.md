# Components Overview

The modular component system allows individual installation and testing of different tools. 
Some components depend on others, but all components can be installed independently.
Each component is run by 'curling' the bash script from the github repo and then executing it. This allows for 'oneliners'.

## Available Components

| Component | Auto-Generated Docs | Manual Docs | Purpose | Dependencies |
|-----------|--------------------|--------------|---------|--------------| 
| **Diagnostics** | [Script Details](../../generated/diagnostics.md) | [Overview](diagnostics.md) | System compatibility checks | None |
| **Homebrew** | [Script Details](../../generated/components.md#package-manager) | [Overview](homebrew.md) | Package manager installation | None |
| **Python** | [Script Details](../../generated/components.md#python) | [Overview](python.md) | Miniconda installation and setup | Homebrew |
| **VSCode** | [Script Details](../../generated/components.md#ide) | [Overview](vscode.md) | Visual Studio Code and extensions | Homebrew |
| **LaTeX** | [Script Details](../../generated/components.md#latex) | [Overview](latex.md) | TeXLive distribution and PDF export | Homebrew |
| **Utilities** | - | [Overview](utilities.md) | Common utilities | None |

📖 **Script Documentation**: The "Script Details" links contain auto-generated documentation extracted directly from the shell scripts, including usage examples, requirements, and implementation notes.

---

## Usage Pattern

Each component can be used independently:

```bash
# Install specific component
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
```

Or combined via orchestrators for complete setups.