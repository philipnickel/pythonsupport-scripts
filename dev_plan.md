# Development Plan

## Overview
This document outlines the main development tasks that need to be completed for the Python Support Scripts project.

## Main Tasks

### 1. Workflow Cleanup
- Review and optimize existing workflows
- Remove redundant or outdated processes
- Standardize workflow patterns across the codebase
Requirements: 
- Seperate MacOS and Windows Workflows
- Tests on latest MacOS and intel MacOS
- Test on Windows 10 and Windows 11
- Verifies that the new python installation is the one a fresh shell is using (base activated automatically)
- Verifies correct python version is installed along with needed packages
- Verifies vscode along with extensions are installed
- Test scenarios: Preinstalled conda (triggers autouninstall and then 'reinstall') (anaconda or miniconda)

### 2. Add Piwik Analytics
- Integrate Piwik analytics tracking at key stages of the workflow
- Should be minimal and not intrusive in the scripts
- Won't abort installation if Piwik is not available
using: piwik_log CODE
with CODE refering to specific events/steps in the workflow - setup up logical groupings of events
Pythonrelated code: 2xx for example 200 being 'Miniforge installed successfully' and 201 being 'Miniforge installation failed'
300 being VSCode installed successfully and 301 being VSCode installation failed

### 3. Fix Uninstall Feature
- Complete the uninstall functionality
- Ensure clean removal of all components (everything conda related according to official documentation)
- Should work by either calling oneliner for uninstall script directly or when called withing main installer entrypoint

### 4. Ensure No User-Terminal Interaction Using macOS Native Popups
- Replace terminal prompts with macOS native dialogs for:
  - Piwik analytics consent
  - Uninstall confirmation
  - Sudo permission requests (if needed)
- Implement AppleScript or native macOS UI components
- Maintain non-interactive operation from terminal
- CI detection to just confirm 

### 5. Documentation Update
- Update README.md with relevant 'oneliners'
- explore how we can use github pages for proper documentation
- using 'custom markdown files' along with docstrings in the codebase

### 6. Advanced Diagnostics Capabilities
- change current 'simple_report.sh' to 'post_install_report.sh'
- Create a 'comprehensive_report.sh' that adds additional checks to a report 
- The html part should be 'templated' in a way so we can use it for both windows and macos 
In the end: 
Diagnostics tools for both MacOS and Windows
post_install_report.sh should be very clear and easy to understand (intended for users)
comprehensive_report.sh should be more detailed and include additional checks (intended for supporters debugging)
Priority: 
- Post install report should work fully before starting with comprehensive report

### 7. Global Installation Config
- Create centralized configuration management for handling pythonversion and packages installed
both windows and macos install scripts load from that 

### 8. Windows: 
- Ensure windows has a setup that works similarily to macos. 
- Follows same pattern, logic and structure as macos


## Notes
- all code should follow best practices, be easily readable and maintainable
