# PKG Installer Configuration System

This document explains the new configuration system for the macOS DTU Python PKG installer.

## Overview

The configuration system allows for environment-specific builds with different settings, making development, testing, and production deployments easier to manage.

## Configuration Files

### Main Configuration
`src/metadata/config.sh` - Contains all default constants and settings

### Environment-Specific Configurations
- `src/metadata/environments/production.sh` - Production releases
- `src/metadata/environments/github_ci.sh` - GitHub Actions CI/CD builds
- `src/metadata/environments/local_testing.sh` - Local development testing

## Build Commands

```bash
# Local testing build (default)
make              # Quick local test
make build-local  # Explicit local build

# GitHub CI build
make build-ci     # For CI/CD pipelines

# Production build
make build-prod   # Official release
```

## Environment Differences

### Local Testing (`build-local`)
- **Package Name**: `MacOS_DTU_Python_Installer_LOCAL`
- **Branch**: Current git branch
- **Version**: No auto-increment (faster iteration)
- **Features**: Minimal (no images/browser summary for speed)
- **Validation**: Disabled for faster builds
- **Use Case**: Quick local development and testing

### GitHub CI (`build-ci`)
- **Package Name**: `MacOS_DTU_Python_Installer`
- **Branch**: Uses `$GITHUB_REF_NAME` from CI environment
- **Version**: Auto-incremented
- **Features**: All features included
- **Validation**: Full validation with verbose output
- **Special**: Uses GitHub Actions environment variables
- **Use Case**: Automated builds in CI/CD pipelines

### Production (`build-prod`)
- **Package Name**: `MacOS_DTU_Python_Installer`
- **Branch**: Always `main`
- **Version**: Auto-incremented
- **Features**: All features included
- **Validation**: Full validation enabled
- **Special**: Supports code signing if certificates available
- **Use Case**: Official releases for distribution

## Configurable Constants

The following constants can be configured in `config.sh` or overridden in environment files:

### Package Information
- `PKG_NAME` - Package filename base
- `PKG_ID` - Bundle identifier
- `PKG_TITLE` - Display title in installer
- `PKG_DESCRIPTION` - Package description

### Repository Settings
- `REPO` - GitHub repository
- `BRANCH` - Git branch to use for installation scripts

### File Paths
- `LOG_FILE` - Installation log path
- `SUMMARY_FILE` - Summary file path

### System Requirements
- `MIN_MACOS_VERSION` - Minimum macOS version
- `MIN_DISK_SPACE_GB` - Minimum disk space requirement

### Build Features
- `AUTO_INCREMENT_VERSION` - Whether to auto-increment version
- `INCLUDE_IMAGES` - Include image resources
- `INCLUDE_BROWSER_SUMMARY` - Include HTML browser summary

### Contact Information
- `SUPPORT_EMAIL` - Support contact email
- `COPYRIGHT_TEXT` - Copyright notice

## Adding New Environments

1. Create new environment file: `src/metadata/environments/[name].sh`
2. Override desired configuration variables
3. Add new Makefile target:
   ```makefile
   build-[name]:
       @cd $(PKG_DIR) && BUILD_ENV=[name] ./src/build.sh
   ```

## Template Variables

The build system replaces the following placeholders in source files:

- `PLACEHOLDER_VERSION` - Current build version
- `PLACEHOLDER_PKG_TITLE` - Package title
- `PLACEHOLDER_PKG_DESCRIPTION` - Package description
- `PLACEHOLDER_PKG_ID` - Bundle identifier
- `PLACEHOLDER_PKG_NAME` - Package name
- `PLACEHOLDER_MIN_MACOS_VERSION` - Minimum macOS version
- `PLACEHOLDER_LOG_FILE` - Log file path
- `PLACEHOLDER_REPO` - Repository name
- `PLACEHOLDER_BRANCH` - Git branch
- `PLACEHOLDER_SUMMARY_FILE` - Summary file path
- `PLACEHOLDER_SUPPORT_EMAIL` - Support email
- `PLACEHOLDER_COPYRIGHT` - Copyright text

## Usage Examples

```bash
# Quick local development iteration
make                    # Default local build
make build-local        # Explicit local build

# CI/CD pipeline build
make build-ci           # Used in GitHub Actions

# Production release
make build-prod         # Official release build

# Clean and rebuild for production
make clean && make build-prod

# GitHub Actions workflow example
BUILD_ENV=github_ci ./src/build.sh
```

## GitHub Actions Integration

The `github_ci` environment automatically uses GitHub environment variables:
- `GITHUB_REF_NAME` - Current branch/tag
- `GITHUB_RUN_NUMBER` - Build number
- `GITHUB_SHA` - Commit hash
- `RUNNER_TEMP` - Temporary directory for logs

Example GitHub Actions workflow:
```yaml
- name: Build PKG
  run: make build-ci
```