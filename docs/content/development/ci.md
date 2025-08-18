# Continuous Integration (CI)

The repository uses GitHub Actions for automated testing of all components and orchestrators to ensure reliability and quality.

## Testing Strategy

The CI system is designed with two complementary approaches:

### 1. Component Testing (`mac_components.yml`)

**Purpose**: Test individual components in isolation to catch issues early during development.

**Triggers**:
- Pull requests to any branch
- Changes to `MacOS/Components/**` 
- Changes to the workflow file

**Components Tested**:
- **Homebrew**: Package manager installation
- **Python**: Miniconda installation and basic functionality
- **VSCode**: Editor installation and extension setup
- **LaTeX**: Document preparation tools (with Python dependency)
- **Diagnostics**: System compatibility checks
- **Python Uninstall**: Cleanup script verification

**Test Approach**: Each component is tested independently with clean environments, focusing on:
- Successful installation
- Basic functionality verification  
- Dependency management
- Clean uninstallation (where applicable)

### 2. Orchestrator Testing (`mac_orchestrators.yml`)

**Purpose**: Test complete end-to-end installations that combine multiple components.

**Triggers**:
- Pull requests to `main` branch only
- Changes to `MacOS/Components/**`
- Changes to the workflow file

**Orchestrators Tested**:
- **First Year Students**: Complete setup equivalent to legacy `MacOS_AutoInstall.sh`

**Test Approach**: Full integration testing with the same standards as legacy scripts:
- Clean system installation
- Exact Python version verification (3.11.x)
- Complete package verification (dtumathtools, pandas, scipy, statsmodels, uncertainties)
- VSCode and extension verification

## Workflow Architecture

```
┌─────────────────────────────────────┐
│           Pull Request              │
│        (any branch)                 │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│      Component Tests Run            │
│   • Fast feedback (1-2 min each)   │
│   • Individual component focus     │
│   • Parallel execution             │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│     PR to main branch only          │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│    Orchestrator Tests Run           │
│  • Full integration verification   │
│  • Legacy compatibility check      │
│  • Complete setup validation       │
└─────────────────────────────────────┘
```

## Component Test Details

### Homebrew Component
- Installs Homebrew package manager
- Verifies `brew` command availability
- Tests basic package management functionality

### Python Component  
- Installs miniconda via component script
- Verifies conda availability and basic functionality
- Tests in isolation (no first-year packages)

### VSCode Component
- Installs Visual Studio Code
- Installs Python development extensions
- Verifies editor launches and extensions are available

### LaTeX Component
- **Dependency**: Requires Python component (installs it first)
- Installs pandoc and BasicTeX
- Installs additional TeX packages
- Verifies nbconvert integration
- Tests complete LaTeX → PDF pipeline

### Python Uninstall Tests
- **Install → Verify → Uninstall → Verify** cycle
- Tests both `uninstall_conda.sh` and `uninstall_python.sh`
- Verifies complete cleanup of directories and shell configuration
- Handles both miniconda and Homebrew-managed conda installations

### Diagnostics Component
- **Dependencies**: Runs after Homebrew, Python, and VSCode tests
- Performs system compatibility and installation verification
- Provides comprehensive environment analysis

## Orchestrator Test Details

### First Year Students Orchestrator

This test ensures the modular component approach produces identical results to the legacy monolithic `MacOS_AutoInstall.sh` script.

**Test Steps**:
1. **Clean System**: Remove all existing installations
2. **Run Orchestrator**: Execute `first_year_students.sh` 
3. **Strict Verification**: Apply same standards as legacy script
   - VSCode must be functional
   - Conda must be available  
   - Python version must be exactly 3.11.x
   - All first-year packages must import successfully

**Success Criteria**: If this test passes, the modular approach is a perfect drop-in replacement for the legacy script.

## CI Environment

**Runners**: `macos-latest` (GitHub-hosted)
**Shell**: `bash -l {0}` (login shell for proper environment loading)
**Parallelization**: Component tests run in parallel for faster feedback
**Isolation**: Each test job uses a fresh macOS environment

## Development Workflow

1. **During Development**: Component tests provide fast feedback on individual changes
2. **Before Merging**: Orchestrator tests verify complete integration works
3. **Quality Gate**: Both test suites must pass before code can be merged to main

## Monitoring and Maintenance

- **Scheduled Runs**: Orchestrator tests run weekly to catch environment changes
- **Manual Triggers**: Both workflows support `workflow_dispatch` for manual testing
- **Failure Handling**: Tests fail fast with clear error messages for debugging

This comprehensive CI system ensures that both individual components and complete installations remain reliable and maintain backward compatibility with existing user workflows.