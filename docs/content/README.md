# Documentation System

This directory contains the documentation system for the Python Support Scripts project.

## Overview

The documentation is automatically generated from docstrings embedded directly in shell scripts. This ensures that documentation stays up-to-date with the code and provides a single source of truth.

## Structure

```
docs/
├── README.md                 # This file
├── docstring_format.md       # Documentation format specification
├── generated/               # Auto-generated documentation
│   ├── index.md            # Overview and statistics
│   └── components.md       # Detailed component documentation
```

## Docstring Format

Shell scripts use a structured comment format to embed documentation:

```bash
#!/bin/bash
# @doc
# @name: Script Name
# @description: Brief description of functionality
# @category: Component category
# @requires: Dependencies and requirements
# @usage: How to use the script
# @example: Example usage
# @notes: Additional notes or warnings
# @author: Author information
# @version: Version or date
# @/doc

# Script code follows...
```

See [docstring_format.md](docstring_format.md) for complete specification.

## Adding Documentation to Scripts

To add documentation to a script:

1. Add the docstring block at the beginning of the file (after the shebang)
2. Fill in the relevant fields using the format above
3. The documentation will be automatically generated when the script is committed

## Manual Documentation Generation

To manually generate documentation:

```bash
# Generate documentation from all scripts
python3 tools/extract_docs.py --input MacOS/Components --output docs/generated

# Verbose output
python3 tools/extract_docs.py --input MacOS/Components --output docs/generated --verbose
```

## Automated Generation

Documentation is automatically generated via GitHub Actions when:

- Scripts with docstrings are modified
- The documentation extraction tool is updated
- Manually triggered via workflow_dispatch

The workflow:
1. Extracts docstrings from all shell scripts
2. Generates markdown documentation
3. Creates artifacts for download
4. (On main branch) Commits updated documentation

## Benefits

- **Single Source of Truth**: Documentation lives with the code
- **Always Up-to-Date**: Automatically regenerated when code changes
- **Consistent Format**: Standardized structure across all components
- **Easy to Maintain**: No separate documentation files to maintain
- **Developer Friendly**: Documentation is part of the development process