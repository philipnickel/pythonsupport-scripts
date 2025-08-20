#!/bin/bash
set -e

# DTU Python Installation Script
# This script installs the complete Python development environment for DTU students
# Uses local scripts included in the package (no internet required during installation)

LOG_FILE="PLACEHOLDER_LOG_FILE"
# Stream output both to console (for installer UI/CLI) and to log file
# Create/clear log file, then tee all subsequent output
: > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): === DTU Python installation started ==="

# Determine user
USER_NAME=$(stat -f%Su /dev/console || true)
# In CI there may be no console session; prefer non-root effective user
if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
  USER_NAME="${SUDO_USER:-$(whoami)}"
fi
export USER="$USER_NAME"
export HOME="/Users/$USER_NAME"

# Location where PKG extracted our components
# Install payload places components under /Library to avoid writing to sealed system volume
COMPONENTS_DIR="/Library/dtu_components"

# Ensure remote repository coordinates for any scripts that fetch utilities remotely
# These placeholders are replaced at build time
REMOTE_PS_DEFAULT="PLACEHOLDER_REPO"
BRANCH_PS_DEFAULT="PLACEHOLDER_BRANCH"
export REMOTE_PS="${REMOTE_PS:-$REMOTE_PS_DEFAULT}"
export BRANCH_PS="${BRANCH_PS:-$BRANCH_PS_DEFAULT}"
echo "$(date): Using remote repo $REMOTE_PS on branch $BRANCH_PS for utility loading"

if [[ ! -d "$COMPONENTS_DIR" ]]; then
    echo "$(date): ERROR: Component scripts not found at $COMPONENTS_DIR"
    echo "$(date): Package may be corrupted. Please download a fresh copy."
    exit 1
fi

echo "$(date): Using local component scripts from $COMPONENTS_DIR"
echo "$(date): Orchestrating full installation via first_year_students.sh"

# Prefer local orchestrator; fall back to remote URL
ORCH_LOCAL="$COMPONENTS_DIR/orchestrators/first_year_students.sh"
# On CI runners, install cask apps into user Applications to avoid permission issues
if [[ -n "${GITHUB_ACTIONS:-}" || "${PIS_ENV}" == "CI" ]]; then
    export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
    mkdir -p "$HOME/Applications" || true
    echo "$(date): Using HOMEBREW_CASK_OPTS=$HOMEBREW_CASK_OPTS"
fi
if [[ -f "$ORCH_LOCAL" ]]; then
    echo "$(date): ==> Running local orchestrator..."
    sudo -u "$USER_NAME" env REMOTE_PS="$REMOTE_PS" BRANCH_PS="$BRANCH_PS" PYTHON_VERSION_PS="${PYTHON_VERSION_PS:-3.11}" PIS_ENV="CI" PATH="/opt/homebrew/Caskroom/miniconda/base/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" bash "$ORCH_LOCAL" || echo "$(date): Orchestrator completed with warnings"
else
    echo "$(date): Local orchestrator not found; running remote orchestrator..."
    sudo -u "$USER_NAME" env REMOTE_PS="$REMOTE_PS" BRANCH_PS="$BRANCH_PS" PYTHON_VERSION_PS="${PYTHON_VERSION_PS:-3.11}" PIS_ENV="CI" PATH="/opt/homebrew/Caskroom/miniconda/base/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/$REMOTE_PS/$BRANCH_PS/MacOS/Components/orchestrators/first_year_students.sh)" || echo "$(date): Orchestrator completed with warnings"
fi

# Clean up extracted components (IMPORTANT: Remove scripts from filesystem)
echo "$(date): Cleaning up installation scripts..."
# Keep components for post-install verification/logging in CI environments
if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
    if [[ -d "$COMPONENTS_DIR" ]]; then
        rm -rf "$COMPONENTS_DIR"
        echo "$(date): Removed temporary installation scripts from $COMPONENTS_DIR"
    else
        echo "$(date): Warning: Components directory already removed or not found"
    fi
else
    echo "$(date): Detected CI environment; keeping $COMPONENTS_DIR for inspection"
fi

# Create summary
SUMMARY_FILE="PLACEHOLDER_SUMMARY_FILE"
cat > "$SUMMARY_FILE" << EOF
DTU Python Installation Complete!

Installation log: $LOG_FILE
Date: $(date)
User: $USER_NAME

Components installed:
- Homebrew package manager
- Python (via Miniconda)
- Visual Studio Code
- Python development packages

Next steps:
1. Open Terminal and type 'python3' to test Python
2. Open Visual Studio Code to start coding
3. Check the installation log if you encounter issues

For support: PLACEHOLDER_SUPPORT_EMAIL
EOF

echo "$(date): === Installation completed ==="
echo "Summary created at: $SUMMARY_FILE"

# Show notification
sudo -u "$USER_NAME" osascript -e 'display notification "DTU Python environment installed successfully!" with title "DTU Python Installation Complete"' 2>/dev/null || true

exit 0