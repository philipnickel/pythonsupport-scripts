# MacOS Diagnostics Tool Modernization Plan

## Overview

This document outlines the plan to modernize the MacOS Components Diagnostics tool to be more modular, maintainable, and aligned with specific testing needs (First Year Environment vs Comprehensive Environment).

## Current State Analysis

### Existing Structure
```
MacOS/Components/Diagnostics/
├── generate_report.sh           # Monolithic script with hardcoded components
├── report_config.sh            # Configuration file
└── Components/                 # Individual diagnostic scripts
    ├── Conda/
    ├── Development/
    ├── Python/
    ├── System Information/
    └── Visual Studio Code/
```

### Current Issues
1. **Hardcoded Components**: Component definitions are embedded in `generate_report.sh` (lines 97-108)
2. **No Test Profiles**: Single comprehensive test suite, no targeted testing
3. **Maintenance Burden**: Adding/removing tests requires script modification
4. **User Confusion**: No clear distinction between essential vs comprehensive tests

## Proposed Modular Architecture

### New Directory Structure
```
MacOS/Components/Diagnostics/
├── profiles/
│   ├── first_year.conf          # First year essentials only
│   ├── comprehensive.conf       # All available tests
│   └── custom.conf.template     # Template for custom profiles
├── templates/
│   ├── base.html               # Main HTML template with placeholders
│   ├── styles.css              # Separate CSS file for easier editing
│   └── scripts.js              # Separate JavaScript file
├── generate_report.sh           # Enhanced main generator (profile-aware)
├── report_config.sh            # Global configuration
└── Components/                 # Individual diagnostic scripts (unchanged)
```

## Implementation Plan

### Phase 1: Profile System and Templates Creation

#### 1.1 Create Profile Configuration Files

**First Year Profile** (`profiles/first_year.conf`):
- Matches tests from `mac_orchestrators.yml`
- Essential components only:
  - Python Installation Check
  - First Year Required Packages
  - Conda Installation Check
  - VS Code Installation Check
  - Python Development Extensions

**Comprehensive Profile** (`profiles/comprehensive.conf`):
- All current diagnostic components
- Maintains existing functionality
- Serves as default fallback

#### 1.2 Profile Configuration Format
```bash
# Profile metadata
PROFILE_NAME="Profile Display Name"
PROFILE_DESCRIPTION="Detailed description of what this profile tests"

# Component definitions
# Format: "Category:Subcategory:script_name:Display Name:repo_path"
COMPONENTS=(
    "Python:Installation:python_installation_check:Python Installation Check:Components/Python/Installation/python_installation_check.sh"
    "Conda:Installation:conda_installation:Conda Installation Check:Components/Conda/Installation/conda_installation.sh"
    # ... more components
)
```

#### 1.3 Create HTML Template System

**Base HTML Template** (`templates/base.html`):
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DTU Python Diagnostics Report - {{PROFILE_NAME}}</title>
    <style>{{CSS_CONTENT}}</style>
</head>
<body>
    <div class="container">
        <header>
            <h1>DTU Python Diagnostics Report</h1>
            <div class="profile-info">
                <h2>{{PROFILE_NAME}}</h2>
                <p>{{PROFILE_DESCRIPTION}}</p>
            </div>
            <div class="timestamp">Generated on: {{TIMESTAMP}}</div>
        </header>
        
        <div class="summary">
            {{SUMMARY_HTML}}
        </div>
        
        <div class="diagnostics" id="diagnostics-container">
            <!-- Diagnostic items will be populated by JavaScript -->
        </div>
        
        <footer>
            <p><strong>DTU Python Support</strong></p>
            <p>Technical University of Denmark</p>
        </footer>
    </div>
    
    <script>
        const diagnosticData = {{DIAGNOSTIC_DATA}};
        const profileInfo = {
            name: "{{PROFILE_NAME}}",
            description: "{{PROFILE_DESCRIPTION}}"
        };
        {{JS_CONTENT}}
    </script>
</body>
</html>
```

**Separate CSS File** (`templates/styles.css`):
- All CSS styling extracted from current script
- Easy to edit without touching shell code
- Consistent DTU branding and color scheme

**Separate JavaScript File** (`templates/scripts.js`):
- All JavaScript functionality extracted
- Report generation, interaction, and download features
- Clean separation of concerns

### Phase 2: Enhanced Main Script

#### 2.1 Command Line Interface
```bash
# New usage patterns
./generate_report.sh --profile first_year
./generate_report.sh --profile comprehensive
./generate_report.sh --profile custom
./generate_report.sh                    # Default: comprehensive (backward compatible)

# Remote execution examples
curl -fsSL https://raw.githubusercontent.com/.../generate_report.sh | bash -s -- --profile first_year
curl -fsSL https://raw.githubusercontent.com/.../generate_report.sh | bash -s -- --profile comprehensive
```

#### 2.2 Profile Loading Logic
- Replace hardcoded component definitions
- Load profile from configuration file
- Validate profile exists and is readable
- Graceful fallback to comprehensive profile

#### 2.3 Template-Based HTML Generation
- Load HTML template from `templates/base.html`
- Replace placeholders with dynamic content (profile info, test results, etc.)
- Support for separate CSS and JavaScript files
- Easy visual customization without touching shell script
- Template variables for profile-specific content

#### 2.4 Template System Features
```bash
# Template placeholders (examples)
{{PROFILE_NAME}}           # Profile display name
{{PROFILE_DESCRIPTION}}    # Profile description
{{TIMESTAMP}}             # Report generation time
{{SUMMARY_DATA}}          # Pass/fail/timeout counts
{{DIAGNOSTIC_DATA}}       # JSON data for test results
{{CSS_CONTENT}}           # Inline CSS from templates/styles.css
{{JS_CONTENT}}            # Inline JavaScript from templates/scripts.js
```

### Phase 3: Documentation and Integration

#### 3.1 Usage Documentation
- Update README with new --profile parameter usage
- Document available profiles and their purposes
- Provide examples for both local and remote execution

#### 3.2 Integration Updates
- Update orchestrator scripts to use profile parameter
- Update any existing references to use new parameter system

## Detailed Component Mapping

### First Year Environment Components
Based on `mac_orchestrators.yml` requirements:

| Component | Purpose | Maps to Test |
|-----------|---------|--------------|
| Python Installation Check | Verify Python 3.11 is installed | `which python3` + version check |
| First Year Required Packages | Import test for required packages | `import dtumathtools, pandas, scipy, statsmodels, uncertainties` |
| Conda Installation Check | Verify conda is available | `which conda` + `conda --version` |
| VS Code Installation Check | Verify VS Code is installed | `code --version` |
| Python Development Extensions | Check VS Code Python extensions | Extension verification |

### Comprehensive Environment Components
All existing components plus any future additions:
- All First Year components
- Homebrew installation check
- System information gathering
- Python environment configuration
- Conda environments check

## Benefits of Proposed Architecture

### 1. Maintainability
- **Separation of Concerns**: Test definitions separated from execution logic
- **Easy Updates**: Add/remove tests by editing configuration files
- **Version Control**: Profile changes are clearly tracked
- **Documentation**: Self-documenting profile configurations

### 2. Flexibility
- **Custom Profiles**: Users can create custom test suites
- **Targeted Testing**: Run only relevant tests for specific scenarios
- **Easy Extension**: New profiles for different user groups (advanced, research, etc.)

### 3. Visual Customization
- **Template-Based HTML**: Easy to modify report appearance
- **Separate CSS**: Quick styling changes without touching shell code
- **Modular JavaScript**: Clean interaction and functionality updates
- **Profile-Specific Branding**: Different visual themes per profile

### 4. User Experience
- **Clear Purpose**: Distinct first year vs comprehensive options
- **Consistent Interface**: Same reporting format regardless of profile
- **Remote Friendly**: Easy curl-based execution with profile parameters
- **Backward Compatible**: Existing usage patterns continue to work

### 5. Alignment with CI/CD
- **CI Integration**: First year profile matches GitHub Actions tests
- **Consistent Testing**: Same tests in CI and user diagnostics
- **Reliable Validation**: Proven test components from orchestrator

## Migration Strategy

### Phase 1: Implementation (No Breaking Changes)
1. Create new directory structure including `templates/` folder
2. Create profile configuration files  
3. Extract current HTML/CSS/JS into separate template files
4. Enhance main script with profile support, parameter parsing, and template processing
5. Test thoroughly with existing functionality

### Phase 2: Documentation and Adoption
1. Update README with new --profile parameter usage
2. Update orchestrator scripts to use profile parameter
3. Communicate changes to users

### Phase 3: Cleanup (Optional)
1. Consider deprecating old usage patterns (after sufficient adoption)
2. Remove redundant code paths

## Implementation Timeline

- **Week 1**: Create profile configurations, directory structure, and HTML templates
- **Week 2**: Extract current HTML/CSS/JS into template files  
- **Week 3**: Enhance main script with profile loading, parameter parsing, and template processing
- **Week 4**: Test thoroughly with both profiles and update documentation

## Testing Strategy

### Unit Testing
- Profile loading and validation
- Component discovery from profiles
- Template loading and placeholder replacement
- Error handling for missing/invalid profiles or templates

### Integration Testing
- First year profile matches orchestrator tests exactly
- Comprehensive profile maintains existing functionality
- Remote execution works correctly
- HTML report generation functions properly

### Regression Testing
- Existing usage patterns continue to work
- All current diagnostic components still function
- Report format remains consistent

## Future Enhancements

### Potential Extensions
- **Interactive Profile Selection**: CLI menu for profile selection
- **Profile Composition**: Ability to combine multiple profiles
- **Conditional Components**: Components that run based on system state
- **Performance Profiles**: Fast vs thorough testing modes
- **Profile-Specific Templates**: Different visual themes per profile
- **Template Customization**: User-configurable template overrides

### Advanced Features
- **Parallel Execution Optimization**: Profile-aware parallelization
- **Dependency Management**: Component prerequisites and ordering
- **Result Caching**: Cache component results for faster reruns
- **Notification Integration**: Email/Slack notifications for CI results

This modernization plan provides a clear path forward while maintaining backward compatibility and improving the overall user experience and maintainability of the diagnostics system.