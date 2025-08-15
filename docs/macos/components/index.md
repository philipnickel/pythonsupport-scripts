# Components Overview

The modular component system allows individual installation and testing of different tools. 
Some components depend on others, but all components can be installed independently.
Each component is run by 'curling' the bash script from the github repo and then executing it. This allows for 'oneliners'.

## Available Components

| Component | Purpose | Dependencies |
|-----------|---------|--------------|
| [Diagnostics](diagnostics.md) | System compatibility checks | None |
| [Homebrew](homebrew.md) | Package manager installation | None |
| [Python](python.md) | Miniconda installation and setup (envs and configs.) | Homebrew |
| [VSCode](vscode.md) | Visual Studio Code and extensions | Homebrew |
| [LaTeX](latex.md) | TeXLive distribution and pdf-export configuration for VSCode | Homebrew |
| [Utilities](utilities.md) | Common utilities | None |

---

## Usage Pattern

Each component can be used independently:

```bash
# Install specific component
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Python/install.sh)"
```

Or combined via orchestrators for complete setups.