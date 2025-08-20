#!/bin/bash
# @doc
# @name: VSCode Installation
# @description: Installs Visual Studio Code on macOS with Python extension setup
# @category: IDE
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/VSC/install.sh)"
# @requirements: macOS system, Homebrew (for cask installation)
# @notes: Uses master utility system for consistent error handling and logging. Configures remote repository settings and installs via Homebrew cask
# @/doc

# Load master utilities
eval "$(curl -fsSL "https://raw.githubusercontent.com/${REMOTE_PS:-dtudk/pythonsupport-scripts}/${BRANCH_PS:-main}/MacOS/Components/Shared/master_utils.sh")"

if [[ "${PIS_ENV:-}" == "CI" && "${SKIP_VSC_INSTALL:-}" == "1" ]]; then
  log_info "Skipping VS Code installation (CI mode)"
  exit 0
fi

log_info "Installing Visual Studio Code"

# Check for homebrew and install if needed
ensure_homebrew

# check if vs code is installed
log_info "Installing Visual Studio Code if not already installed..."
# if output is empty, then install vs code
# Check if VSCode is already installed
if command -v code > /dev/null 2>&1; then
    vspath=$(which code)
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    vspath="/Applications/Visual Studio Code.app"
else
    vspath=""
fi
check_exit_code "Failed to check VSCode installation status"

if [ -n "$vspath" ]  ; then
    log_success "Visual Studio Code is already installed"
else
    log_info "Installing Visual Studio Code"
    # Try default install to /Applications
    if ! brew install --cask visual-studio-code; then
        log_warning "Default cask install failed; retrying with --appdir=$HOME/Applications"
        mkdir -p "$HOME/Applications" || true
        brew install --cask visual-studio-code --appdir="$HOME/Applications"
        check_exit_code "Failed to install Visual Studio Code via Homebrew cask"
    fi
fi

hash -r
clear -x

log_info "Setting up Visual Studio Code environment..."
eval "$(brew shellenv)"

# Ensure 'code' CLI is available on PATH
VSC_APP_PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
VSC_APP_PATH_USER="$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if ! command -v code >/dev/null 2>&1; then
    if [ -x "$VSC_APP_PATH" ]; then
        log_info "Adding VS Code CLI to PATH via symlink"
        # Attempt to link into common bin locations
        for BIN_DIR in /opt/homebrew/bin /usr/local/bin; do
            if [ -d "$BIN_DIR" ] && [ -w "$BIN_DIR" ]; then
                ln -sf "$VSC_APP_PATH" "$BIN_DIR/code" || true
                if "$BIN_DIR/code" --version >/dev/null 2>&1; then
                    log_success "VS Code CLI linked at $BIN_DIR/code"
                    break
                fi
            fi
        done
    elif [ -x "$VSC_APP_PATH_USER" ]; then
        log_info "Adding VS Code CLI (user appdir) to PATH via symlink"
        for BIN_DIR in /opt/homebrew/bin /usr/local/bin; do
            if [ -d "$BIN_DIR" ] && [ -w "$BIN_DIR" ]; then
                ln -sf "$VSC_APP_PATH_USER" "$BIN_DIR/code" || true
                if "$BIN_DIR/code" --version >/dev/null 2>&1; then
                    log_success "VS Code CLI linked at $BIN_DIR/code"
                    break
                fi
            fi
        done
    else
        log_warning "VS Code app CLI not found at expected path: $VSC_APP_PATH"
    fi
fi

# Test if code is installed correctly (with fallback to app path)
if code --version >/dev/null 2>&1 || "$VSC_APP_PATH" --version >/dev/null 2>&1 || "$VSC_APP_PATH_USER" --version >/dev/null 2>&1; then
    log_success "Visual Studio Code installed successfully"
else
    log_error "Visual Studio Code installation failed (CLI not found)"
    exit_message
fi

log_success "Visual Studio Code installation completed!"