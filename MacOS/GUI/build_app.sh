#!/bin/bash
# Build script for First Year Python Installer for macOS
# Compiles AppleScript into a portable macOS app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building First Year Python Installer for macOS...${NC}"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script must be run on macOS${NC}"
    exit 1
fi

# Check if osacompile is available
if ! command -v osacompile &> /dev/null; then
    echo -e "${RED}Error: osacompile not found. This script requires macOS.${NC}"
    exit 1
fi

# Set up paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/FirstYearPythonInstallerMacOS.applescript"
OUTPUT_APP="$SCRIPT_DIR/FirstYearPythonInstallerMacOS.app"

echo -e "${YELLOW}Source script: $SOURCE_SCRIPT${NC}"
echo -e "${YELLOW}Output app: $OUTPUT_APP${NC}"

# Check if source script exists
if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    echo -e "${RED}Error: Source script not found: $SOURCE_SCRIPT${NC}"
    exit 1
fi

# Remove existing app if it exists
if [[ -d "$OUTPUT_APP" ]]; then
    echo -e "${YELLOW}Removing existing app...${NC}"
    rm -rf "$OUTPUT_APP"
fi

# Compile the AppleScript into an app
echo -e "${BLUE}Compiling AppleScript to application...${NC}"
osacompile -o "$OUTPUT_APP" "$SOURCE_SCRIPT"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Application compiled successfully!${NC}"
    echo -e "${GREEN}✓ App location: $OUTPUT_APP${NC}"
    
    # Make the app executable
    chmod +x "$OUTPUT_APP"
    
    # Set proper permissions
    chmod 755 "$OUTPUT_APP"
    
    echo -e "${BLUE}Application details:${NC}"
    echo -e "  • Name: FirstYearPythonInstallerMacOS.app"
    echo -e "  • Type: Portable macOS Application"
    echo -e "  • Location: $OUTPUT_APP"
    echo -e "  • Size: $(du -sh "$OUTPUT_APP" | cut -f1)"
    
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${YELLOW}You can now double-click the app to run it, or drag it to your Applications folder.${NC}"
    
else
    echo -e "${RED}✗ Failed to compile application${NC}"
    exit 1
fi
