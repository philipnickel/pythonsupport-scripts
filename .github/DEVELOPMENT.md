# Development Workflow

This document outlines the development workflow for the Python Support Scripts repository.

## Branch Structure

- **`main`** - Production-ready code, stable releases
- **`dev`** - Development branch, integration testing
- **`feature/*`** - Feature branches for new components or major changes

## Development Process

### 1. Working on Features

```bash
# Start from dev branch
git checkout dev
git pull origin dev

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes, commit frequently
git add .
git commit -m "Descriptive commit message"

# Push feature branch
git push origin feature/your-feature-name
```

### 2. Testing

All changes are automatically tested via GitHub Actions:

- **Component Tests**: Individual testing of each MacOS component
- **Integration Tests**: Full end-to-end installation testing
- **Validation**: Shell script linting, YAML validation, documentation checks

### 3. Pull Requests

Create PRs targeting the `dev` branch:

```bash
gh pr create --base dev --title "Feature: Add new component" --body "Description of changes"
```

## GitHub Actions Workflows

### Mac Components Tests (`mac_components.yml`)

**Triggers:**
- Pull requests to `main`/`dev`
- Pushes to `dev` branch
- Manual dispatch with branch selection
- Weekly scheduled runs (Sundays 2 AM UTC)

**Features:**
- Tests all components on `macos-latest` with Python 3.11
- Supports testing from any branch or fork
- Clear logging of which repository/branch is being tested
- Manual trigger allows testing specific branches

**Jobs:**
- `test-homebrew` - Homebrew installation
- `test-python` - Python/Miniconda + first year setup
- `test-vscode` - VS Code + extensions
- `test-latex` - LaTeX dependencies
- `test-diagnostics` - System diagnostics (requires other components)
- `test-integration` - Full component chain installation

### Code Validation (`validation.yml`)

**Triggers:**
- All pull requests
- Pushes to `main`/`dev`
- Manual dispatch

**Checks:**
- Shell script validation with shellcheck
- Script file permissions
- GitHub Actions workflow YAML syntax
- Component documentation completeness

## Component Development Guidelines

### Adding a New Component

1. Create directory: `MacOS/Components/YourComponent/`
2. Add `install.sh` script with:
   - Error handling using shared utilities
   - Consistent logging format (`_prefix="PYS:"`)
   - Proper environment variable support
   - Installation verification

3. Update documentation in `docs/macos/components.md`
4. Test thoroughly using the GitHub Actions workflow

### Component Script Standards

```bash
#!/bin/bash

_prefix="PYS:"

# Environment variable defaults
if [ -z "$REMOTE_PS" ]; then
  REMOTE_PS="dtudk/pythonsupport-scripts"
fi
if [ -z "$BRANCH_PS" ]; then
  BRANCH_PS="main"
fi

export REMOTE_PS BRANCH_PS

# Use shared utilities for error handling
exit_message() {
    echo ""
    echo "Oh no! Something went wrong"
    echo ""
    echo "Please visit: https://pythonsupport.dtu.dk/install/macos/automated-error.html"
    echo "or contact: pythonsupport@dtu.dk"
    exit 1
}

# Main installation logic
echo "$_prefix Installing YourComponent..."

# Installation steps with error checking
command_that_might_fail
[ $? -ne 0 ] && exit_message

echo "$_prefix YourComponent installation completed!"
```

## Manual Testing

### Test Specific Branch
```bash
# Via GitHub UI: Actions → Mac Components Tests → Run workflow → Select branch
# Or via CLI:
gh workflow run mac_components.yml --ref your-branch-name
```

### Local Testing
```bash
# Test individual component
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/pythonsupport-scripts/YOUR_BRANCH/MacOS/Components/Homebrew/install.sh)"

# Test diagnostics
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/pythonsupport-scripts/YOUR_BRANCH/MacOS/Components/Diagnostics/run.sh)"
```

## Best Practices

1. **Small, focused commits** with clear messages
2. **Test before pushing** - use the manual workflow dispatch
3. **Keep documentation updated** - especially `docs/macos/components.md`
4. **Follow existing patterns** - consistent error handling, logging, etc.
5. **Clean branch management** - delete merged feature branches

## Troubleshooting

### Workflow Issues
- Check Actions tab for detailed logs
- Ensure component scripts are executable (`chmod +x`)
- Verify YAML syntax in workflow files

### Component Issues
- Test scripts locally first
- Check error handling and exit codes
- Ensure proper environment variable usage
- Verify dependency installation order