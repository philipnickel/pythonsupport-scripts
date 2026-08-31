# Universal offline-core images

The release consists of exactly two mounted images:

- `DTU Python Support.dmg` supports Intel and Apple Silicon macOS.
- `DTU Python Support Windows.iso` supports x64 and ARM64 Windows.

Both contain DTU Miniforge, Visual Studio Code, launcher scripts, and DTU
settings. Required VS Code extensions are installed by ID from the Marketplace,
so that final step needs internet access. An extension failure leaves the core
installation intact and can be retried later.

## Build

On macOS, install `go`, `gh`, `curl`, and the standard Xcode command-line tools,
then run:

```bash
bash Utils/OfflineBundle/build_release.sh
```

The same build can be started manually from GitHub Actions with the
**Build offline installers** workflow. It publishes the DMG, Windows ISO, and
their checksums as separate downloadable artifacts for seven days. The ISO is
then mounted and smoke-tested on a Windows runner.

Use `--refresh` to redownload current installers. Otherwise the builder reuses
assets cached under `release_assets/offline-cache/`, keyed by the DTU release
tag and VS Code source commit.

The builder obtains the three required Miniforge assets with `gh`, verifies
their release checksums, downloads the three VS Code architectures from the
official stable endpoints, and verifies Microsoft's SHA-256 response headers.
It cross-builds the four Go targets and injects the DTU and Miniforge versions
into the binaries. No bundle manifest, release ZIP, or persistent log is made.

## Use

On macOS, mount the DMG and double-click `DTU Python Support.command`. This
visible file is the universal Go executable itself, rather than a shell wrapper
which launches a second executable. The image uses DTU's corporate-red logo for
its disk icon, launcher icon, and Finder background.

On Windows, mount the ISO and double-click `DTU Python Support.cmd`. The wrapper
selects the x64 or ARM64 Go launcher. Windows ARM64 uses native ARM64 VS Code and
runs the x64 DTU Miniforge installer through Windows emulation. Explorer shows
the official DTU icon for the mounted image, and the launcher sets a DTU Python
Support console title.

The launcher checks the machine before presenting actions. A fresh computer
gets the fast “Install everything” choice; every other state opens the grouped
install/uninstall overview. Installer output streams directly in the terminal,
and no logs directory is created.

The mounted image must remain available until the chosen operation completes.
The images and Go launchers are unsigned, so Gatekeeper or SmartScreen may still
show a warning depending on system policy.
