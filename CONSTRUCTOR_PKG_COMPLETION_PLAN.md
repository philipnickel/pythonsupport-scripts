# Constructor PKG Installer - Completion Plan

## Overview
Complete the constructor-based PKG installer implementation for DTU Python Development Environment, replacing the current Homebrew-dependent approach with a professional, self-contained installer.



## Phase 1: Core Constructor PKG Validation ⏱️ **IN PROGRESS**

### 1.1 Verify Current Workflow
- [ ] Confirm constructor PKG builds and installs correctly
- [ ] Validate all Python packages import properly (pandas, scipy, statsmodels, uncertainties, dtumathtools)
- [ ] Test conda environment activation and shell integration
- [ ] Ensure PKG works on both Intel and Apple Silicon Macs

### 1.2 Fix Any Remaining Issues
- [ ] Address any test failures in current PR
- [ ] Optimize build time and package size
- [ ] Validate installer works without internet connection

## Phase 2: Enhanced Post-Install Script 🎯 **NEXT**

### 2.1 Comprehensive Post-Install Script
- [ ] Update `post_install.sh` to download and install VS Code from Microsoft
- [ ] Install VS Code Python extensions programmatically
- [ ] Set up VS Code CLI tools (`code` command) in PATH
- [ ] Run diagnostics system as final step (`generate_report.sh`)

### 2.2 Constructor Configuration Updates
- [ ] Add `post_install_desc` to construct.yaml for user-friendly description
- [ ] Ensure post-install script handles both GUI and CLI installations
- [ ] Test script works with `CurrentUserHomeDirectory` target
- [ ] Verify all components install correctly in single PKG

### 2.3 Simplified Workflow Testing
- [ ] Remove complex distribution build steps from workflow
- [ ] Test single constructor PKG with enhanced post-install
- [ ] Verify Python + VS Code + Extensions + Diagnostics all work
- [ ] Update artifact upload to use single PKG


## Phase 3: Production Ready 📦 **AFTER PHASE 2**

### 3.1 Release Automation
- [ ] Restore GitHub release creation when tests pass
- [ ] Generate proper semantic versioning (v2024.MM.DD-SHA)
- [ ] Upload unified PKG as release artifact
- [ ] Create comprehensive release notes

### 3.2 Code Signing Preparation
- [ ] Document code signing requirements in `docs/`
- [ ] Prepare template workflow for Apple Developer Program integration
- [ ] Test unsigned installer distribution methods

### 3.3 Documentation and Cleanup
- [ ] Update main README to document new installer approach
- [ ] Create user installation guide
- [ ] Document troubleshooting steps
- [ ] Clean up any remaining legacy files

## Phase 4: Windows Implementation 🪟 **PARALLEL TO PHASE 3**

### 4.1 Windows Constructor Setup
- [ ] Create Windows construct.yaml (.exe installer type)
- [ ] Adapt Python 3.11 + scientific packages for Windows
- [ ] Test conda constructor on Windows environment

### 4.2 Windows Post-Install Script
- [ ] Create `post_install.bat` for Windows (.bat file required)
- [ ] Download and install VS Code for Windows from Microsoft
- [ ] Install VS Code Python extensions on Windows
- [ ] Set up VS Code CLI tools in Windows PATH
- [ ] Run Windows diagnostics (PowerShell equivalent of generate_report.sh)

### 4.3 Windows CI/CD Integration
- [ ] Add Windows runners to GitHub Actions workflow
- [ ] Create `test-windows-constructor` job using single PKG approach
- [ ] Test Windows installer (.exe) on different Windows versions
- [ ] Parallel testing: macOS and Windows installers

### 4.4 Cross-Platform Consistency
- [ ] Ensure same Python packages on both platforms
- [ ] Consistent VS Code extensions across platforms
- [ ] Unified post-install experience (download + install + verify)
- [ ] Cross-platform diagnostics reports with same format

## Phase 5: Deployment Strategy 🚀 **FINAL**

### 5.1 Migration Plan
- [ ] A/B testing: Compare constructor vs current installer success rates
- [ ] Performance benchmarks: Installation time, reliability, user experience
- [ ] Rollback strategy if issues discovered
- [ ] Test both macOS and Windows installer adoption

### 5.2 User Communication
- [ ] Announce new installer availability for both platforms
- [ ] Provide migration instructions for existing users
- [ ] Set up support channels for new installer issues
- [ ] Platform-specific installation guides

### 5.3 Monitoring and Maintenance
- [ ] Set up telemetry for installation success rates (macOS + Windows)
- [ ] Monitor GitHub issues for installer problems
- [ ] Plan regular updates for Python/package versions
- [ ] Cross-platform compatibility testing schedule

## Success Criteria

### Technical Requirements

#### macOS
- [ ] ✅ Constructor PKG installs Python 3.11 + all required packages
- [ ] ❌ Single PKG with post-install script handles VS Code + extensions + diagnostics
- [ ] ❌ All three installation methods work: constructor, orchestrator, legacy
- [ ] ❌ Compatible with macOS 10.15+ (Intel + Apple Silicon)

#### Windows  
- [ ] ❌ Constructor .exe installs Python 3.11 + packages
- [ ] ❌ Single .exe with post-install script handles VS Code + extensions + diagnostics
- [ ] ❌ Compatible with Windows 10+ (x64 architecture)

#### Cross-Platform
- [ ] ❌ Automatic GitHub releases for both platforms
- [ ] ❌ Python packages work offline (VS Code downloaded during post-install)
- [ ] ❌ Consistent package versions and post-install experience across platforms

### User Experience
- [ ] ❌ Single-click installation (PKG on macOS, .exe/.msi on Windows)
- [ ] ❌ Professional installer UI with DTU branding on both platforms
- [ ] ❌ Clear installation progress and error messages
- [ ] ❌ No Homebrew dependency (macOS) / No Chocolatey dependency (Windows)
- [ ] ❌ Faster installation: <3 minutes vs current 5-10 minutes (both platforms)

### Reliability
- [ ] ❌ >95% installation success rate in testing (both platforms)
- [ ] ❌ Consistent environment setup every time
- [ ] ❌ No conflicts with existing Python installations (macOS + Windows)
- [ ] ❌ Proper error handling and user feedback on both platforms

## Risk Mitigation

### High Priority Risks
1. **Constructor PKG fails in production**: Have rollback to current system (both platforms)
2. **Post-install script fails**: VS Code download/install issues, network problems
3. **macOS/Windows compatibility problems**: Test on multiple OS versions  
4. **Code signing roadblocks**: Plan unsigned distribution strategy
5. **Network dependency**: VS Code download requires internet during installation

### Contingency Plans
- Keep existing installers as fallback (Homebrew on macOS, PowerShell on Windows)
- Implement gradual rollout (opt-in initially, by platform)
- Monitor installation metrics closely on both platforms
- Quick revert capability if needed
- Platform-specific rollback strategies

## Key Decision Points

### Immediate (Phase 1)
- ❓ Should we focus on constructor-only PKG or push for unified distribution?
- ❓ How to handle existing conda installations during testing?

### Upcoming (Phase 2)  
- ❓ System-wide vs user-specific VS Code installation (both platforms)?
- ❓ Which VS Code extensions to pre-install?
- ❓ Code signing: Apple Developer Program + Windows code signing certificates worth the cost?

### Future (Phase 4-5)
- ❓ Windows implementation priority: .exe vs .msi installer format?
- ❓ Cross-platform testing strategy and CI/CD setup?
- ❓ Timeline for deprecating old installers on both platforms?
- ❓ Platform-specific support strategy for installation issues?

---

## Automated Execution Checklist

This plan serves as a comprehensive checklist for automated implementation. Each phase should be completed sequentially with all checkboxes validated before proceeding to the next phase.

**Current Status**: Phase 1 in progress - constructor PKG testing