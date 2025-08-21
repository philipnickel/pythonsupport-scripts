#!/usr/bin/make -f

# DTU Python PKG Installer Makefile
# Creates a self-contained PKG with no network dependencies by bundling component scripts

# Configuration
SCRIPT_DIR := $(shell pwd)
SRC_DIR := $(SCRIPT_DIR)/src
BUILD_DIR := $(SCRIPT_DIR)/temp_build
BUILDS_DIR := $(SCRIPT_DIR)/builds
COMPONENTS_DIR := $(SCRIPT_DIR)/../Components
PAYLOAD_DIR := $(BUILD_DIR)/payload
BUNDLED_COMPONENTS_DIR := $(PAYLOAD_DIR)/usr/local/share/dtu-python-installer/components

# Load version from metadata
VERSION_FILE := $(SRC_DIR)/metadata/.version
VERSION := $(shell test -f $(VERSION_FILE) && cat $(VERSION_FILE) || echo "1.0.0")

# Package configuration (loaded from config.sh)
PKG_NAME := DtuPythonInstaller
PKG_ID := dk.dtu.pythonsupport.dtupythoninstaller

# Component scripts to bundle
PYTHON_SCRIPTS := \
	$(COMPONENTS_DIR)/Python/install.sh \
	$(COMPONENTS_DIR)/Python/first_year_setup.sh

VSC_SCRIPTS := \
	$(COMPONENTS_DIR)/VSC/install.sh \
	$(COMPONENTS_DIR)/VSC/install_extensions.sh \
	$(COMPONENTS_DIR)/VSC/clean_uninstall.sh

SHARED_SCRIPTS := \
	$(COMPONENTS_DIR)/Shared/utils.sh \
	$(COMPONENTS_DIR)/Shared/master_utils.sh \
	$(COMPONENTS_DIR)/Shared/environment.sh \
	$(COMPONENTS_DIR)/Shared/error_handling.sh \
	$(COMPONENTS_DIR)/Shared/dependencies.sh \
	$(COMPONENTS_DIR)/Shared/remote_utils.sh \
	$(COMPONENTS_DIR)/Shared/piwik_utility.sh

ORCHESTRATOR_SCRIPTS := \
	$(COMPONENTS_DIR)/orchestrators/first_year_students.sh

HOMEBREW_SCRIPTS := \
	$(COMPONENTS_DIR)/Homebrew/install.sh

DIAGNOSTICS_SCRIPTS := \
	$(COMPONENTS_DIR)/Diagnostics/generate_report.sh \
	$(COMPONENTS_DIR)/Diagnostics/report_config.sh

# All scripts to bundle
ALL_COMPONENT_SCRIPTS := $(PYTHON_SCRIPTS) $(VSC_SCRIPTS) $(SHARED_SCRIPTS) $(ORCHESTRATOR_SCRIPTS) $(HOMEBREW_SCRIPTS) $(DIAGNOSTICS_SCRIPTS)

# Build targets
.PHONY: all clean pkg test check-components increment-version help

# Default target
all: pkg

help: ## Show this help message
	@echo "DTU Python PKG Installer Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Current version: $(VERSION)"

check-components: ## Verify all required component scripts exist
	@echo "Checking component scripts..."
	@for script in $(ALL_COMPONENT_SCRIPTS); do \
		if [ ! -f "$$script" ]; then \
			echo "ERROR: Missing component script: $$script"; \
			exit 1; \
		else \
			echo "✓ Found: $$script"; \
		fi \
	done
	@echo "All required component scripts found."

increment-version: ## Increment the patch version number
	@if [ -f "$(VERSION_FILE)" ]; then \
		CURRENT_VERSION=$$(cat "$(VERSION_FILE)"); \
		MAJOR=$$(echo $$CURRENT_VERSION | cut -d. -f1); \
		MINOR=$$(echo $$CURRENT_VERSION | cut -d. -f2); \
		PATCH=$$(echo $$CURRENT_VERSION | cut -d. -f3); \
		PATCH=$$((PATCH + 1)); \
		NEW_VERSION="$$MAJOR.$$MINOR.$$PATCH"; \
		echo "$$NEW_VERSION" > "$(VERSION_FILE)"; \
		echo "Version incremented to $$NEW_VERSION"; \
	else \
		echo "1.0.0" > "$(VERSION_FILE)"; \
		echo "Version initialized to 1.0.0"; \
	fi

create-payload: check-components ## Copy component scripts to payload directory
	@echo "Creating payload directory structure..."
	@mkdir -p $(BUNDLED_COMPONENTS_DIR)/Python
	@mkdir -p $(BUNDLED_COMPONENTS_DIR)/VSC
	@mkdir -p $(BUNDLED_COMPONENTS_DIR)/Shared
	@mkdir -p $(BUNDLED_COMPONENTS_DIR)/orchestrators
	@mkdir -p $(BUNDLED_COMPONENTS_DIR)/Homebrew
	@mkdir -p $(BUNDLED_COMPONENTS_DIR)/Diagnostics
	@mkdir -p $(BUNDLED_COMPONENTS_DIR)/Diagnostics/Components
	
	@echo "Copying Python components..."
	@cp $(COMPONENTS_DIR)/Python/install.sh $(BUNDLED_COMPONENTS_DIR)/Python/
	@cp $(COMPONENTS_DIR)/Python/first_year_setup.sh $(BUNDLED_COMPONENTS_DIR)/Python/
	
	@echo "Copying VSC components..."
	@cp $(COMPONENTS_DIR)/VSC/install.sh $(BUNDLED_COMPONENTS_DIR)/VSC/
	@cp $(COMPONENTS_DIR)/VSC/install_extensions.sh $(BUNDLED_COMPONENTS_DIR)/VSC/
	@cp $(COMPONENTS_DIR)/VSC/clean_uninstall.sh $(BUNDLED_COMPONENTS_DIR)/VSC/
	
	@echo "Copying Shared utilities..."
	@cp $(COMPONENTS_DIR)/Shared/*.sh $(BUNDLED_COMPONENTS_DIR)/Shared/
	
	@echo "Copying orchestrators..."
	@cp $(COMPONENTS_DIR)/orchestrators/first_year_students.sh $(BUNDLED_COMPONENTS_DIR)/orchestrators/
	
	@echo "Copying Homebrew components..."
	@cp $(COMPONENTS_DIR)/Homebrew/install.sh $(BUNDLED_COMPONENTS_DIR)/Homebrew/
	
	@echo "Copying Diagnostics components..."
	@cp $(COMPONENTS_DIR)/Diagnostics/generate_report.sh $(BUNDLED_COMPONENTS_DIR)/Diagnostics/
	@cp $(COMPONENTS_DIR)/Diagnostics/report_config.sh $(BUNDLED_COMPONENTS_DIR)/Diagnostics/
	@cp -r $(COMPONENTS_DIR)/Diagnostics/Components/* $(BUNDLED_COMPONENTS_DIR)/Diagnostics/Components/
	
	@echo "Setting execute permissions..."
	@find $(BUNDLED_COMPONENTS_DIR) -name "*.sh" -type f -exec chmod +x {} \;
	
	@echo "Creating curl wrapper for offline mode..."
	@echo '#!/bin/bash' > $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '# Curl wrapper for offline PKG installer' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '# Intercepts curl calls and returns local file contents instead' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '# Extract the URL and identify the component being requested' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo 'URL="$$4"  # curl -fsSL URL' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo 'COMPONENTS_PATH="/usr/local/share/dtu-python-installer/components"' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '# Extract the component path from the GitHub URL' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo 'if [[ "$$URL" =~ github\.com/.*/MacOS/Components/(.*)$$ ]]; then' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '    COMPONENT_PATH="$${BASH_REMATCH[1]}"' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '    LOCAL_FILE="$$COMPONENTS_PATH/$$COMPONENT_PATH"' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '    ' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '    if [ -f "$$LOCAL_FILE" ]; then' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '        cat "$$LOCAL_FILE"' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '        exit 0' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '    else' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '        echo "ERROR: Local component file not found: $$LOCAL_FILE" >&2' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '        exit 1' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '    fi' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo 'fi' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo '# If not a component request, call real curl (this shouldnt happen in offline mode)' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo 'echo "ERROR: Unsupported URL in offline mode: $$URL" >&2' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@echo 'exit 1' >> $(BUNDLED_COMPONENTS_DIR)/curl
	@chmod +x $(BUNDLED_COMPONENTS_DIR)/curl
	

create-offline-postinstall: ## Create modified postinstall script for offline installation
	@echo "Creating offline-capable postinstall script..."
	@mkdir -p $(BUILD_DIR)/Scripts
	@sed -e "s|PLACEHOLDER_LOG_FILE|/tmp/macos_dtu_python_install.log|g" \
	     -e "s|PLACEHOLDER_REPO|bundled|g" \
	     -e "s|PLACEHOLDER_BRANCH|local|g" \
	     -e "s|PLACEHOLDER_SUMMARY_FILE|/tmp/macos_dtu_python_summary.txt|g" \
	     -e "s|PLACEHOLDER_SUPPORT_EMAIL|python-support@dtu.dk|g" \
		$(SRC_DIR)/Scripts/postinstall.sh > $(BUILD_DIR)/Scripts/postinstall_template
	
	@# Replace the curl-based orchestrator call with local execution
	@echo "#!/bin/bash" > $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "# DTU Python Installation Script (PKG Installer - Offline Mode)" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "# This script uses bundled components instead of downloading from GitHub" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'LOG_FILE="/tmp/macos_dtu_python_install.log"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'exec > >(tee -a "$$LOG_FILE") 2>&1' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'echo "$$(date): DEBUG: PKG installer using bundled components (offline mode)"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "# Determine user and set environment" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'USER_NAME=$$(stat -f%Su /dev/console)' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'export USER="$$USER_NAME"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'export HOME="/Users/$$USER_NAME"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "# Load offline configuration" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'source /usr/local/share/dtu-python-installer/components/offline_config.sh' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'echo "$$(date): DEBUG: User=$$USER_NAME, Home=$$HOME"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'echo "$$(date): DEBUG: Using bundled components in offline mode"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "# Load loading animation functions" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'SCRIPT_DIR="$$(dirname "$$0")"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'source "$$SCRIPT_DIR/loading_animations.sh" 2>/dev/null || {' >> $(BUILD_DIR)/Scripts/postinstall
	@echo '    show_progress_log() { echo "$$(date '\''+%H:%M:%S'\'') [$${2:-INFO}] DTU Python Installer: $$1"; }' >> $(BUILD_DIR)/Scripts/postinstall
	@echo '    show_installer_header() { echo "=== DTU Python Installation ==="; }' >> $(BUILD_DIR)/Scripts/postinstall
	@echo '}' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "show_installer_header" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'show_progress_log "Starting first year students installation (offline mode)..." "INFO"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "# Execute original orchestrator script with curl wrapper" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'show_progress_log "Executing original first_year_students.sh orchestrator with offline components..." "INFO"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'if sudo -u "$$USER_NAME" env HOME="/Users/$$USER_NAME" PATH="/usr/local/share/dtu-python-installer/components:$$PATH" DTU_PYTHON_OFFLINE_MODE="true" DTU_COMPONENTS_PATH="/usr/local/share/dtu-python-installer/components" PIS_ENV="CI" GITHUB_CI="true" CI="true" GITHUB_ACTIONS="true" RUNNER_OS="macOS" /bin/bash "/usr/local/share/dtu-python-installer/components/orchestrators/first_year_students.sh"; then' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "    orchestrator_ret=0" >> $(BUILD_DIR)/Scripts/postinstall
	@echo '    echo "$$(date): DEBUG: Orchestrator completed successfully"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo '    show_progress_log "🎉 First year students orchestrator completed successfully!" "INFO"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "else" >> $(BUILD_DIR)/Scripts/postinstall
	@echo '    orchestrator_ret=$$?' >> $(BUILD_DIR)/Scripts/postinstall
	@echo '    echo "$$(date): DEBUG: Orchestrator failed with exit code: $$orchestrator_ret"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo '    show_progress_log "❌ First year students orchestrator failed" "ERROR"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "fi" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "# Create summary" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'SUMMARY_FILE="/tmp/macos_dtu_python_summary.txt"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'cat > "$$SUMMARY_FILE" << EOF' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "DTU First Year Students Installation Complete!" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "Installation log: $$LOG_FILE" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "Date: $$(date)" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "User: $$USER_NAME" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "Mode: Offline (bundled components)" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "Installation Results:" >> $(BUILD_DIR)/Scripts/postinstall
	@echo '- First Year Students Orchestrator: $$([[ $$orchestrator_ret -eq 0 ]] && echo "SUCCESS" || echo "FAILED")' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "Next steps:" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "1. Open Terminal and type 'python3' to test Python" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "2. Open Visual Studio Code to start coding" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "3. Try importing: dtumathtools, pandas, numpy, matplotlib" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "For support: python-support@dtu.dk" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "EOF" >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'show_progress_log "PKG installer script has finished. Summary created at: $$SUMMARY_FILE" "INFO"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'echo "$$(date): DEBUG: PKG installer script finished"' >> $(BUILD_DIR)/Scripts/postinstall
	@echo "" >> $(BUILD_DIR)/Scripts/postinstall
	@echo 'exit $$orchestrator_ret' >> $(BUILD_DIR)/Scripts/postinstall
	
	@# Copy other scripts
	@cp $(SRC_DIR)/Scripts/preinstall.sh $(BUILD_DIR)/Scripts/preinstall_template
	@sed -e "s|PLACEHOLDER_LOG_FILE|/tmp/macos_dtu_python_install.log|g" \
	     -e "s|PLACEHOLDER_REPO|bundled|g" \
	     -e "s|PLACEHOLDER_BRANCH|local|g" \
		$(BUILD_DIR)/Scripts/preinstall_template > $(BUILD_DIR)/Scripts/preinstall
	@rm $(BUILD_DIR)/Scripts/preinstall_template $(BUILD_DIR)/Scripts/postinstall_template
	
	@cp $(SRC_DIR)/Scripts/loading_animations.sh $(BUILD_DIR)/Scripts/ 2>/dev/null || true
	@chmod +x $(BUILD_DIR)/Scripts/*

pkg: increment-version create-payload create-offline-postinstall ## Build the self-contained PKG installer
	@echo "=== DTU Python PKG Builder (Self-contained) ==="
	@NEW_VERSION=$$(cat $(VERSION_FILE)) && \
	echo "Building version: $$NEW_VERSION" && \
	mkdir -p $(BUILD_DIR) $(BUILDS_DIR) && \
	mkdir -p $(BUILD_DIR)/Resources && \
	echo "Copying installer resources..." && \
	cp $(SRC_DIR)/resources/installerText/Introduction.rtf $(BUILD_DIR)/Resources/ && \
	cp $(SRC_DIR)/resources/installerText/Read\ Me.rtf $(BUILD_DIR)/Resources/ && \
	cp $(SRC_DIR)/resources/installerText/License.rtf $(BUILD_DIR)/Resources/ && \
	sed -e "s/PLACEHOLDER_VERSION/$$NEW_VERSION/g" \
	    -e "s/PLACEHOLDER_SUPPORT_EMAIL/python-support@dtu.dk/g" \
	    -e "s/PLACEHOLDER_COPYRIGHT/© 2024 Technical University of Denmark (DTU). All rights reserved./g" \
		$(SRC_DIR)/resources/installerText/Summary.rtf > $(BUILD_DIR)/Resources/Summary.rtf && \
	if [ -d "$(SRC_DIR)/resources/images" ]; then \
		echo "Copying image resources..."; \
		cp -r $(SRC_DIR)/resources/images/* $(BUILD_DIR)/Resources/ 2>/dev/null || true; \
	fi && \
	if [ -f "$(SRC_DIR)/resources/browserSummary/browserSummary.html" ]; then \
		echo "Copying browser summary..."; \
		cp $(SRC_DIR)/resources/browserSummary/browserSummary.html $(BUILD_DIR)/Resources/; \
	fi && \
	echo "Processing Distribution.xml..." && \
	sed -e "s/PLACEHOLDER_VERSION/$$NEW_VERSION/g" \
	    -e "s/PLACEHOLDER_PKG_TITLE/DTU Python Installer (Self-contained)/g" \
	    -e "s/PLACEHOLDER_PKG_DESCRIPTION/Complete Python development environment for DTU students on macOS (offline installer)/g" \
	    -e "s/PLACEHOLDER_PKG_ID/$(PKG_ID)/g" \
	    -e "s/PLACEHOLDER_PKG_NAME/$(PKG_NAME)/g" \
		$(SRC_DIR)/Distribution.xml > $(BUILD_DIR)/Distribution && \
	echo "Building component package with bundled scripts..." && \
	pkgbuild \
		--root $(PAYLOAD_DIR) \
		--scripts $(BUILD_DIR)/Scripts \
		--identifier $(PKG_ID) \
		--version $$NEW_VERSION \
		$(BUILD_DIR)/$(PKG_NAME)-$$NEW_VERSION.pkg && \
	FINAL_PKG="$(BUILDS_DIR)/$(PKG_NAME)_$$NEW_VERSION.pkg" && \
	echo "Creating final self-contained installer..." && \
	productbuild \
		--distribution $(BUILD_DIR)/Distribution \
		--resources $(BUILD_DIR)/Resources \
		--package-path $(BUILD_DIR) \
		"$$FINAL_PKG" && \
	echo "" && \
	echo "✅ Self-contained build completed successfully!" && \
	echo "📦 Installer: $$FINAL_PKG" && \
	echo "📋 Version: $$NEW_VERSION" && \
	echo "📁 Size: $$(du -h "$$FINAL_PKG" | cut -f1)" && \
	echo "🔧 Mode: Self-contained (no network dependencies)" && \
	echo "" && \
	echo "To install: sudo installer -pkg '$$FINAL_PKG' -target /" && \
	echo "To test: make test"

test: ## Test the built PKG installer (requires sudo)
	@LATEST_PKG=$$(ls -t $(BUILDS_DIR)/$(PKG_NAME)_*.pkg 2>/dev/null | head -1) && \
	if [ -f "$$LATEST_PKG" ]; then \
		echo "Testing PKG installer: $$LATEST_PKG" && \
		echo "This will perform a dry-run installation..." && \
		sudo installer -pkg "$$LATEST_PKG" -target / -dumplog; \
	else \
		echo "No PKG file found. Run 'make pkg' first." && \
		exit 1; \
	fi

clean: ## Remove all build artifacts and temporary files
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(BUILDS_DIR)/*.pkg
	@echo "Clean completed."

# Development targets
show-version: ## Show current version
	@echo "Current version: $(VERSION)"

show-components: ## List all component scripts that will be bundled
	@echo "Component scripts to be bundled:"
	@echo "Python components:"
	@for script in $(PYTHON_SCRIPTS); do echo "  - $$script"; done
	@echo "VSC components:"
	@for script in $(VSC_SCRIPTS); do echo "  - $$script"; done
	@echo "Shared utilities:"
	@for script in $(SHARED_SCRIPTS); do echo "  - $$script"; done
	@echo "Orchestrators:"
	@for script in $(ORCHESTRATOR_SCRIPTS); do echo "  - $$script"; done
	@echo "Homebrew components:"
	@for script in $(HOMEBREW_SCRIPTS); do echo "  - $$script"; done

# Safety check - prevent accidental deletion
ifeq ($(COMPONENTS_DIR),)
$(error COMPONENTS_DIR is not set - this is a safety check to prevent accidental deletion)
endif