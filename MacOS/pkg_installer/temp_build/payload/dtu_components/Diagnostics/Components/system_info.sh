#!/bin/bash
# @doc
# @name: System Information Diagnostics
# @description: Checks macOS version, architecture, and basic system information
# @category: Diagnostics
# @usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/Components/system_info.sh)"
# @requirements: macOS system
# @notes: Basic system compatibility check for Python development
# @/doc

_prefix="PYS:"

echo "SYSTEM INFORMATION"
echo "------------------"
echo "macOS Version: $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"
echo "Hostname: $(hostname)"
echo ""

# Determine status based on macOS version
os_version=$(sw_vers -productVersion)
if [[ "$os_version" > "10.14" ]] || [[ "$os_version" == "10.14" ]]; then
    echo "✓ System is compatible with Python development"
    exit 0
else
    echo "⚠ Consider updating to macOS 10.14 or later for best compatibility"
    exit 1
fi
