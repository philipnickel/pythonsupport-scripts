#!/bin/bash
# @name: Python Development Compatibility
# @description: Check if system is compatible with Python development
# @category: System
# @subcategory: Compatibility
# @timeout: 8

echo "PYTHON DEVELOPMENT COMPATIBILITY"
echo "================================"

compatibility_issues=0

# Check macOS version
echo "macOS Compatibility:"
echo "-------------------"
macos_version=$(sw_vers -productVersion 2>/dev/null)
if [ -n "$macos_version" ]; then
    echo "macOS Version: $macos_version"
    
    # Check if version is >= 10.14 (minimum for modern Python development)
    if [[ "$macos_version" =~ ^([0-9]+)\.([0-9]+) ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        
        if [ "$major" -gt 10 ] || ([ "$major" -eq 10 ] && [ "$minor" -ge 14 ]); then
            echo "✓ System is compatible with Python development (macOS $macos_version >= 10.14)"
        else
            echo "✗ System may have compatibility issues (macOS $macos_version < 10.14)"
            compatibility_issues=1
        fi
    else
        echo "⚠ Unable to parse macOS version format"
    fi
else
    echo "✗ Unable to determine macOS version"
    compatibility_issues=1
fi

echo ""

# Check architecture
echo "Architecture Compatibility:"
echo "--------------------------"
arch=$(uname -m 2>/dev/null)
case "$arch" in
    "x86_64")
        echo "✓ Intel x64 architecture - Compatible"
        ;;
    "arm64")
        echo "✓ Apple Silicon (M1/M2/M3) architecture - Compatible"
        ;;
    *)
        echo "⚠ Unknown architecture: $arch"
        ;;
esac

echo ""

# Check for Xcode Command Line Tools
echo "Development Tools:"
echo "-----------------"
if [ -d "/Library/Developer/CommandLineTools" ]; then
    echo "✓ Xcode Command Line Tools: /Library/Developer/CommandLineTools"
else
    echo "✗ Xcode Command Line Tools not found"
    echo "  Install with: xcode-select --install"
    compatibility_issues=1
fi

# Check for git (usually comes with command line tools)
if command -v git >/dev/null 2>&1; then
    git_version=$(git --version 2>/dev/null | awk '{print $3}')
    echo "✓ Git: $git_version"
else
    echo "✗ Git not found"
    compatibility_issues=1
fi

echo ""

if [ $compatibility_issues -eq 0 ]; then
    echo "✅ System compatibility check complete - PASSED"
else
    echo "⚠ Compatibility issues detected - SETUP NEEDED"
    exit 1
fi