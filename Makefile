# DTU Python Installer Makefile
# Environment-specific build orchestration for PKG installer

PKG_DIR = MacOS/pkg_installer
BUILD_SCRIPT = $(PKG_DIR)/src/build.sh

.PHONY: all build build-local build-ci build-prod clean help install

# Default target - build all environments
all: build-all

# Build all environments
build-all:
	@echo "============================================"
	@echo "Building all DTU Python Installer packages"
	@echo "============================================"
	@$(MAKE) clean
	@$(MAKE) build-prod
	@echo ""
	@$(MAKE) build-ci
	@echo ""
	@$(MAKE) build-local
	@echo ""
	@echo "============================================"
	@echo "✅ All builds completed successfully!"
	@echo "============================================"
	@echo "Recent packages:"
	@ls -lht $(PKG_DIR)/builds/*.pkg | head -10

# Single build (defaults to local)
build:
	@$(MAKE) build-local

build-local:
	@echo "Building DTU Python Installer (Local Testing)..."
	@cd $(PKG_DIR) && BUILD_ENV=local_testing ./src/build.sh

build-ci:
	@echo "Building DTU Python Installer (GitHub CI)..."
	@cd $(PKG_DIR) && BUILD_ENV=github_ci ./src/build.sh

build-prod:
	@echo "Building DTU Python Installer (Production)..."
	@cd $(PKG_DIR) && BUILD_ENV=production ./src/build.sh

# Clean build artifacts (preserves built PKGs)
clean:
	@echo "Cleaning temporary build files..."
	@rm -rf $(PKG_DIR)/temp_build/
	@echo "Clean complete (PKG files preserved)"

# Deep clean - removes everything including PKGs (use with caution)
clean-all:
	@echo "WARNING: This will delete all built PKG files!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -rf $(PKG_DIR)/temp_build/; \
		rm -rf $(PKG_DIR)/builds/*.pkg; \
		echo "All build artifacts removed"; \
	else \
		echo "Cancelled"; \
	fi

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

# Show help
help:
	@echo "DTU Python Installer Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all         - Build all environments (prod, CI, local)"
	@echo "  build-all   - Same as 'all'"
	@echo "  build-local - Build for local testing"
	@echo "  build-ci    - Build for GitHub CI/CD"
	@echo "  build-prod  - Build production release"
	@echo "  build       - Single build (defaults to local)"
	@echo "  clean       - Clean temp files only (preserves PKGs)"
	@echo "  clean-all   - Remove everything including PKGs (caution!)"
	@echo "  install     - Install the latest built PKG"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Environment configurations:"
	@echo "  production    - Official releases (DtuPythonInstaller_X.Y.Z.pkg)"
	@echo "  github_ci     - CI builds (DtuPythonInstaller_CI_X.Y.Z.pkg)"
	@echo "  local_testing - Local testing (DtuPythonInstaller_LOCAL_X.Y.Z.pkg)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make              # Build all environments"
	@echo "  make all          # Build all environments"
	@echo "  make build-local  # Quick local test build"
	@echo "  make build-prod   # Production release only"
	@echo ""
	@echo "Files:"
	@echo "  $(PKG_DIR)/src/metadata/config.sh           - Main configuration"
	@echo "  $(PKG_DIR)/src/metadata/environments/       - Environment configs"
	@echo "  $(PKG_DIR)/src/resources/                   - RTF, images, HTML"
	@echo "  $(PKG_DIR)/src/Scripts/                     - Installation scripts"
	@echo "  $(PKG_DIR)/builds/                          - Built PKG files"