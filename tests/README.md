# Piwik Analytics Testing Tools

This directory contains comprehensive testing tools for the enhanced Piwik analytics utility.

## Files

### `piwik_simulator.sh`
A comprehensive test simulator that validates all features of the enhanced Piwik utility.

**Features:**
- Environment detection testing (PROD, DEV, CI, STAGING)
- Connection testing
- Basic and enhanced functionality testing
- Error categorization testing
- Performance timing testing
- System information collection testing

**Usage:**
```bash
# Test with default environment (DEV)
./tests/piwik_simulator.sh

# Test with specific environment
./tests/piwik_simulator.sh PROD
./tests/piwik_simulator.sh DEV
./tests/piwik_simulator.sh CI
./tests/piwik_simulator.sh STAGING

# Show help
./tests/piwik_simulator.sh --help
```

### `piwik_example.sh`
A practical example script demonstrating how to integrate Piwik tracking into real installation scenarios.

**Features:**
- Real-world usage examples
- Environment simulation
- Error handling demonstrations
- Performance monitoring examples
- Integration patterns

**Usage:**
```bash
# Run with default environment (DEV)
./tests/piwik_example.sh

# Run with specific environment
./tests/piwik_example.sh PROD
./tests/piwik_example.sh CI
./tests/piwik_example.sh STAGING
```

## Environment Variables

The enhanced Piwik utility automatically detects the environment based on these variables:

### Production Environment
- No special environment variables set
- Category: `Installer_PROD`

### Development Environment
- `TESTING_MODE=true`
- `DEV_MODE=true`
- `DEBUG=true`
- Category: `Installer_DEV`

### CI/CD Environment
- `GITHUB_CI=true`
- `CI=true`
- `TRAVIS=true`
- `CIRCLECI=true`
- Category: `Installer_CI`

### Staging Environment
- `STAGING=true`
- `STAGE=true`
- Category: `Installer_STAGING`

## Enhanced Features

### 1. Environment Detection
The utility automatically detects the environment and sets appropriate Piwik categories:
- `Installer_PROD` - Production installations
- `Installer_DEV` - Development/testing installations
- `Installer_CI` - CI/CD pipeline installations
- `Installer_STAGING` - Staging environment installations

### 2. Timing and Performance
The enhanced `piwik_log_enhanced` function tracks execution time:
```bash
# Basic usage (no timing)
piwik_log "event_name" command

# Enhanced usage (with timing)
piwik_log_enhanced "event_name" command
```

### 3. Error Categorization
Automatic error categorization based on error patterns:
- `_permission_error` - Permission denied errors
- `_network_error` - Network/download errors
- `_disk_error` - Disk space errors
- `_missing_dependency` - Missing command/file errors
- `_already_exists` - Already exists errors
- `_version_error` - Version compatibility errors
- `_unknown_error` - Other errors

### 4. Utility Functions
Additional utility functions for debugging and monitoring:
```bash
# Get environment information
piwik_get_environment_info

# Test Piwik connection
piwik_test_connection
```

## Testing Workflow

### 1. Run the Simulator
```bash
# Test all features
./tests/piwik_simulator.sh DEV
```

### 2. Check Results
The simulator provides detailed output with:
- ✅ Pass indicators for successful tests
- ❌ Fail indicators for failed tests
- ⚠️ Warning indicators for potential issues
- ℹ️ Info indicators for informational messages

### 3. Review Example Usage
```bash
# See practical examples
./tests/piwik_example.sh DEV
```

### 4. Integration Testing
Test the utility in your actual installation scripts:
```bash
# Source the utility
source "MacOS/Components/Shared/piwik_utility.sh"

# Set environment
export TESTING_MODE=true

# Use in your scripts
piwik_log "component_install" install_command
piwik_log_enhanced "component_install_timed" install_command
```

## Expected Test Results

### Successful Test Run
```
==========================================
    Piwik Analytics Test Simulator
==========================================
Environment: DEV
Utility Script: /path/to/piwik_utility.sh
Date: [timestamp]

🧪 Testing Environment Detection
----------------------------------------
✅ PASS: Environment detection for PROD: PROD -> Installer_PROD
✅ PASS: Environment detection for DEV: DEV -> Installer_DEV
✅ PASS: Environment detection for CI: CI -> Installer_CI
✅ PASS: Environment detection for STAGING: STAGING -> Installer_STAGING

🌐 Testing Piwik Connection
----------------------------------------
✅ Piwik connection successful (HTTP 200)
✅ PASS: Piwik connection successful

[... more test results ...]

==========================================
              Test Summary
==========================================
Total Tests: 15
Passed: 15
Failed: 0
🎉 All tests passed!
```

### Failed Test Run
If tests fail, check:
1. Internet connectivity
2. Piwik PRO service availability
3. Correct Site ID configuration
4. Environment variable settings

## Troubleshooting

### Connection Issues
```bash
# Test connection manually
curl -s -w "%{http_code}" -o /dev/null -G "https://pythonsupport.piwik.pro/ppms.php" \
  --data-urlencode "idsite=0bc7bce7-fb4d-4159-a809-e6bab2b3a431" \
  --data-urlencode "rec=1"
```

### Environment Detection Issues
```bash
# Check current environment
piwik_get_environment_info
```

### Permission Issues
```bash
# Make scripts executable
chmod +x tests/piwik_simulator.sh
chmod +x tests/piwik_example.sh
```

## Integration with CI/CD

For CI/CD pipelines, set the appropriate environment variables:

```yaml
# GitHub Actions example
env:
  GITHUB_CI: true
  CI: true

# GitLab CI example
variables:
  CI: "true"
```

## Next Steps

1. **Run the simulator** to validate all features
2. **Review the example** to understand integration patterns
3. **Integrate into your scripts** using the enhanced utility
4. **Set up Piwik PRO dashboards** as outlined in the setup guide
5. **Configure alerts and monitoring** for production use

For more information, see the main [Piwik Setup Guide](../piwik_setup_guide.md).
