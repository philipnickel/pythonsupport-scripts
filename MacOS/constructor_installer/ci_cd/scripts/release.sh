#!/bin/bash

# @doc
# @name: DTU Python Environment Release Script
# @description: Automated release management for DTU Python Development Environment
# @category: Release Management
# @usage: ./release.sh [version] [--prerelease] [--draft]
# @requirements: git, gh CLI, macOS system
# @notes: Manages version tagging, release creation, and automation triggers
# @/doc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Default values
VERSION=""
PRERELEASE=false
DRAFT=false

log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warning() {
    echo "[WARNING] $*"
}

usage() {
    cat << EOF
DTU Python Environment Release Script

Usage: $0 [version] [options]

Arguments:
  version         Release version (e.g., 1.0.0, 1.1.0-beta.1)

Options:
  --prerelease    Mark as pre-release
  --draft         Create as draft release
  --help, -h      Show this help message

Examples:
  $0 1.0.0                    # Create stable release v1.0.0
  $0 1.1.0-beta.1 --prerelease  # Create pre-release v1.1.0-beta.1
  $0 2.0.0 --draft            # Create draft release v2.0.0

The script will:
1. Validate version format
2. Update version in configuration files
3. Create and push git tag
4. Trigger automated build and release workflow
5. Monitor release progress
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prerelease)
                PRERELEASE=true
                shift
                ;;
            --draft)
                DRAFT=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$VERSION" ]]; then
                    VERSION="$1"
                else
                    log_error "Multiple versions specified: $VERSION and $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$VERSION" ]]; then
        log_error "Version is required"
        usage
        exit 1
    fi
}

validate_version() {
    # Support both stable (1.0.0) and pre-release (1.0.0-beta.1) versions
    if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        log_error "Invalid version format: $VERSION"
        log_error "Expected formats:"
        log_error "  - Stable: X.Y.Z (e.g., 1.0.0)"
        log_error "  - Pre-release: X.Y.Z-suffix (e.g., 1.0.0-beta.1)"
        exit 1
    fi
    
    # Auto-detect pre-release from version format
    if [[ $VERSION == *"-"* ]]; then
        PRERELEASE=true
        log_info "Pre-release version detected: $VERSION"
    fi
    
    log_success "Version format valid: $VERSION"
}

validate_environment() {
    log_info "Validating release environment..."
    
    # Check git status
    if ! git diff-index --quiet HEAD --; then
        log_error "Working directory has uncommitted changes"
        log_error "Please commit or stash changes before creating a release"
        exit 1
    fi
    
    # Check if on main branch (for stable releases) or constructor-pkg-installer (for development)
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ "$PRERELEASE" == "false" ]] && [[ "$CURRENT_BRANCH" != "main" ]]; then
        log_warning "Creating stable release from branch: $CURRENT_BRANCH"
        log_warning "Stable releases are typically created from 'main' branch"
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Release cancelled"
            exit 0
        fi
    fi
    
    # Check if tag already exists
    if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
        log_error "Tag v$VERSION already exists"
        log_error "Use a different version or delete the existing tag"
        exit 1
    fi
    
    # Check GitHub CLI
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) is not installed"
        log_error "Install with: brew install gh"
        exit 1
    fi
    
    # Check GitHub authentication
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI is not authenticated"
        log_error "Run: gh auth login"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

update_version_files() {
    log_info "Updating version in configuration files..."
    
    # Update constructor config
    local construct_yaml="$PROJECT_ROOT/MacOS/constructor_installer/python_stack/construct.yaml"
    if [[ -f "$construct_yaml" ]]; then
        # Create backup
        cp "$construct_yaml" "$construct_yaml.bak"
        
        # Update version (remove pre-release suffix for constructor compatibility)
        local constructor_version
        constructor_version=$(echo "$VERSION" | cut -d'-' -f1)
        
        sed -i.tmp "s/version: .*/version: $constructor_version/" "$construct_yaml"
        rm "$construct_yaml.tmp"
        
        log_info "Updated constructor version to: $constructor_version"
    fi
    
    # Update distribution build script
    local build_script="$PROJECT_ROOT/MacOS/constructor_installer/distribution/build_combined.sh"
    if [[ -f "$build_script" ]]; then
        # Create backup
        cp "$build_script" "$build_script.bak"
        
        sed -i.tmp "s/VERSION=\".*\"/VERSION=\"$VERSION\"/" "$build_script"
        rm "$build_script.tmp"
        
        log_info "Updated distribution build version to: $VERSION"
    fi
    
    # Update main implementation plan
    local plan_file="$PROJECT_ROOT/MacOS/constructor_installer/IMPLEMENTATION_PLAN.md"
    if [[ -f "$plan_file" ]]; then
        # Update last updated date
        local today
        today=$(date +%Y-%m-%d)
        sed -i.tmp "s/\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $today/" "$plan_file"
        rm "$plan_file.tmp"
        
        log_info "Updated implementation plan date"
    fi
    
    log_success "Version files updated"
}

create_release_commit() {
    log_info "Creating release commit..."
    
    # Add updated files
    git add -A
    
    # Create release commit
    local commit_message
    if [[ "$PRERELEASE" == "true" ]]; then
        commit_message="release: prepare v$VERSION pre-release"
    else
        commit_message="release: prepare v$VERSION"
    fi
    
    git commit -m "$commit_message

- Update version to $VERSION in configuration files
- Prepare for automated release build and deployment
- Ready for production release pipeline

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    log_success "Release commit created"
}

create_and_push_tag() {
    log_info "Creating and pushing release tag..."
    
    local tag="v$VERSION"
    local tag_message
    
    if [[ "$PRERELEASE" == "true" ]]; then
        tag_message="DTU Python Development Environment v$VERSION (Pre-release)

Pre-release version of the complete DTU Python development environment.
This version may contain experimental features and should be used for testing only.

Built with hybrid constructor + VSCode PKG installer approach."
    else
        tag_message="DTU Python Development Environment v$VERSION

Complete Python development environment for DTU students.
Professional single-click installer with no Homebrew dependency.

Features:
- Python 3.11 with scientific computing stack
- Visual Studio Code with Python extensions
- Professional DTU-branded installer experience
- Enterprise deployment ready

Built with hybrid constructor + VSCode PKG installer approach."
    fi
    
    # Create annotated tag
    git tag -a "$tag" -m "$tag_message"
    
    # Push commit and tag
    git push origin HEAD
    git push origin "$tag"
    
    log_success "Tag $tag created and pushed"
}

trigger_release_workflow() {
    log_info "Triggering automated release workflow..."
    
    # Trigger production release workflow
    gh workflow run "production-release.yml" \
        --field version="$VERSION" \
        --field prerelease="$PRERELEASE" \
        --field draft="$DRAFT"
    
    log_success "Release workflow triggered"
    
    # Wait a moment for workflow to start
    sleep 5
    
    # Show workflow status
    log_info "Monitoring release workflow..."
    gh run list --workflow="production-release.yml" --limit 1
}

monitor_release() {
    log_info "Release v$VERSION initiated!"
    log_info ""
    log_info "=== Release Summary ==="
    log_info "Version: $VERSION"
    log_info "Tag: v$VERSION"
    log_info "Pre-release: $PRERELEASE"
    log_info "Draft: $DRAFT"
    log_info ""
    log_info "The automated release workflow is now building and testing the installer."
    log_info "You can monitor progress at:"
    log_info "https://github.com/$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')/actions"
    log_info ""
    log_info "Once complete, the release will be available at:"
    log_info "https://github.com/$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')/releases/tag/v$VERSION"
}

cleanup_on_error() {
    log_error "Release process failed. Cleaning up..."
    
    # Restore backup files if they exist
    for backup in "$PROJECT_ROOT"/MacOS/constructor_installer/*/*.bak; do
        if [[ -f "$backup" ]]; then
            original="${backup%.bak}"
            mv "$backup" "$original"
            log_info "Restored: $(basename "$original")"
        fi
    done
    
    # Remove tag if it was created
    local tag="v$VERSION"
    if git tag -l "$tag" | grep -q "$tag"; then
        git tag -d "$tag" 2>/dev/null || true
        git push origin --delete "$tag" 2>/dev/null || true
        log_info "Removed tag: $tag"
    fi
    
    # Reset last commit if it was a release commit
    if git log -1 --pretty=format:'%s' | grep -q "release: prepare v$VERSION"; then
        git reset --hard HEAD~1
        log_info "Reset release commit"
    fi
}

main() {
    log_info "DTU Python Development Environment Release Script"
    log_info "================================================="
    
    parse_arguments "$@"
    validate_version
    validate_environment
    
    # Set up error handling
    trap cleanup_on_error ERR
    
    update_version_files
    create_release_commit
    create_and_push_tag
    trigger_release_workflow
    monitor_release
    
    log_success "🎉 Release v$VERSION process completed successfully!"
}

# Run main function
main "$@"