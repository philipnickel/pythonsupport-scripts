# DTU Python Installer Makefile

PKG_DIR = MacOS/pkg_installer
BUILD_SCRIPT = $(PKG_DIR)/src/build.sh
COMPONENTS_DIR = MacOS/Components

.PHONY: all pkg-installer build clean help install

# Default target
all: pkg-installer

# Build the PKG installer (primary target)
pkg-installer:
	@echo "Building DTU Python Installer with bundled components..."
	@echo "Preparing component bundling..."
	@# Ensure Components directory exists
	@if [ ! -d "$(COMPONENTS_DIR)" ]; then \
		echo "Error: $(COMPONENTS_DIR) directory not found"; \
		exit 1; \
	fi
	@# Create builds directory if it doesn't exist
	@mkdir -p $(PKG_DIR)/builds/
	@# Copy Components to payload directory before build
	@echo "Bundling MacOS/Components into PKG payload..."
	@rm -rf $(PKG_DIR)/src/payload/Components/
	@mkdir -p $(PKG_DIR)/src/payload/Components/
	@cp -r $(COMPONENTS_DIR)/* $(PKG_DIR)/src/payload/Components/
	@echo "Running build script..."
	@cd $(PKG_DIR) && ./src/build.sh
	@echo "✅ PKG installer built successfully with bundled components!"

# Legacy build target (for backward compatibility)
build: pkg-installer

# Clean build artifacts
clean:
	@echo "Cleaning build files..."
	@rm -rf $(PKG_DIR)/temp_build/
	@rm -rf $(PKG_DIR)/builds/
	@rm -rf $(PKG_DIR)/src/payload/Components/
	@echo "Clean complete"

# Install the latest built PKG (for testing)
install:
	@echo "Installing latest PKG..."
	@PKG_FILE=$$(ls -t $(PKG_DIR)/builds/*.pkg 2>/dev/null | head -n1); \
	if [ -n "$$PKG_FILE" ]; then \
		echo "Installing: $$PKG_FILE"; \
		sudo installer -pkg "$$PKG_FILE" -target /; \
	else \
		echo "No PKG file found. Run 'make pkg-installer' first."; \
		exit 1; \
	fi

# Show help
help:
	@echo "DTU Python Installer Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  pkg-installer - Build the PKG installer with bundled components (recommended)"
	@echo "  build         - Same as pkg-installer (legacy alias)"
	@echo "  clean         - Remove build artifacts and bundled components"
	@echo "  install       - Install the latest built PKG"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make                # Build the installer with components"
	@echo "  make pkg-installer  # Same as above"
	@echo "  make install        # Install latest PKG"
	@echo "  make clean          # Clean all build artifacts"
	@echo ""
	@echo "Component Bundling:"
	@echo "  $(COMPONENTS_DIR)/ -> PKG payload at build time"
	@echo "  Components are accessible from postinstall script"
	@echo ""
	@echo "Files and Directories:"
	@echo "  $(PKG_DIR)/src/metadata/config.sh     - Configuration"
	@echo "  $(PKG_DIR)/src/resources/             - RTF, images, HTML"
	@echo "  $(PKG_DIR)/src/Scripts/               - Installation scripts"
	@echo "  $(PKG_DIR)/src/payload/               - PKG payload (auto-populated)"
	@echo "  $(PKG_DIR)/builds/                    - Built PKG files"
	@echo "  $(COMPONENTS_DIR)/                    - Source components (bundled)"