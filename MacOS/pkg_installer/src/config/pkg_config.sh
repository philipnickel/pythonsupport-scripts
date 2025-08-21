#!/bin/bash
# @doc
# @name: Package Installer Configuration
# @description: Configuration file for offline Python Support package installer
# @category: Configuration
# @usage: source pkg_config.sh
# @notes: Sets environment variables for offline operation without network dependencies
# @/doc

# Package installer environment configuration
# This file provides offline configuration for Python Support components

# Python version configuration
export PYTHON_VERSION_PS="3.11"

# Environment settings
export PIS_ENV="PKG"
export GITHUB_CI="false"

# Repository settings (used for offline mode identification)
export REMOTE_PS="dtudk/pythonsupport-scripts"
export BRANCH_PS="main"

# Package installer specific settings
export PKG_INSTALLER_MODE="true"
export OFFLINE_MODE="true"

# Logging prefix
export _prefix="PYS-PKG:"

# Base installation paths
export HOMEBREW_PREFIX_INTEL="/usr/local"
export HOMEBREW_PREFIX_APPLE="/opt/homebrew"

# Conda paths for different architectures
export CONDA_PATH_INTEL="/usr/local/Caskroom/miniconda/base/bin"
export CONDA_PATH_APPLE="/opt/homebrew/Caskroom/miniconda/base/bin"

# Default conda environment
export CONDA_DEFAULT_ENV="base"

# Package installer version
export PKG_VERSION="1.0"

# Disable analytics in offline mode
export DISABLE_ANALYTICS="true"
export ANACONDA_ANON_USAGE="false"

# Error handling
export EXIT_ON_ERROR="true"