# Python Support Scripts Documentation

This repository contains installation scripts and tools to help DTU students set up Python development environments on macOS and Windows.

## Architecture

The scripts are organized into two main approaches:

### Legacy Scripts

- **MacOS_AutoInstall.sh**: Old installation script
- Direct installation without modular components

### Modular Components (New from Summer 2025)

- **Components**: Individual installation modules that can be used independently
- **Orchestrators**: Scripts that combine multiple components for specific use cases
- Better testing, maintenance, and flexibility
- Can be run through CLI or through the GUI

---

## Components Overview

Each component is a self-contained installation module:

- **Diagnostics**: System compatibility checks and tests for successful installation
- **Homebrew**: Package manager installation
- **Python**: Miniconda installation and configuration
- **VSCode**: Visual Studio Code and extensions
- **LaTeX**: LaTeX distribution (Experimental with limited support)
- **Utilities**: Common utilities used across components for error handling and logging