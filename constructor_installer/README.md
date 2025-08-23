# DTU Python Environment - Constructor Installer

This directory contains a simplified approach using **Constructor** to build a conda-based installer for the DTU Python Environment.

## What is Constructor?

Constructor is a tool specifically designed for creating conda-based installers. It handles:
- ✅ Package dependency resolution
- ✅ Channel management (conda-forge only)
- ✅ macOS PKG creation
- ✅ Post-install scripts
- ✅ Environment initialization

## Key Advantages

1. **Simplified**: No complex PKG building or orchestrator scripts
2. **Reliable**: Uses conda's native package management
3. **Clean**: Only conda-forge channels (no ToS issues)
4. **Standard**: Follows conda best practices

## Files

- `construct.yaml` - Main configuration file
- `scripts/post_install.sh` - Post-installation script for VS Code
- `build.sh` - Build script
- `README.md` - This file

## Building the Installer

```bash
cd constructor_installer
chmod +x build.sh
./build.sh
```

The installer will be created in `dist/` directory.

## What the Installer Does

1. **Installs Python 3.11** with conda-forge
2. **Installs required packages**:
   - dtumathtools
   - pandas
   - scipy
   - statsmodels
   - uncertainties
   - jupyter
   - notebook
   - ipykernel

3. **Post-install script**:
   - Installs Homebrew (if needed)
   - Installs VS Code
   - Installs Python extensions
   - Creates `dtu-python` launcher script

4. **Initializes conda** in shell profiles

## Usage After Installation

```bash
# Activate the environment
conda activate base

# Or use the launcher
dtu-python

# Check Python version
python --version  # Should show Python 3.11.x

# Import packages
python -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties; print('All packages available!')"
```

## Comparison with Previous Approach

| Aspect | Previous PKG | Constructor |
|--------|-------------|-------------|
| Complexity | High (custom scripts) | Low (standard conda) |
| Reliability | Variable | High |
| Channel Management | Manual | Automatic |
| ToS Issues | Yes (Miniconda) | No (conda-forge) |
| Maintenance | High | Low |
| Standards | Custom | Conda best practices |
