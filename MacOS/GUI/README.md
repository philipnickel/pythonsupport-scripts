# First Year Python Installer for macOS

A portable macOS application built with AppleScript that provides a graphical interface for DTU Python Support tools, specifically designed for first-year students.

## Features

- **System Diagnostics**: Run comprehensive system diagnostics to check your Python development environment
- **First Year Setup**: (Coming soon) Complete installation of Python development environment for first-year students
- **User-friendly Interface**: Simple dialog-based interface that's easy to use
- **Portable**: Self-contained application that can be run from anywhere

## Building the Application

### Prerequisites

- macOS (required for AppleScript compilation)
- `osacompile` command-line tool (included with macOS)

### Build Steps

1. Navigate to the GUI directory:
   ```bash
   cd MacOS/GUI
   ```

2. Run the build script:
   ```bash
   ./build_app.sh
   ```

3. The compiled application will be created as `FirstYearPythonInstallerMacOS.app`

## Using the Application

### Running the App

1. **Double-click** the `FirstYearPythonInstallerMacOS.app` file to launch
2. **Drag to Applications folder** for permanent installation
3. **Run from command line**: `open FirstYearPythonInstallerMacOS.app`

### Available Options

#### Run Diagnostics
- Checks your macOS version and architecture
- Verifies Homebrew installation and status
- Tests Python/Conda installations and environments
- Validates Visual Studio Code setup and extensions
- Provides detailed system information

#### First Year Setup (Coming Soon)
- Complete installation of Python development environment
- Includes Homebrew, Python with Miniconda, VSCode, and essential packages
- Designed specifically for DTU first-year students

## Technical Details

### Architecture
- **Language**: AppleScript
- **Compilation**: Uses `osacompile` to create portable `.app` bundle
- **Dependencies**: None (self-contained)
- **Target**: macOS 10.14+ (Mojave and later)

### Integration
The GUI application calls the same command-line scripts used by the Python Support team:
- Diagnostics: `MacOS/Components/Diagnostics/run.sh`
- First Year Setup: `MacOS/Components/orchestrators/first_year_students.sh`

### Security
- All scripts are downloaded from the official DTU repository
- Uses HTTPS for secure downloads
- No local file modifications without user consent

## Development

### Modifying the GUI

1. Edit `FirstYearPythonInstallerMacOS.applescript`
2. Run `./build_app.sh` to recompile
3. Test the new application

### Adding New Features

To add new functionality:

1. Add new handler functions in the AppleScript
2. Update the main dialog to include new options
3. Implement the functionality using shell script calls
4. Test thoroughly before deployment

## Troubleshooting

### Common Issues

**App won't launch:**
- Check that the app has execute permissions
- Verify it was built on macOS
- Try rebuilding with `./build_app.sh`

**Diagnostics fail:**
- Check internet connection
- Verify the DTU repository is accessible
- Check terminal output for detailed error messages

**Permission denied:**
- The app may need to be allowed in System Preferences > Security & Privacy
- Some operations require administrator privileges

### Getting Help

For issues with the GUI application or underlying scripts:
- Contact: pythonsupport@dtu.dk
- Visit: https://pythonsupport.dtu.dk
- Check the terminal output for detailed error information

## Version History

- **v1.0.0**: Initial release with diagnostics functionality
- **v1.1.0**: Added first year setup placeholder (coming soon)
