# Shell Script Documentation Format

This document defines the standardized docstring format for shell scripts in this project.

## Format

All shell scripts should begin with a documentation block using this format:

```bash
#!/bin/bash
# @doc
# @name: Script Name
# @description: Brief description of what the script does
# @category: Component category (e.g., Python, LaTeX, VSCode, etc.)
# @requires: List of requirements/dependencies
# @usage: How to use the script
# @example: Example usage
# @notes: Additional notes or warnings
# @author: Author information
# @version: Script version
# @/doc

# Rest of the script...
```

## Fields

- `@name`: Human-readable name of the script
- `@description`: Brief description of functionality  
- `@category`: Component category for organization
- `@requires`: Dependencies (software, environment variables, etc.)
- `@usage`: Command line usage or invocation method
- `@example`: Example usage with sample commands
- `@notes`: Important notes, warnings, or additional information
- `@author`: Author or team responsible
- `@version`: Version number or date

## Example

```bash
#!/bin/bash
# @doc
# @name: Python Component Installer
# @description: Installs Python via Miniconda with essential packages for data science
# @category: Python
# @requires: macOS, Homebrew (will be installed if missing), Internet connection
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/user/repo/branch/MacOS/Components/Python/install.sh)"
# @example: PYTHON_VERSION_PS=3.11 ./install.sh
# @notes: Script will install Homebrew if not present. Supports Python 3.10-3.12.
# @author: Python Support Team
# @version: 2024-08-18
# @/doc

_prefix="PYS:"
echo "$_prefix Python installation starting..."
```

## Documentation Generation

A separate tool will parse these docstrings and generate:
- Component documentation pages
- API reference
- Usage guides
- Installation instructions