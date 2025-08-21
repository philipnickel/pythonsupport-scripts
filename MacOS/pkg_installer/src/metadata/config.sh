#!/bin/bash
# PKG Configuration for DTU Python Installer
# This file defines what gets packaged and how

# Package metadata
PKG_NAME="DTU Python First Year Students"
PKG_IDENTIFIER="dk.dtu.pythonsupport.firstyear"
PKG_VERSION="1.1.0"
PKG_DESCRIPTION="Phase 2: Professional installer with Homebrew component for DTU Python development environment"

# Build configuration
BUILD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_ROOT="$(cd "$BUILD_ROOT/../.." && pwd)"
COMPONENTS_SOURCE="$REPO_ROOT/MacOS/Components"
BUILD_DIR="$BUILD_ROOT/build"
BUILDS_DIR="$BUILD_ROOT/builds"
RESOURCES_DIR="$BUILD_ROOT/resources"
PKG_ROOT="$BUILD_DIR/pkg_root"
SCRIPTS_DIR="$BUILD_DIR/scripts"

# Components to copy and localize (relative to MacOS/Components/)
# These will be copied from the single source of truth in the repo
# Phase 2: Adding Homebrew component
COMPONENTS=(
    "Homebrew/install.sh"
    "Shared/master_utils.sh"
    "Shared/dependencies.sh"
    "Shared/piwik_utility.sh"
    "Shared/remote_utils.sh"
    "Shared/utils.sh"
)

# Diagnostics components to copy and localize (relative to MacOS/Components/Diagnostics/)
# Starting with minimal dummy PKG - diagnostics will be added later
DIAGNOSTICS_COMPONENTS=(
    # Phase 1: Minimal dummy - no diagnostics yet
)

# Installation script configuration
INSTALL_SCRIPT="postinstall"
MAIN_ORCHESTRATOR="orchestrators/first_year_students.sh"

# URLs to localize (replace with local file paths)
REMOTE_REPO_PATTERN="https://raw.githubusercontent.com/\${REMOTE_PS:-dtudk/pythonsupport-scripts}/\${BRANCH_PS:-main}/"
DIAG_REPO_PATTERN="https://raw.githubusercontent.com/\${DIAG_REMOTE_PS:-philipnickel/pythonsupport-scripts}/\${DIAG_BRANCH_PS:-main}/"

# Local path prefix (where scripts will be installed)
LOCAL_INSTALL_PATH="/usr/local/share/dtu-pythonsupport"
LOCAL_PATH_PREFIX="file://$LOCAL_INSTALL_PATH/"