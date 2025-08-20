# Dev Plan

Overall goal: 
Improving the installation process for students and also make it easier for supporters to provide support and troubleshoot. 

Done by implementing a new approach for MacOS where the installation script is devided up into 'Components' that can be used in a modular fashion. 

Everything we focus on will be within MacOS/ folder. 

## Phase 1: Diagnostics Component ✅ COMPLETE
Description: Finish the diagnostics component. Should be possible for a student to run a 'oneliner' to check if their python environment is setup correctly. Will generate a report that can be used to troubleshoot and be easy to share. 

### Current Status:
**Completed:**
- ✅ Sophisticated HTML report generator with DTU branding and interactive features
- ✅ Remote execution system - downloads all diagnostic scripts from GitHub repository
- ✅ Modular architecture: 12 focused diagnostic components organized by category/subcategory
- ✅ Categories: Python (Installation, Environment, Packages), Conda (Installation, Environments), Development (Homebrew, LaTeX), System (Information, Compatibility), VSCode (Installation, Extensions)
- ✅ Working oneliner: `curl -s https://raw.githubusercontent.com/philipnickel/pythonsupport-scripts/macos-components/MacOS/Components/Diagnostics/generate_report.sh | bash`
- ✅ Parallel execution with configurable timeout handling (20s default)
- ✅ Repository-based configuration system with report_config.sh
- ✅ Comprehensive error handling and cleanup mechanisms
- ✅ Professional report with pass/fail/timeout counts and detailed logs

### Tasks:
- [x] **Oneliner Command**: Create a oneliner terminal command to run diagnostics
- [x] **Extensible System**: Design system to easily add/disable checks by adding files to components folder
- [x] **Cleanup Mechanism**: Implement cleanup mechanism (report can be saved to file)
- [x] **Check Organization**: Organize checks in meaningful categories with subcategories
- [x] **Report Structure**: Structure report according to diagnostics/components folder structure
- [x] **Fast Execution**: Implement parallel execution for diagnostic checks with timeouts
- [x] **Error Handling**: Enhance error handling to ensure report always generates even with failures
- [x] **Enhanced Oneliner**: Create fully functional curl-based oneliner that works remotely 

## Phase 2: PKG Installer ✅ (85% Complete)
Description: Finish the pkg installer that installs the python environment and additional tools.

### Current Status:
**Completed:**
- ✅ PKG build system with Makefile in MacOS/pkg_installer/
- ✅ Simplified single-build system (removed environment variants)
- ✅ Self-contained bundling with components directory embedding
- ✅ Distribution.xml and resource management system (simplified for compatibility)
- ✅ Dual execution support (terminal and GUI)
- ✅ Loading Animation System: Professional progress indicators for PKG installer log
  - ASCII art headers with DTU branding
  - Emoji status indicators (✓, 🔧, 📊, etc.)
  - Progress bars for long-running operations
  - Timestamped logging with INFO/WARN/ERROR levels
  - Compatible with macOS Installer.app (visible via ⌘L)
- ✅ Testing Workaround: Created test scripts to simulate PKG installation without sudo
  - `test_pkg_install.sh`: Extracts PKG and runs scripts directly
  - `test_install_simulation.sh`: Full simulation with progress indicators
  - Uses `pkgutil --expand` to extract PKG contents for testing

**Still Needed:**

### Tasks:
- [x] **Component Integration**: Build pkg installer using macos/components
- [x] **Build System**: Create makefile for building pkg installer
- [x] **Self-Contained**: Make installer bundled and self-contained
- [x] **Dual Execution**: Enable running via terminal and double-clicking pkg
- [x] **Environment Setup**: Set up Production, CI, local-dev environments with PIS_env variable
- [x] **Loading Animation**: Implement custom loading animation using AppleScript/osascript
- [ ] **Smart Installation**: Add logic to detect and skip already installed software
- [ ] **Timeout Handling**: Add timeout handling for installation parts with cleanup on failure
- [ ] **Post-Install Diagnostics**: Run diagnostics component after installation
- [ ] **Tracking Consent**: Add user prompt for tracking consent and set environment variable
- [ ] **CI Testing**: Set up GitHub Actions testing for pkg installer 

## Phase 3: Piwik Integration ✅ (Complete)
Description: Integration with piwik by using the piwik utility

### Current Status:
**Completed:**
- ✅ Full Piwik Pro integration in MacOS/Components/Shared/piwik_utility.sh
- ✅ Event tracking for all major operations (install, uninstall, errors)
- ✅ Success/failure monitoring with detailed error messages
- ✅ System information collection (OS, architecture, commit SHA)
- ✅ Environment detection (production vs testing)
- ✅ Integrated into all component scripts via piwik_log wrapper

### Tasks:
- [x] **Piwik Integration**: Integrate with piwik using the piwik utility

## Phase 4: Documentation ✅ (90% Complete)
Description: Write proper documentation for everything macos-related

### Current Status:
**Completed:**
- ✅ Automated docstring extraction system (docs/tools/extract_docs.py)
- ✅ Native Python solution for parsing shell script docstrings
- ✅ MkDocs integration with navigation generation
- ✅ Custom pages support in docs/content/
- ✅ Local serving with mkdocs serve
- ✅ Category-based organization (Development, Utilities, etc.)

**Still Needed:**

### Tasks:
- [x] **Docstring Extraction**: Auto-pull docstrings from individual scripts for documentation
- [x] **Native Solution**: Implement native solution for docstring extraction
- [x] **Custom Pages**: Enable custom documentation pages
- [x] **Local Serving**: Add local documentation serving via makefile
- [ ] **GitHub Pages Deployment**: Deploy documentation to GitHub Pages

## Additional Improvements Identified

### High Priority:
- [x] **Parallel Diagnostics**: Implement parallel execution in generate_report.sh using background jobs
- [x] **Timeout Management**: Add configurable timeouts to all diagnostic checks
- [x] **Enhanced Error Recovery**: Improve error handling in diagnostic components
- [x] **Performance Metrics**: Add execution time tracking for each diagnostic
- [x] **Remote Component System**: Enable curl-based downloading of diagnostic scripts from repository

### Medium Priority:
- [ ] **Report Comparison**: Add ability to compare diagnostic reports between runs
- [ ] **Export Options**: Add PDF export for diagnostic reports
- [ ] **GUI Progress Indicator**: AppleScript/osascript loading animation for PKG installer
- [ ] **Installation Detection**: Smart skip logic for already installed components

### Low Priority:
- [ ] **Historical Tracking**: Store diagnostic history for trend analysis
- [ ] **Custom Report Templates**: Allow customizable report formats
- [ ] **Resource Monitoring**: Track CPU/memory usage during diagnostics 