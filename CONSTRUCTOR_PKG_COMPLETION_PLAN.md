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

## Phase 2: VS Code Integration 🎯 **NEXT**

### 2.1 Complete VS Code PKG Component
- [ ] Test `MacOS/constructor_installer/vscode_component/build_vscode_pkg.sh`
- [ ] Ensure VS Code downloads correctly from Microsoft
- [ ] Verify Python extensions install properly
- [ ] Test VS Code CLI tools availability (`code` command)

### 2.2 Unified Distribution PKG
- [ ] Fix `MacOS/constructor_installer/distribution/Distribution.xml` JavaScript issues
- [ ] Test combined installer with both Python and VS Code
- [ ] Ensure proper RTF documentation displays during installation
- [ ] Validate system-wide installation with `sudo installer`

### 2.3 Post-Installation Diagnostics
- [ ] Integrate diagnostics system as final installation step
- [ ] Run `MacOS/Components/Diagnostics/generate_report.sh` after installation
- [ ] Verify all components installed correctly (Python, VS Code, packages)
- [ ] Generate installation report for user and troubleshooting

### 2.4 Update Workflow for Unified Testing
- [ ] Restore unified distribution build steps in workflow
- [ ] Test complete installation: Python + VS Code + Extensions + Diagnostics
- [ ] Ensure all three test jobs pass: constructor, orchestrator, legacy


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

### 4.1 Windows Constructor PKG
- [ ] Research conda constructor for Windows (.exe/.msi installers)
- [ ] Adapt construct.yaml for Windows environment
- [ ] Test Python 3.11 + scientific packages on Windows
- [ ] Implement Windows-specific post-install scripts

### 4.2 Windows VS Code Integration
- [ ] Create Windows VS Code installer component
- [ ] Download VS Code for Windows from Microsoft
- [ ] Handle Windows-specific VS Code extensions and CLI setup
- [ ] Test unified Windows installer (.msi format)

### 4.3 Windows Post-Installation Diagnostics
- [ ] Adapt diagnostics system for Windows environment
- [ ] Create Windows equivalent of `generate_report.sh` (PowerShell script)
- [ ] Test Python, VS Code, and package verification on Windows
- [ ] Generate Windows-compatible installation reports

### 4.4 Windows CI/CD Integration
- [ ] Add Windows runners to GitHub Actions workflow
- [ ] Create `test-windows-constructor` job
- [ ] Test Windows installer on different Windows versions
- [ ] Parallel testing: macOS and Windows installers

### 4.5 Cross-Platform Consistency
- [ ] Ensure same Python packages on both platforms
- [ ] Consistent VS Code extensions across platforms
- [ ] Unified documentation and user experience
- [ ] Common troubleshooting procedures
- [ ] Cross-platform diagnostics reports with same format and metrics

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
- [ ] ❌ Unified PKG installs both Python and VS Code successfully  
- [ ] ❌ All three installation methods work: constructor, orchestrator, legacy
- [ ] ❌ Compatible with macOS 10.15+ (Intel + Apple Silicon)
- [ ] ❌ Diagnostics system runs automatically post-installation

#### Windows  
- [ ] ❌ Constructor installer (.exe/.msi) installs Python 3.11 + packages
- [ ] ❌ Unified Windows installer includes VS Code
- [ ] ❌ Compatible with Windows 10+ (x64 architecture)
- [ ] ❌ Windows-specific post-install scripts work correctly
- [ ] ❌ Windows diagnostics system runs automatically post-installation

#### Cross-Platform
- [ ] ❌ Automatic GitHub releases for both platforms
- [ ] ❌ Installation works offline (no internet required)
- [ ] ❌ Consistent package versions across macOS and Windows

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

## Timeline

### Week 1 (Current)
- **Phase 1**: Complete macOS constructor PKG validation
- Merge current PR once tests pass
- Fix any critical bugs discovered in testing

### Week 2  
- **Phase 2**: macOS VS Code integration and unified distribution
- Get complete unified macOS installer working
- Full workflow testing all macOS components

### Week 3
- **Phase 3**: macOS production readiness  
- Release automation for macOS
- Documentation and cleanup

### Week 4
- **Phase 4**: Windows implementation (parallel work)
- Windows constructor setup and testing
- Cross-platform workflow integration

### Week 5
- **Phase 5**: Deployment preparation
- Performance testing both platforms
- Migration planning and user communication

## Risk Mitigation

### High Priority Risks
1. **Constructor PKG fails in production**: Have rollback to current system (both platforms)
2. **VS Code integration issues**: Make VS Code optional component
3. **macOS/Windows compatibility problems**: Test on multiple OS versions
4. **Code signing roadblocks**: Plan unsigned distribution strategy
5. **Windows-specific issues**: conda constructor behavior differences on Windows
6. **Cross-platform package consistency**: Different package versions/availability

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

## Current Action Items

### Immediate (Today)
1. ✅ Monitor current workflow run for test results
2. ❌ Fix any test failures that occur
3. ❌ Merge PR once constructor PKG tests pass

### This Week
1. ❌ Implement unified distribution testing
2. ❌ Get VS Code component working
3. ❌ Full end-to-end testing

**Status**: Phase 1 in progress - waiting for constructor PKG test results