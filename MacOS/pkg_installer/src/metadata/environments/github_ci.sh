#!/bin/bash
# GitHub CI Environment Configuration
# Settings for automated CI/CD builds in GitHub Actions

# CI-specific settings
PKG_NAME="DtuPythonInstaller_CI"
PKG_ID="dk.dtu.pythonsupport.dtupythoninstaller"
PKG_TITLE="DTU Python Installer (CI)"

# Use the branch that triggered the CI
BRANCH="${GITHUB_REF_NAME:-main}"

# CI build features
AUTO_INCREMENT_VERSION=true  # Track versions in CI
INCLUDE_IMAGES=true          # Include all resources
INCLUDE_BROWSER_SUMMARY=true

# CI-specific paths (may be in runner temp)
LOG_FILE="${RUNNER_TEMP:-/tmp}/macos_dtu_python_install_ci.log"
SUMMARY_FILE="${RUNNER_TEMP:-/tmp}/macos_dtu_python_summary_ci.txt"

# Standard requirements
MIN_DISK_SPACE_GB=2

# CI validation settings
VALIDATE_SCRIPTS=true
VALIDATE_RESOURCES=true
VERBOSE_OUTPUT=true

# CI-specific build info
BUILD_NUMBER="${GITHUB_RUN_NUMBER:-0}"
COMMIT_SHA="${GITHUB_SHA:-unknown}"

echo "🤖 GitHub CI build configuration loaded"
echo "   Branch: $BRANCH"
echo "   Build: #$BUILD_NUMBER"
echo "   Commit: ${COMMIT_SHA:0:7}"