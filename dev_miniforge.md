Switch the macos first year orchestrator to use miniforge without homebrew requirement
install vs code without homebrew

Requirements: 
Must pass the tests in the MacOS_autoInstall.yml file

while implenting this: 
Create PR to main and test through github actions

## Implementation Plan

### Current Analysis
- **Orchestrator**: `MacOS/Components/orchestrators/first_year_students.sh` currently calls Python and VSC install components
- **Python Component**: `MacOS/Components/Python/install.sh` uses Homebrew to install Miniconda via `brew install --cask miniconda`
- **VSCode Component**: `MacOS/Components/VSC/install.sh` uses `ensure_homebrew()` then `brew install --cask visual-studio-code`
- **Test Requirements**: MacOS_autoInstall.yml expects:
  - `code --version` to work
  - `conda --version` to work  
  - Python 3.11 with specific packages (dtumathtools, pandas, scipy, statsmodels, uncertainties)

### Key Dependencies to Remove
1. `ensure_homebrew()` function in `dependencies.sh`
2. Homebrew-based Miniconda installation
3. Homebrew-based VSCode installation

### Implementation Steps

#### 1. Create Miniforge Direct Installation
- Replace Miniconda+Homebrew with direct Miniforge installer
- Download and run official Miniforge installer script
- install correct python version and packages in base

#### 2. Create VSCode Direct Installation  
- Replace Homebrew cask with direct .dmg download and installation
- Download VSCode .dmg from Microsoft's official releases
- Mount, copy to Applications, and verify installation
Or something easier?

#### 3. Update Dependencies System
- Modify `dependencies.sh` to remove Homebrew dependency checks
- Create new functions for direct installations
- Maintain same error handling and logging patterns

#### 4. Update Orchestrator
- Keep same orchestrator flow but use new Homebrew-free components
- Maintain all existing analytics tracking and error handling
- Ensure backward compatibility for CI environment variables

#### 5. Testing Strategy
- Create PR to trigger GitHub Actions testing
- Monitor MacOS_autoInstall.yml workflow for:
  - VSCode version command success
  - Conda installation and version check
  - Python 3.11 with required packages
