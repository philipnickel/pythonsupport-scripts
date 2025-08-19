#!/bin/bash
# @doc
# @name: Homebrew Diagnostics
# @description: Checks Homebrew installation and status
# @category: Diagnostics
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/Components/homebrew_check.sh)"
# @requirements: macOS system
# @notes: Checks if Homebrew is installed and working properly
# @/doc

_prefix="PYS:"

echo "HOMEBREW"
echo "--------"
if command -v brew > /dev/null; then
    echo "✓ Homebrew is installed"
    echo "  Version: $(brew --version | head -n 1)"
    echo "  Location: $(which brew)"
    
    # Check for common issues (skip brew doctor to avoid hanging)
    echo "  Status: ✓ Installed (brew doctor check skipped)"
    echo "  Note: Run 'brew doctor' manually if you need detailed status"
    echo ""
    exit 0
else
    echo "✗ Homebrew is not installed"
    echo "  Required for Python development setup"
    echo ""
    exit 2
fi
