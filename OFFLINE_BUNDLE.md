# Offline USB bundle

The generated ZIP contains everything required to install DTU Miniforge,
Visual Studio Code, the DTU settings, and the configured extensions without a
network connection.

## Build the ZIP

The worktree must be clean because the builder packages the committed `HEAD`.

```bash
# Prepare USB drive directly (macOS):
bash Utils/OfflineBundle/prepare_usb.sh

# Or build standalone release ZIP:
uv run Utils/OfflineBundle/build_offline_bundle.py
```

The builder writes release archives to `dist/`, or flashes a USB drive directly
when run with `prepare_usb.sh` (or `--target-dir`).

## Running on macOS

Open `Install macOS.command` in the extracted folder. If macOS does not retain
the executable bit, run it from Terminal instead:

```bash
bash "/path/to/DTU-Python-Support-Offline-.../Install macOS.command"
```

## Running on Windows

Double-click `Install Windows.cmd` in the extracted folder.

## Interactive Menu

The launchers present an interactive menu in the terminal:
- **1) Full Installation (Default):** Installs Miniforge, VS Code, settings, and extensions.
- **2) Install Miniforge only:** Installs DTU Miniforge conda environment.
- **3) Install VS Code only:** Installs VS Code with DTU settings and extensions.
- **4) Full Uninstall:** Completely removes VS Code and Conda distributions.
- **5) Uninstall Miniforge only**
- **6) Uninstall VS Code only**
- **q) Quit**

Pressing `Enter` defaults to option `1` (Full Installation). Offline mode never
falls back to the network.

The build manifest records extension dependency cycles. Current Microsoft
Python tooling contains such a cycle; every member is bundled once and the
generated installation order remains finite.

On Windows ARM64, VS Code is native ARM64 while the current DTU Miniforge x64
build runs under Windows emulation.

Extensions installed from VSIX files do not automatically update by default.
