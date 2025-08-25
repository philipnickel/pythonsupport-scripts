# Windows Miniforge Implementation Plan

## Overview
This plan outlines the implementation of a Windows equivalent to the MacOS first year orchestrator that uses Miniforge without Homebrew requirements. The goal is to create a Windows-native installation system that passes all tests in the MacOS_autoInstall.yml workflow.

## Current State Analysis

### MacOS Implementation (Reference)
- **Orchestrator**: `MacOS/Components/orchestrators/first_year_students.sh`
- **Python Component**: Uses Homebrew + Miniconda via `brew install --cask miniconda`
- **VSCode Component**: Uses Homebrew via `brew install --cask visual-studio-code`
- **Dependencies**: Requires `ensure_homebrew()` function

### Windows Current State
- **Components**: Basic structure exists but needs Homebrew-free implementation
- **Orchestrator**: Missing - needs to be created

## Implementation Requirements

### Test Requirements (from MacOS_autoInstall.yml)
1. `code --version` must work
2. `conda --version` must work
3. Python 3.11 with specific packages:
   - dtumathtools
   - pandas
   - scipy
   - statsmodels
   - uncertainties

### Key Dependencies to Remove
1. `ensure_homebrew()` function calls
2. Homebrew-based Miniconda installation
3. Homebrew-based VSCode installation

## Implementation Steps

### Phase 1: Create Windows Components Structure

#### 1.1 Create Windows Shared Utilities
**File**: `Windows/Components/Shared/master_utils.ps1`
- Port MacOS `master_utils.sh` to PowerShell
- Error handling and logging functions
- Environment variable management

#### 1.2 Create Windows Python Component
**File**: `Windows/Components/Python/install.ps1`
- Download Miniforge installer directly from GitHub releases
- Install Miniforge without Homebrew dependency
- Configure conda-forge channel only
- Set up Python 3.11 environment
- Install required packages (dtumathtools, pandas, scipy, statsmodels, uncertainties)

#### 1.3 Create Windows VSCode Component
**File**: `Windows/Components/VSC/install.ps1`
- Download VSCode installer directly from Microsoft
- Install VSCode without Homebrew dependency
- Configure CLI access (`code` command)
- Install Python extension
- Set up development environment

#### 1.4 Create Windows First Year Setup
**File**: `Windows/Components/Python/first_year_setup.ps1`
- Configure Python 3.11 environment
- Install DTU-specific packages
- Set up Jupyter kernels
- Configure development tools

### Phase 2: Create Windows Orchestrator

#### 2.1 Create Windows First Year Orchestrator
**File**: `Windows/Components/orchestrators/first_year_students.ps1`
- Orchestrate Python installation
- Orchestrate VSCode installation
- Run first year setup
- Install VSCode extensions
- Provide user feedback and error handling

### Phase 3: Update Dependencies System

#### 3.1 Create Windows Dependencies Module
**File**: `Windows/Components/Shared/dependencies.ps1`
- Remove Homebrew dependency checks
- Add Windows-specific dependency validation
- PowerShell version checks
- .NET Framework validation
- Windows version compatibility

### Phase 4: Testing and Validation

#### 4.1 Create Windows AutoInstall Workflow
**File**: `.github/workflows/Windows_autoInstall.yml`
- Mirror MacOS_autoInstall.yml structure
- Test Windows orchestrator
- Validate all requirements
- Test legacy installation

#### 4.2 Update Cross-Platform Workflow
**File**: `.github/workflows/MacOS_autoInstall.yml`
- Rename to `CrossPlatform_autoInstall.yml`
- Add Windows job alongside MacOS jobs
- Ensure both platforms pass all tests

## Technical Implementation Details

### Miniforge Installation Strategy
```powershell
# Download Miniforge installer
$miniforge_url = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe"
$installer_path = "$env:TEMP\Miniforge3-Windows-x86_64.exe"

# Install silently
Start-Process -FilePath $installer_path -ArgumentList "/S" -Wait

# Configure conda-forge only
conda config --remove-key channels 2>$null
conda config --add channels conda-forge
conda config --set channel_priority strict
```

### VSCode Installation Strategy
```powershell
# Download VSCode installer
$vscode_url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
$installer_path = "$env:TEMP\VSCodeUserSetup-x64.exe"

# Install silently
Start-Process -FilePath $installer_path -ArgumentList "/VERYSILENT /NORESTART" -Wait

# Add to PATH
$env:PATH += ";$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
```

### Environment Configuration
- Use Windows-native environment variables
- Configure PowerShell profiles for persistent PATH
- Set up conda initialization for PowerShell
- Configure VSCode CLI access

## File Structure

```
Windows/
├── Components/
│   ├── Shared/
│   │   ├── master_utils.ps1
│   │   ├── dependencies.ps1
│   │   └── error_handling.ps1
│   ├── Python/
│   │   ├── install.ps1
│   │   ├── first_year_setup.ps1
│   │   └── uninstall.ps1
│   ├── VSC/
│   │   ├── install.ps1
│   │   ├── install_extensions.ps1
│   │   └── uninstall.ps1
│   └── orchestrators/
│       └── first_year_students.ps1
└── AutoInstall.ps1
```

## Testing Strategy

### Local Testing
1. Test each component individually
2. Test orchestrator end-to-end
3. Validate all requirements are met
4. Test error handling scenarios

### CI/CD Testing
1. Create PR to trigger GitHub Actions
2. Monitor Windows_autoInstall.yml workflow
3. Ensure all tests pass:
   - Orchestrator test
4. Validate cross-platform compatibility

### Test Validation Points
- [ ] `code --version` returns valid version
- [ ] `conda --version` returns valid version
- [ ] Python 3.11 is installed and accessible
- [ ] All required packages import successfully
- [ ] VSCode Python extension is installed
- [ ] Development environment is properly configured

## Success Criteria

### Functional Requirements
- [ ] Windows orchestrator installs Python 3.11 with Miniforge
- [ ] Windows orchestrator installs VSCode without Homebrew
- [ ] All required Python packages are available
- [ ] VSCode CLI (`code` command) works
- [ ] Conda environment is properly configured

### Quality Requirements
- [ ] All MacOS_autoInstall.yml tests pass
- [ ] Error handling is robust
- [ ] User feedback is clear and helpful
- [ ] Installation is idempotent (safe to run multiple times)

### Performance Requirements
- [ ] Installation completes within reasonable time
- [ ] Minimal user interaction required
- [ ] Silent installation where possible
- [ ] Proper cleanup on failure

## Risk Mitigation

### Technical Risks
- **PowerShell Execution Policy**: Ensure scripts can run with appropriate execution policy
- **Network Connectivity**: Handle download failures gracefully
- **Permission Issues**: Handle admin vs user installation scenarios
- **Antivirus Interference**: Test with common antivirus software

### Compatibility Risks
- **Windows Version**: Test on Windows 10 and 11
- **PowerShell Version**: Ensure compatibility with PowerShell 5.1+
- **Architecture**: Support both x64 and ARM64 if needed

## Timeline

### Week 1: Foundation
- [ ] Create Windows shared utilities
- [ ] Implement Miniforge installation component
- [ ] Basic testing and validation

### Week 2: Components
- [ ] Implement VSCode installation component
- [ ] Create first year setup component
- [ ] Build orchestrator framework

### Week 3: Integration
- [ ] Complete orchestrator implementation
- [ ] Create Windows AutoInstall workflow
- [ ] Integration testing

### Week 4: Validation
- [ ] Create PR and test through GitHub Actions
- [ ] Fix any issues found
- [ ] Final validation and documentation

## Next Steps

1. **Immediate**: Start with Phase 1.1 (Windows Shared Utilities)
2. **Parallel**: Begin Miniforge installation research and testing
3. **Validation**: Set up local Windows testing environment
4. **CI/CD**: Prepare GitHub Actions workflow structure

## Notes

- All PowerShell scripts should follow Windows best practices
- Use Windows-native installation methods where possible
- Maintain compatibility with existing MacOS implementation
- Ensure proper error handling and user feedback
- Include comprehensive logging for debugging
- Follow security best practices for Windows environments
