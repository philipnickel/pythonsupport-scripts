#!/bin/bash
# Build script for DTU Python Support - Full GUI Application
# Creates a comprehensive modular macOS app with all components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building DTU Python Support - Full GUI Application...${NC}"

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
SOURCE_SCRIPT="$SCRIPT_DIR/DTUPythonSupportFull.applescript"
OUTPUT_APP="$SCRIPT_DIR/DTUPythonSupportFull.app"

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

# Compile the main AppleScript into an app
echo -e "${BLUE}Compiling main AppleScript to application...${NC}"
osacompile -o "$OUTPUT_APP" "$SOURCE_SCRIPT"

# Compile all modular components
echo -e "${BLUE}Compiling modular component scripts...${NC}"

# Define component scripts
components=(
    "gui_controller.applescript:GUI Controller"
    "diagnostics_manager.applescript:Diagnostics Manager"
    "installation_manager.applescript:Installation Manager"
    "report_manager.applescript:Report Manager"
    "repair_manager.applescript:Repair Manager"
    "settings_manager.applescript:Settings Manager"
)

# Compile each component
for component_entry in "${components[@]}"; do
    IFS=':' read -r script description <<< "$component_entry"
    SCRIPT_PATH="$SCRIPT_DIR/Scripts/$script"
    SCRIPT_NAME="${script%.*}"  # Remove .applescript extension
    OUTPUT_PATH="$OUTPUT_APP/Contents/Resources/${SCRIPT_NAME}.scpt"
    
    if [ -f "$SCRIPT_PATH" ]; then
        osacompile -o "$OUTPUT_PATH" "$SCRIPT_PATH"
        echo -e "${GREEN}✓ Compiled $description${NC}"
    else
        echo -e "${RED}✗ Component script not found: $SCRIPT_PATH${NC}"
    fi
done

# Bundle diagnostic component shell scripts into the app
echo -e "${BLUE}Bundling diagnostic component scripts...${NC}"
COMPONENTS_SRC="$SCRIPT_DIR/../Components/Diagnostics/Components"
COMPONENTS_DST="$OUTPUT_APP/Contents/Resources/diagnostics_components"
mkdir -p "$COMPONENTS_DST"

if [ -d "$COMPONENTS_SRC" ]; then
    cp -f "$COMPONENTS_SRC"/*.sh "$COMPONENTS_DST" 2>/dev/null || true
    chmod +x "$COMPONENTS_DST"/*.sh 2>/dev/null || true
    echo -e "${GREEN}✓ Included diagnostic components:${NC}"
    for script in "$COMPONENTS_DST"/*.sh; do
        if [ -f "$script" ]; then
            basename_script=$(basename "$script")
            echo -e "  • ${basename_script}"
        fi
    done
else
    echo -e "${YELLOW}! Source components directory not found: $COMPONENTS_SRC${NC}"
fi

# Copy the main diagnostics runner script
MAIN_DIAG_SRC="$SCRIPT_DIR/../Components/Diagnostics/run_components.sh"
if [ -f "$MAIN_DIAG_SRC" ]; then
    cp "$MAIN_DIAG_SRC" "$COMPONENTS_DST/"
    chmod +x "$COMPONENTS_DST/run_components.sh"
    echo -e "${GREEN}✓ Included main diagnostics runner${NC}"
fi

# Create application info
echo -e "${BLUE}Configuring application metadata...${NC}"

# Update Info.plist if needed
INFO_PLIST="$OUTPUT_APP/Contents/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    # Update bundle name and identifier
    /usr/libexec/PlistBuddy -c "Set :CFBundleName 'DTU Python Support - Full'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'DTU Python Support'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier 'dk.dtu.pythonsupport.full'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion '2.0.0'" "$INFO_PLIST" 2>/dev/null || true
    echo -e "${GREEN}✓ Updated application metadata${NC}"
fi

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Application compiled successfully!${NC}"
    echo -e "${GREEN}✓ App location: $OUTPUT_APP${NC}"
    
    # Make the app executable
    chmod +x "$OUTPUT_APP"
    
    # Set proper permissions
    chmod 755 "$OUTPUT_APP"
    
    echo -e "${PURPLE}Application Architecture:${NC}"
    echo -e "  📱 Main App: DTUPythonSupportFull.app"
    echo -e "  🎛️  GUI Controller: Manages all user interface flows"
    echo -e "  🔍 Diagnostics Manager: Component-based system analysis"
    echo -e "  📦 Installation Manager: Multiple installation workflows"
    echo -e "  📊 Report Manager: Comprehensive system reporting"
    echo -e "  🔧 Repair Manager: Environment troubleshooting"
    echo -e "  ⚙️  Settings Manager: User preferences and configuration"
    echo ""
    echo -e "${BLUE}Feature Overview:${NC}"
    echo -e "  • Modular component architecture"
    echo -e "  • Integration with MacOS/Components/Diagnostics scripts"
    echo -e "  • Post-installation verification workflows"
    echo -e "  • Multiple installation types (First Year, Advanced, Custom)"
    echo -e "  • Comprehensive diagnostic reporting"
    echo -e "  • Environment repair and troubleshooting"
    echo -e "  • Quick start menu for common tasks"
    echo ""
    echo -e "${BLUE}Application Details:${NC}"
    echo -e "  • Name: DTUPythonSupportFull.app"
    echo -e "  • Type: Modular macOS Application"
    echo -e "  • Location: $OUTPUT_APP"
    echo -e "  • Size: $(du -sh "$OUTPUT_APP" | cut -f1)"
    echo -e "  • Components: $(ls "$OUTPUT_APP/Contents/Resources"/*.scpt 2>/dev/null | wc -l | tr -d ' ') AppleScript modules"
    echo -e "  • Shell Scripts: $(ls "$COMPONENTS_DST"/*.sh 2>/dev/null | wc -l | tr -d ' ') diagnostic components"
    echo ""
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${YELLOW}You can now double-click the app to run it, or drag it to your Applications folder.${NC}"
    echo -e "${PURPLE}This full-featured app provides comprehensive Python development support for DTU students.${NC}"
    
else
    echo -e "${RED}✗ Failed to compile application${NC}"
    exit 1
fi