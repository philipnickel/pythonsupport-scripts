# Windows MSI Installer

This is an MSI installer for Windows, build with the
[WiX](https://www.firegiant.com/wixtoolset/) toolset. It is essentially a
wrapper that installs and runs a PowerShell script which performs the actual
installation.

Main inspirations:

- <https://docs.firegiant.com/heatwave/building-wix-projects/>
- <https://damienbod.com/2013/09/01/wix-installer-with-powershell-scripts/>.
- <https://stackoverflow.com/questions/26378382/wix-how-to-execute-a-command-line-command-after-installation>

## Building & Running

Only builds on Windows. Requires .NET, installable with the following command.

```
winget install Microsoft.DotNet.SDK.9
```

The installer is built as follows.

```
dotnet build
```

This creates an MSI file which can be run as follows, producing a log in
`log.txt`.

```
msiexec /i bin\Debug\DtuPythonInstaller.msi /l*v log.txt
```

By default, the installer creates the files `install.ps1` and `license.rtf` in
`C:\Program Files (x86)\DTU Python Installer\`. `install.ps1` is executed
automatically.

## TODO

- Displays more information about the installation process to the user.
- Perform error handling if the script fails.
