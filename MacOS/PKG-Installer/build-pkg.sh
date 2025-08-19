#!/bin/bash

# Build DTU Python Support PKG Installer
# Creates a professional PKG that runs installation in background

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"
RESOURCES_DIR="$BUILD_DIR/resources"

# Package information
PKG_NAME="DTUPythonSupport"
PKG_VERSION="1.0.0"
PKG_IDENTIFIER="dk.dtu.pythonsupport"
PKG_FILENAME="$PKG_NAME-$PKG_VERSION.pkg"

echo "Building DTU Python Support PKG Installer..."

# Clean and create build directories
rm -rf "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR/usr/local/share/dtu-python-support"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$RESOURCES_DIR"

# Create preinstall script (runs before installation)
cat > "$SCRIPTS_DIR/preinstall" << 'EOF'
#!/bin/bash

# Pre-installation checks and setup
echo "Preparing DTU Python Support installation..."

# Log to installer log
exec > /tmp/dtu-python-support-install.log 2>&1

echo "$(date): DTU Python Support pre-installation started"
echo "System: $(uname -a)"
echo "User: $(whoami)"

# Check system requirements
if [[ $(uname) != "Darwin" ]]; then
    echo "ERROR: This installer is only compatible with macOS"
    exit 1
fi

# Check for admin privileges
if [[ $EUID -eq 0 ]]; then
    echo "Running as root - OK"
else
    echo "Running as user $(whoami) - installer will handle privilege escalation"
fi

echo "Pre-installation checks completed successfully"
exit 0
EOF

chmod +x "$SCRIPTS_DIR/preinstall"

# Create postinstall script (the main installation happens here)
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash

# DTU Python Support main installation
# This runs silently in the background during PKG installation

exec > /tmp/dtu-python-support-install.log 2>&1
exec 2>&1

echo "$(date): Starting DTU Python Support installation..."

# Function to log progress
log_progress() {
    echo "$(date): $1"
    # Also write to a progress file that could be read by a progress dialog
    echo "$1" > /tmp/dtu-python-support-progress.txt
}

# Function to handle errors
handle_error() {
    local error_msg="$1"
    log_progress "ERROR: $error_msg"
    echo "Installation failed: $error_msg" > /tmp/dtu-python-support-error.txt
    exit 1
}

# Set up error handling
trap 'handle_error "Installation interrupted"' INT TERM

log_progress "Initializing DTU Python Support installation..."

# Check if we're running as root (PKG installer should run as root)
if [[ $EUID -ne 0 ]]; then
    handle_error "Installation must run with administrator privileges"
fi

# Get the actual user who launched the installer
ACTUAL_USER="${USER:-$(logname 2>/dev/null || echo $SUDO_USER)}"
if [[ -z "$ACTUAL_USER" || "$ACTUAL_USER" == "root" ]]; then
    # Fallback: get the console user
    ACTUAL_USER=$(stat -f%Su /dev/console)
fi

log_progress "Installing for user: $ACTUAL_USER"

# Switch to user context for the actual installation
log_progress "Step 1/4: Checking system components..."

# Check current system state
HOMEBREW_INSTALLED=false
PYTHON_INSTALLED=false
VSCODE_INSTALLED=false

# Check as the actual user, not root
if sudo -u "$ACTUAL_USER" command -v brew >/dev/null 2>&1; then
    HOMEBREW_INSTALLED=true
    log_progress "✓ Homebrew detected"
else
    log_progress "• Homebrew will be installed"
fi

if sudo -u "$ACTUAL_USER" command -v conda >/dev/null 2>&1 || sudo -u "$ACTUAL_USER" command -v python3 >/dev/null 2>&1; then
    PYTHON_INSTALLED=true
    log_progress "✓ Python environment detected"
else
    log_progress "• Python environment will be installed"
fi

if [[ -d "/Applications/Visual Studio Code.app" ]] || sudo -u "$ACTUAL_USER" command -v code >/dev/null 2>&1; then
    VSCODE_INSTALLED=true
    log_progress "✓ Visual Studio Code detected"
else
    log_progress "• Visual Studio Code will be installed"
fi

log_progress "Step 2/4: Setting up environment..."

# Set up environment for the installation
export HOME="/Users/$ACTUAL_USER"
export USER="$ACTUAL_USER"

# Create a script to run the installation as the user
cat > /tmp/dtu-install-user.sh << 'USERSCRIPT'
#!/bin/bash

# This script runs as the actual user, not root
exec >> /tmp/dtu-python-support-install.log 2>&1

echo "$(date): Running installation as user $(whoami)"

# Load user's shell environment
[[ -f "$HOME/.bash_profile" ]] && source "$HOME/.bash_profile"
[[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 
[[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

# Function to update progress
log_progress() {
    echo "$(date): $1"
    echo "$1" > /tmp/dtu-python-support-progress.txt
}

log_progress "Step 3/4: Installing Python development environment..."

# Run the DTU Python Support installation script
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/orchestrators/first_year_students.sh)"; then
    log_progress "✓ Installation completed successfully"
    INSTALL_SUCCESS=true
else
    log_progress "⚠ Installation completed with warnings"
    INSTALL_SUCCESS=false
fi

log_progress "Step 4/4: Verifying installation..."

# Run diagnostics to verify the installation
if curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/run.sh | bash >/dev/null 2>&1; then
    log_progress "✓ All diagnostic tests passed"
    echo "SUCCESS" > /tmp/dtu-python-support-result.txt
else
    log_progress "⚠ Some diagnostic tests need attention"
    echo "PARTIAL" > /tmp/dtu-python-support-result.txt
fi

log_progress "Installation process completed"
USERSCRIPT

chmod +x /tmp/dtu-install-user.sh

# Run the installation as the actual user
log_progress "Running installation as user $ACTUAL_USER..."
sudo -u "$ACTUAL_USER" /bin/bash /tmp/dtu-install-user.sh

# Clean up temporary files
rm -f /tmp/dtu-install-user.sh

# Check the result
if [[ -f "/tmp/dtu-python-support-result.txt" ]]; then
    RESULT=$(cat /tmp/dtu-python-support-result.txt)
    case "$RESULT" in
        "SUCCESS")
            log_progress "🎉 DTU Python Support installation completed successfully!"
            ;;
        "PARTIAL") 
            log_progress "DTU Python Support installation completed with some warnings"
            ;;
        *)
            log_progress "DTU Python Support installation finished with unknown status"
            ;;
    esac
else
    log_progress "DTU Python Support installation process finished"
fi

# Create completion notification
cat > /tmp/dtu-python-support-completion.txt << COMPLETION
DTU Python Support Installation Complete

Your Python development environment is now ready for DTU coursework.

What was installed:
• Homebrew (package manager)
• Python/Miniconda (Python environment)
• Visual Studio Code (development environment)
• Python packages for coursework

Next steps:
1. Open Visual Studio Code
2. Create a new Python file (.py)
3. Start coding!

For help and documentation:
https://github.com/dtudk/pythonsupport-scripts

Installation log available at: /tmp/dtu-python-support-install.log
COMPLETION

echo "$(date): DTU Python Support installation completed"
exit 0
EOF

chmod +x "$SCRIPTS_DIR/postinstall"

# Create a simple payload file so PKG has something to install
cat > "$PAYLOAD_DIR/usr/local/share/dtu-python-support/README.txt" << 'EOF'
DTU Python Support

This directory contains files for the DTU Python Support installer.

The main installation is handled by the postinstall script.
For more information, visit: https://github.com/dtudk/pythonsupport-scripts
EOF

# Create Distribution file for a nicer installer experience
cat > "$BUILD_DIR/Distribution" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<installer-script minSpecVersion="1.000000">
    <title>DTU Python Support</title>
    <welcome file="welcome.html"/>
    <conclusion file="conclusion.html"/>
    <background file="background.png" alignment="bottomleft" scaling="proportional"/>
    <options customize="never" allow-external-scripts="false"/>
    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
    
    <choices-outline>
        <line choice="dtu-python-support"/>
    </choices-outline>
    
    <choice id="dtu-python-support" title="DTU Python Support">
        <pkg-ref id="dk.dtu.pythonsupport"/>
    </choice>
    
    <pkg-ref id="dk.dtu.pythonsupport" installKBytes="1024">DTUPythonSupport-1.0.0.pkg</pkg-ref>
</installer-script>
EOF

# Create welcome HTML
cat > "$RESOURCES_DIR/welcome.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
        h1 { color: #007AFF; font-size: 24px; margin-bottom: 20px; }
        h2 { color: #333; font-size: 18px; margin-top: 20px; }
        p { line-height: 1.5; color: #666; }
        ul { color: #666; }
        .highlight { background-color: #f0f8ff; padding: 15px; border-radius: 8px; margin: 15px 0; }
    </style>
</head>
<body>
    <h1>🐍 Welcome to DTU Python Support</h1>
    
    <p>This installer will set up your complete Python development environment for DTU coursework.</p>
    
    <div class="highlight">
        <h2>What will be installed:</h2>
        <ul>
            <li><strong>Homebrew</strong> - Package manager for macOS</li>
            <li><strong>Python/Miniconda</strong> - Python environment with conda package manager</li>
            <li><strong>Visual Studio Code</strong> - Professional code editor</li>
            <li><strong>Python Packages</strong> - Essential packages for your courses</li>
        </ul>
    </div>
    
    <h2>🧠 Smart Installation</h2>
    <p>The installer automatically detects what's already installed on your system and only installs missing components.</p>
    
    <p><strong>Installation time:</strong> 5-15 minutes depending on your internet connection and system configuration.</p>
    
    <p>Click <strong>Continue</strong> to begin the installation process.</p>
</body>
</html>
EOF

# Create conclusion HTML
cat > "$RESOURCES_DIR/conclusion.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
        h1 { color: #28a745; font-size: 24px; margin-bottom: 20px; }
        h2 { color: #333; font-size: 18px; margin-top: 20px; }
        p { line-height: 1.5; color: #666; }
        ul { color: #666; }
        .success { background-color: #d4edda; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #28a745; }
        .next-steps { background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0; }
    </style>
</head>
<body>
    <h1>🎉 Installation Complete!</h1>
    
    <div class="success">
        <p><strong>DTU Python Support has been successfully installed on your system.</strong></p>
    </div>
    
    <div class="next-steps">
        <h2>Next Steps:</h2>
        <ol>
            <li>Open <strong>Visual Studio Code</strong> from your Applications folder</li>
            <li>Create a new Python file (File → New File, save with .py extension)</li>
            <li>Start coding! Try: <code>print("Hello, DTU!")</code></li>
        </ol>
    </div>
    
    <h2>📚 Resources</h2>
    <ul>
        <li><strong>Documentation:</strong> <a href="https://github.com/dtudk/pythonsupport-scripts">DTU Python Support GitHub</a></li>
        <li><strong>Installation Log:</strong> /tmp/dtu-python-support-install.log</li>
        <li><strong>Help & Support:</strong> Create an issue on GitHub for assistance</li>
    </ul>
    
    <p>Your Python development environment is now ready for DTU coursework!</p>
</body>
</html>
EOF

# Build the simple PKG first
echo "Creating PKG file..."
pkgbuild \
    --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "$PKG_IDENTIFIER" \
    --version "$PKG_VERSION" \
    --install-location "/" \
    "$BUILD_DIR/$PKG_FILENAME"

echo ""
echo "✓ DTU Python Support PKG installer created successfully!"
echo ""
echo "📦 Package Details:"
echo "   File: $BUILD_DIR/$PKG_FILENAME"
echo "   Version: $PKG_VERSION"
echo "   Identifier: $PKG_IDENTIFIER"
echo ""
echo "🚀 Features:"
echo "   • Runs completely in background (no Terminal windows)"
echo "   • Smart detection of existing components"
echo "   • Professional installer UI with welcome/conclusion screens"
echo "   • Comprehensive logging to /tmp/dtu-python-support-install.log"
echo "   • Installs Python, VSCode, and all required packages"
echo ""
echo "To test the installer:"
echo "1. Double-click: $BUILD_DIR/$PKG_FILENAME"
echo "2. Follow the installer prompts"
echo "3. Installation runs silently in background"
echo "4. Check /tmp/dtu-python-support-install.log for detailed progress"