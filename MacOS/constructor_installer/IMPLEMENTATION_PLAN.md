# Constructor-based PKG Installer Implementation Plan

## Overview

This document outlines the incremental implementation plan for migrating from the current shell-based PKG installer to a hybrid approach using conda constructor for Python components and custom PKG packaging for VSCode, eliminating Homebrew dependency entirely.

## Architecture

### Current System
- Custom shell-based installer downloading and running `first_year_students.sh`
- Dynamic installation of Homebrew → Conda → VSCode → Python packages
- Internet-dependent for all component installations
- Complex dependency chain with multiple failure points

### Target Hybrid System
```
DTU-Python-Complete.pkg (Distribution Package)
├── DTU-Python-Stack.pkg (Constructor-generated)
│   ├── Conda/Miniconda environment
│   ├── Python 3.11 + all required packages
│   ├── Pre-configured environments
│   └── Path/shell integration
├── DTU-VSCode.pkg (Custom wrapper)
│   ├── VSCode.app (downloaded from Microsoft)
│   ├── Extension installation scripts
│   ├── Python integration setup
│   └── CLI tools (code command)
└── Post-install coordination script
```

### Key Benefits
1. **No Homebrew dependency** - eliminates major complexity and potential failure point
2. **Offline installation** - Python packages bundled via constructor
3. **Professional packaging** - both components as proper macOS pkgs
4. **Enterprise-friendly** - single installer for managed deployments
5. **Version consistency** - exact same environment every time
6. **Simplified testing** - fewer moving parts to validate

## Implementation Phases

### Phase 1: Constructor Python Stack (Foundation)
**Timeline**: 1-2 weeks  
**Goal**: Create a working constructor-based Python environment that passes existing tests

#### Deliverables
1. **`construct.yaml`** - Core constructor configuration
   - Python 3.11 specification
   - Required packages: dtumathtools, pandas, scipy, statsmodels, uncertainties
   - Conda channels configuration
   - macOS-specific settings

2. **Build automation** - `build.sh`
   - Constructor installation and setup
   - Build process automation
   - Version management integration

3. **Test integration** - `test.sh`
   - Adapt existing verification commands from `test-pkg-installer.yml`
   - Python version validation
   - Package import testing
   - PATH integration verification

4. **CI/CD integration**
   - GitHub Actions workflow modification
   - Automated testing pipeline

#### Success Criteria
- [ ] Constructor PKG installs without errors
- [ ] Python 3.11 available and correct version
- [ ] All packages importable: `python3 -c "import dtumathtools, pandas, scipy, statsmodels, uncertainties"`
- [ ] PATH integration works correctly
- [ ] Installation size comparable or smaller than current approach
- [ ] Installation time faster than current network-dependent approach

#### Testing Strategy
- Install PKG on clean macOS system
- Run existing Python verification commands
- Compare performance vs current installer
- Test offline installation capability

---

### Phase 2: VSCode PKG Component (Parallel Development)
**Timeline**: 1-2 weeks (can run parallel to Phase 1)  
**Goal**: Create standalone VSCode PKG installer that matches current behavior

#### Deliverables
1. **VSCode packaging** - `build_vscode_pkg.sh`
   - Download VSCode from Microsoft official source
   - Create proper PKG installer structure
   - Handle app bundle installation to `/Applications/`

2. **Extension management**
   - Pre-install Python development extensions
   - Extension configuration and settings
   - User-specific vs system-wide installation strategy

3. **CLI tool setup**
   - Install `code` command to system PATH
   - Shell integration setup
   - Verify CLI functionality

4. **Integration scripts**
   - Python interpreter detection and configuration
   - Settings.json template for Python development
   - Extension pre-configuration

#### Success Criteria
- [ ] VSCode app installs to `/Applications/Visual Studio Code.app`
- [ ] CLI command `code --version` works
- [ ] Python extensions pre-installed and functional
- [ ] VSCode can detect and use constructor-installed Python
- [ ] Settings optimized for DTU Python development

#### Testing Strategy
- Install VSCode PKG independently
- Verify app functionality and extensions
- Test CLI tools and Python integration
- Validate extension functionality

---

### Phase 3: Integration Testing (Validation)
**Timeline**: 1 week  
**Goal**: Test both components together without distribution packaging

#### Deliverables
1. **Sequential installation testing**
   - Install Python PKG, then VSCode PKG
   - Test inter-component communication
   - Verify no conflicts or duplicate installations

2. **Comprehensive test suite adaptation**
   - Modify existing `test-pkg-installer.yml` workflow
   - Add constructor-specific test cases
   - Performance benchmarking vs current approach

3. **User experience validation**
   - Test complete development workflow
   - Validate Python coding experience in VSCode
   - Ensure feature parity with current installer

4. **Edge case testing**
   - Clean system installation
   - Upgrade scenarios
   - Partial installation recovery

#### Success Criteria
- [ ] All existing test cases pass
- [ ] Performance meets or exceeds current installer
- [ ] No conflicts between components
- [ ] Complete Python development environment functional
- [ ] User experience equivalent or better than current system

#### Testing Strategy
- Install both PKGs in sequence on multiple test systems
- Run full existing test suite
- Performance comparison testing
- User acceptance testing with sample workflows

---

### Phase 4: Distribution Package (Orchestration)
**Timeline**: 1-2 weeks  
**Goal**: Create unified installer that manages both components

#### Deliverables
1. **Master distribution configuration**
   - `Distribution.xml` for combined installer
   - Installation order and dependency management
   - User interface customization

2. **Unified installer experience**
   - Professional installer UI with DTU branding
   - Progress tracking across both components
   - Error handling and rollback capabilities

3. **Post-install integration**
   - Coordinate final setup between components
   - Generate installation summary
   - Launch post-install diagnostics

4. **Installer metadata**
   - Version management for combined installer
   - Proper package identification and tracking
   - Uninstall capability

#### Success Criteria
- [ ] One-click installation experience
- [ ] Proper error handling and rollback
- [ ] Professional installer UI with progress tracking
- [ ] Passes all existing test scenarios
- [ ] Installation summary matches current system output
- [ ] Proper integration between Python and VSCode components

#### Testing Strategy
- Single installer deployment testing
- Error scenario testing and recovery
- UI/UX validation
- Enterprise deployment simulation

---

### Phase 5: CI/CD Integration (Production Ready)
**Timeline**: 1 week  
**Goal**: Integrate with existing build and release pipeline

#### Deliverables
1. **Automated constructor builds**
   - CI pipeline integration for Python stack builds
   - Version synchronization with existing system
   - Automated testing of constructor builds

2. **VSCode packaging automation**
   - Automated VSCode download and packaging
   - Version tracking and updates
   - Extension management automation

3. **Distribution assembly pipeline**
   - Automated combination of component PKGs
   - Final installer assembly and testing
   - Release artifact generation

4. **Release integration**
   - Integration with existing release pipeline
   - Backwards compatibility with current versioning
   - Proper signing and notarization workflow

#### Success Criteria
- [ ] Automated builds work reliably in CI/CD
- [ ] Version management integrated with existing system
- [ ] Release artifacts properly signed/notarized
- [ ] Backwards compatible with existing pipeline
- [ ] Zero-touch build and release process
- [ ] Proper error handling and notifications in CI

#### Testing Strategy
- Full CI/CD pipeline testing
- Release process validation
- Integration testing with existing systems
- Production deployment verification

## Directory Structure

```
MacOS/constructor_installer/
├── IMPLEMENTATION_PLAN.md          # This document
├── README.md                       # Quick start guide
├── python_stack/                   # Phase 1: Constructor Python environment
│   ├── construct.yaml              # Constructor configuration
│   ├── build.sh                   # Build automation
│   ├── test.sh                    # Testing script
│   └── docs/                      # Phase-specific documentation
├── vscode_component/               # Phase 2: VSCode PKG creation
│   ├── build_vscode_pkg.sh        # VSCode packaging script
│   ├── extensions/                # Extension configurations
│   ├── templates/                 # Settings templates
│   └── docs/                      # Phase-specific documentation
├── distribution/                   # Phase 4: Combined installer
│   ├── Distribution.xml           # Master distribution config
│   ├── build_combined.sh          # Combined installer build
│   ├── resources/                 # UI resources and branding
│   └── docs/                      # Phase-specific documentation
├── testing/                       # Phase 3 & 5: Testing infrastructure
│   ├── integration_tests.sh       # Integration test suite
│   ├── performance_tests.sh       # Performance benchmarking
│   └── ci_cd_tests/              # CI/CD testing scripts
└── docs/                          # General documentation
    ├── CONSTRUCTOR_GUIDE.md       # Constructor usage guide
    ├── VSCODE_PACKAGING.md        # VSCode packaging guide
    └── TROUBLESHOOTING.md         # Common issues and solutions
```

## Testing Strategy

### Continuous Testing Approach
- Each phase includes comprehensive testing before proceeding
- Automated testing integrated with CI/CD pipeline
- Performance benchmarking against current system
- User acceptance testing for experience validation

### Test Environments
1. **Clean macOS systems** - Fresh installations
2. **Existing DTU systems** - Upgrade scenarios
3. **Enterprise environments** - Managed deployment testing
4. **CI/CD environments** - Automated testing infrastructure

### Success Metrics
- **Installation success rate**: >99%
- **Installation time**: <50% of current system
- **User satisfaction**: Equal or better than current system
- **Maintenance overhead**: Reduced compared to current system
- **CI/CD reliability**: >99% successful builds

## Risk Mitigation

### Technical Risks
- **Constructor learning curve**: Mitigated by Phase 1 focus and incremental approach
- **VSCode packaging complexity**: Addressed in dedicated Phase 2
- **Integration issues**: Handled by dedicated Phase 3 testing

### Process Risks
- **Timeline delays**: Mitigated by parallel development and clear phase gates
- **Testing coverage**: Addressed by comprehensive test strategy
- **Rollback capability**: Each phase provides rollback to previous working state

### User Experience Risks
- **Feature regression**: Mitigated by comprehensive test suite adaptation
- **Learning curve for users**: Addressed by maintaining familiar end-state
- **Enterprise deployment**: Validated in Phase 4 with proper packaging

## Next Steps

1. **Start Phase 1**: Begin with constructor Python stack implementation
2. **Set up testing infrastructure**: Prepare automated testing for constructor builds
3. **Document progress**: Track implementation progress and lessons learned
4. **Plan Phase 2 kickoff**: Begin VSCode component development in parallel

## Success Definition

The implementation is considered successful when:
- All existing test cases pass with new installer
- Installation time is reduced compared to current system
- User experience is maintained or improved
- Enterprise deployment capabilities are enhanced
- Maintenance overhead is reduced
- CI/CD integration is seamless

---

**Document Version**: 1.0  
**Last Updated**: 2025-08-23  
**Status**: Planning Phase  
**Next Review**: Start of Phase 1 Implementation