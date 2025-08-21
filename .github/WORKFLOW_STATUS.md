# GitHub Workflows Status During PKG Development

## Overview

During PKG installer development, most GitHub Actions workflows have been temporarily disabled to avoid interference and reduce CI resource usage. Only `mac_orchestrators.yml` remains enabled to catch regressions in existing functionality.

## Current Status

| Workflow File | Status | Reason |
|---------------|--------|--------|
| `mac_orchestrators.yml` | ✅ **ENABLED** | Essential for catching regressions in existing functionality |
| `docs.yml` | ❌ **DISABLED** | Documentation deployment not needed during development |
| `generate_docs.yml` | ❌ **DISABLED** | Documentation generation not needed during development |
| `install_mac.yml` | ❌ **DISABLED** | Legacy workflow superseded by orchestrators |
| `install_windows.yml` | ❌ **DISABLED** | Not relevant for current PKG development |
| `mac_components.yml` | ❌ **DISABLED** | Comprehensive component testing not needed during active development |
| `test-pkg-installer.yml` | ❌ **DISABLED** | PKG installer testing disabled during development iteration |

## How Workflows Were Disabled

Each disabled workflow has `if: false` conditions added to their job definitions with explanatory comments:

```yaml
jobs:
  job-name:
    # Temporarily disabled during PKG development - only mac_orchestrators.yml should run
    # TO RE-ENABLE: Change "if: false" back to "if: true" or remove the line entirely
    if: false
    runs-on: ubuntu-latest
    # ... rest of job configuration
```

## Re-enabling Workflows

When PKG development is complete, re-enable workflows by:

1. **Option 1 (Recommended):** Remove the `if: false` lines entirely
2. **Option 2:** Change `if: false` to `if: true`

### Batch Re-enabling Script

You can use this command to re-enable all workflows at once:

```bash
# Remove all "if: false" lines added during PKG development
find .github/workflows -name "*.yml" -exec sed -i '' '/^[[:space:]]*if: false$/d' {} \;

# Remove associated comment lines
find .github/workflows -name "*.yml" -exec sed -i '' '/# Temporarily disabled during PKG development/d' {} \;
find .github/workflows -name "*.yml" -exec sed -i '' '/# TO RE-ENABLE: Change "if: false"/d' {} \;
```

## Testing Strategy During Development

- **mac_orchestrators.yml**: Continues to run on PR changes to `MacOS/Components/**` to ensure no regressions
- **Other workflows**: Disabled to focus CI resources on essential regression testing
- **Manual testing**: PKG installer and components should be tested locally during development

## When to Re-enable

Re-enable all workflows when:
- PKG installer development is complete
- Ready for comprehensive testing across all components
- Preparing for production release
- No longer actively iterating on PKG installer changes

---

**Last Updated:** $(date)
**Disabled By:** Development team during PKG installer iteration
**Next Review:** When PKG development phase is complete