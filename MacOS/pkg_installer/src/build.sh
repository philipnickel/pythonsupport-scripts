#!/bin/bash
set -euo pipefail

# DTU Python PKG Builder - Simplified Build Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "$SCRIPT_DIR/metadata/config.sh"

echo "=== $PKG_TITLE Build System ==="
echo

# Get and increment version (always increment)
if [[ -f "$VERSION_FILE" ]]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    PATCH=$((PATCH + 1))
    VERSION="$MAJOR.$MINOR.$PATCH"
else
    VERSION="1.0.0"
fi
echo "$VERSION" > "$VERSION_FILE"

echo "Building $PKG_NAME version $VERSION..."

# Set up directories
BUILD_DIR="$SCRIPT_DIR/../temp_build"
BUILDS_DIR="$SCRIPT_DIR/../builds"
SOURCE_DIR="$SCRIPT_DIR"
RESOURCES_DIR="$BUILD_DIR/Resources"
SCRIPTS_DIR="$BUILD_DIR/Scripts"

# Clean and create build directories
rm -rf "$BUILD_DIR"
mkdir -p "$RESOURCES_DIR" "$SCRIPTS_DIR" "$BUILDS_DIR"

# Copy RTF resources (update version placeholders)
echo "Copying installer text resources..."
cp "$SOURCE_DIR/resources/installerText/Introduction.rtf" "$RESOURCES_DIR/"
cp "$SOURCE_DIR/resources/installerText/Read Me.rtf" "$RESOURCES_DIR/"
cp "$SOURCE_DIR/resources/installerText/License.rtf" "$RESOURCES_DIR/"

# Process Summary.rtf with version and configuration
sed -e "s/PLACEHOLDER_VERSION/$VERSION/g" \
    -e "s/PLACEHOLDER_SUPPORT_EMAIL/$SUPPORT_EMAIL/g" \
    -e "s/PLACEHOLDER_COPYRIGHT/$COPYRIGHT_TEXT/g" \
    "$SOURCE_DIR/resources/installerText/Summary.rtf" > "$RESOURCES_DIR/Summary.rtf"

# Copy images if enabled
if [[ "$INCLUDE_IMAGES" == "true" && -d "$SOURCE_DIR/resources/images" ]]; then
    echo "Copying image resources..."
    cp -r "$SOURCE_DIR/resources/images"/* "$RESOURCES_DIR/" 2>/dev/null || true
fi

# Copy browser summary if enabled
if [[ "$INCLUDE_BROWSER_SUMMARY" == "true" && -f "$SOURCE_DIR/resources/browserSummary/browserSummary.html" ]]; then
    echo "Copying browser summary..."
    cp "$SOURCE_DIR/resources/browserSummary/browserSummary.html" "$RESOURCES_DIR/"
fi

# Copy and process installation scripts
echo "Processing installation scripts..."
# Update scripts with configuration values
sed -e "s|PLACEHOLDER_LOG_FILE|$LOG_FILE|g" \
    -e "s|PLACEHOLDER_REPO|$REPO|g" \
    -e "s|PLACEHOLDER_BRANCH|$BRANCH|g" \
    "$SOURCE_DIR/Scripts/preinstall.sh" > "$SCRIPTS_DIR/preinstall"

sed -e "s|PLACEHOLDER_LOG_FILE|$LOG_FILE|g" \
    -e "s|PLACEHOLDER_REPO|$REPO|g" \
    -e "s|PLACEHOLDER_BRANCH|$BRANCH|g" \
    -e "s|PLACEHOLDER_SUMMARY_FILE|$SUMMARY_FILE|g" \
    -e "s|PLACEHOLDER_SUPPORT_EMAIL|$SUPPORT_EMAIL|g" \
    "$SOURCE_DIR/Scripts/postinstall.sh" > "$SCRIPTS_DIR/postinstall"

# Copy loading animations helper script
if [[ -f "$SOURCE_DIR/Scripts/loading_animations.sh" ]]; then
    echo "Copying loading animations helper..."
    cp "$SOURCE_DIR/Scripts/loading_animations.sh" "$SCRIPTS_DIR/"
fi

chmod +x "$SCRIPTS_DIR/"*

# Process Distribution.xml with all configuration values
echo "Processing Distribution.xml..."
sed -e "s/PLACEHOLDER_VERSION/$VERSION/g" \
    -e "s/PLACEHOLDER_PKG_TITLE/$PKG_TITLE/g" \
    -e "s/PLACEHOLDER_PKG_DESCRIPTION/$PKG_DESCRIPTION/g" \
    -e "s/PLACEHOLDER_PKG_ID/$PKG_ID/g" \
    -e "s/PLACEHOLDER_PKG_NAME/$PKG_NAME/g" \
    "$SOURCE_DIR/Distribution.xml" > "$BUILD_DIR/Distribution"

# Create payload directory (minimal - no components bundled)
PAYLOAD_DIR="$BUILD_DIR/payload"
mkdir -p "$PAYLOAD_DIR"

# Copy any additional payload files if they exist
if [[ -d "$SOURCE_DIR/payload" && -n "$(ls -A "$SOURCE_DIR/payload" 2>/dev/null)" ]]; then
    echo "Copying additional payload files..."
    cp -r "$SOURCE_DIR/payload"/* "$PAYLOAD_DIR/"
fi

# For script-only packages, we don't need any payload files
# The PKG will only run the preinstall/postinstall scripts
echo "Creating script-only PKG (no payload files)"

# Create component package
echo "Building component package..."
pkgbuild \
    --root "$PAYLOAD_DIR" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "$PKG_ID" \
    --version "$VERSION" \
    "$BUILD_DIR/${PKG_NAME}-${VERSION}.pkg"

# Create final installer
FINAL_PKG="$BUILDS_DIR/${PKG_NAME}_${VERSION}.pkg"
echo "Creating final installer..."

productbuild \
    --distribution "$BUILD_DIR/Distribution" \
    --resources "$RESOURCES_DIR" \
    --package-path "$BUILD_DIR" \
    "$FINAL_PKG"

# Cleanup temp_build directory
echo "Cleaning up temporary build files..."
rm -rf "$BUILD_DIR"

echo
echo "✅ Build completed successfully!"
echo "📦 Installer: $FINAL_PKG"
echo "📋 Version: $VERSION"
echo "📁 Size: $(du -h "$FINAL_PKG" | cut -f1)"
echo
echo "To install: sudo installer -pkg '$FINAL_PKG' -target /"