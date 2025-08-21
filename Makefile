# DTU Python Installer Makefile

PKG_DIR = MacOS/pkg_installer
BUILD_SCRIPT = $(PKG_DIR)/src/build.sh

.PHONY: all build clean help install test verify

# Default target
all: build

# Build the PKG installer
build:
	@echo "Building DTU Python Installer..."
	@cd $(PKG_DIR) && ./src/build.sh

# Clean build artifacts
clean:
	@echo "Cleaning build files..."
	@rm -rf $(PKG_DIR)/build/
	@rm -rf $(PKG_DIR)/builds/
	@echo "Clean complete"

# Install the latest built PKG (for testing)
install:
	@echo "Installing latest PKG..."
	@PKG_FILE=$$(ls -t $(PKG_DIR)/builds/*.pkg 2>/dev/null | head -n1); \
	if [ -n "$$PKG_FILE" ]; then \
		echo "Installing: $$PKG_FILE"; \
		sudo installer -pkg "$$PKG_FILE" -target /; \
	else \
		echo "No PKG file found. Run a build command first."; \
		exit 1; \
	fi

# Test PKG without installing (shows what would be installed)
test:
	@echo "Testing PKG structure..."
	@PKG_FILE=$$(ls -t $(PKG_DIR)/builds/*.pkg 2>/dev/null | head -n1); \
	if [ -n "$$PKG_FILE" ]; then \
		echo "PKG file: $$PKG_FILE"; \
		echo "Size: $$(du -h "$$PKG_FILE" | cut -f1)"; \
		echo ""; \
		echo "Contents:"; \
		pkgutil --payload-files "$$PKG_FILE" | head -20; \
		echo ""; \
		echo "Scripts:"; \
		pkgutil --scripts "$$PKG_FILE" | head -10; \
	else \
		echo "No PKG file found. Run 'make build' first."; \
		exit 1; \
	fi

# Verify both installation methods produce same results
verify:
	@echo "This would run diagnostics on both PKG and curl-based installations"
	@echo "Feature not yet implemented - requires test environment setup"

# Show help
help:
	@echo "DTU Python Installer Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build     - Build the PKG installer"
	@echo "  clean     - Remove build artifacts"
	@echo "  install   - Install the latest built PKG (requires sudo)"
	@echo "  test      - Test PKG structure without installing"
	@echo "  verify    - Verify both installation methods work identically"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make          # Build the installer"
	@echo "  make build    # Same as above"
	@echo "  make test     # Check PKG contents"
	@echo "  make install  # Install latest PKG"
	@echo ""
	@echo "Files:"
	@echo "  $(PKG_DIR)/src/metadata/config.sh     - Configuration"
	@echo "  $(PKG_DIR)/src/build.sh               - Build script"
	@echo "  $(PKG_DIR)/builds/                    - Built PKG files"