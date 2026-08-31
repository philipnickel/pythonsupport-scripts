from __future__ import annotations

import json
import os
import shlex
import shutil
import subprocess
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[1]


def test_release_builder_is_valid_and_documents_both_images() -> None:
    builder = REPO_ROOT / "Utils/OfflineBundle/build_release.sh"
    syntax = subprocess.run(
        ["bash", "-n", str(builder)], text=True, capture_output=True, check=False
    )
    assert syntax.returncode == 0, syntax.stderr
    help_result = subprocess.run(
        ["bash", str(builder), "--help"], text=True, capture_output=True, check=False
    )
    assert help_result.returncode == 0, help_result.stderr
    assert "DTU Python Support.dmg" in help_result.stdout
    assert "DTU Python Support Windows.iso" in help_result.stdout
    builder_text = builder.read_text()
    assert "dmg-background.png" in builder_text
    assert "DTU-Python-Support.icns" in builder_text
    assert "Applying the DTU Finder layout" in builder_text


def test_bundle_runtime_has_no_launcher_metadata_or_manifest_dependency() -> None:
    runtime_files = [
        *REPO_ROOT.glob("Core/**/*.sh"),
        *REPO_ROOT.glob("Core/**/*.ps1"),
        *REPO_ROOT.glob("Utils/Conda/*"),
        *REPO_ROOT.glob("Utils/VsCode/*"),
    ]
    text = "\n".join(path.read_text() for path in runtime_files if path.is_file())
    assert "@launcher" not in text
    assert "bundle-metadata.json" not in text


def test_macos_miniforge_check_detects_outdated_dtu_release(tmp_path: Path) -> None:
    home = tmp_path / "home"
    conda = home / "miniforge3-dtu/bin/conda"
    conda.parent.mkdir(parents=True)
    conda.write_text("#!/bin/bash\nexit 0\n")
    conda.chmod(0o755)
    (home / "miniforge3-dtu/.dtu-python-support.json").write_text(
        json.dumps({"schema": 1, "dtuRelease": "2026.2.2-0"})
    )
    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    fake_curl = fake_bin / "curl"
    fake_curl.write_text(
        "#!/bin/bash\nprintf '%s\\n' '{\"tag_name\":\"2026.2.3-0\"}'\n"
    )
    fake_curl.chmod(0o755)
    result = subprocess.run(
        ["bash", str(REPO_ROOT / "Core/Checks/check_miniforge_macOS.sh")],
        env={"HOME": str(home), "PATH": f"{fake_bin}:{os.environ['PATH']}"},
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    payload = json.loads(result.stdout)
    assert payload["status"] == "outdated"
    assert payload["installedVersion"] == "2026.2.2-0"
    assert payload["latestVersion"] == "2026.2.3-0"


def test_macos_extension_check_compares_ids_not_versions(tmp_path: Path) -> None:
    fake_bin = tmp_path / "fake bin"
    fake_bin.mkdir()
    fake_code = fake_bin / "code"
    fake_code.write_text(
        "#!/bin/bash\n"
        "if [[ \"$1\" == --list-extensions ]]; then\n"
        "  printf '%s\\n' ms-python.python ms-python.vscode-pylance ms-python.debugpy "
        "ms-toolsai.jupyter ms-toolsai.jupyter-renderers ms-toolsai.jupyter-keymap "
        "ms-toolsai.vscode-jupyter-cell-tags ms-toolsai.vscode-jupyter-slideshow\n"
        "fi\n"
    )
    fake_code.chmod(0o755)
    result = subprocess.run(
        ["bash", str(REPO_ROOT / "Core/Checks/check_extensions_macOS.sh")],
        env={
            "HOME": str(tmp_path / "home"),
            "PATH": f"{fake_bin}:{os.environ['PATH']}",
            "PS_ENV": "offline",
            "PS_BUNDLE_ROOT": str(REPO_ROOT),
        },
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)["status"] == "ready"


def test_macos_extension_installer_uses_marketplace_ids_in_offline_mode(
    tmp_path: Path,
) -> None:
    bundle_root = tmp_path / "bundle"
    extension_list = bundle_root / "Core/VsCode/config/extensions.txt"
    extension_list.parent.mkdir(parents=True)
    extension_list.write_text("# Required\nms-python.python\r\nms-toolsai.jupyter\n")
    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    calls = tmp_path / "code-calls.txt"
    fake_code = fake_bin / "code"
    fake_code.write_text(
        "#!/bin/bash\n" f"printf '%s\\n' \"$*\" >> {shlex.quote(str(calls))}\n"
    )
    fake_code.chmod(0o755)
    result = subprocess.run(
        ["bash", str(REPO_ROOT / "Core/VsCode/config/extensions_macOS.sh")],
        env={
            "HOME": str(tmp_path / "home"),
            "PATH": f"{fake_bin}:{os.environ['PATH']}",
            "PS_ENV_INITIALIZED": "1",
            "PS_ENV": "offline",
            "PS_BUNDLE_ROOT": str(bundle_root),
        },
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert calls.read_text().splitlines() == [
        "--install-extension ms-python.python --force",
        "--install-extension ms-toolsai.jupyter --force",
    ]


def test_legacy_macos_full_install_uses_leaf_scripts(tmp_path: Path) -> None:
    root = tmp_path / "command bundle"
    launcher = root / "Install macOS.command"
    shutil.copytree(REPO_ROOT / "Core", root / "Core")
    shutil.copyfile(REPO_ROOT / "Install macOS.command", launcher)
    marker = root / "ran.txt"
    for name, relative_path in (
        ("conda", "Core/Conda/install/install_macOS.sh"),
        ("vscode", "Core/VsCode/install/install_macOS.sh"),
        ("settings", "Core/VsCode/config/settings_macOS.sh"),
        ("extensions", "Core/VsCode/config/extensions_macOS.sh"),
    ):
        script = root / relative_path
        script.write_text(f"#!/bin/bash\necho {name} >> {str(marker)!r}\n")
    result = subprocess.run(
        ["bash", str(launcher), "install-all"],
        env={"PATH": os.environ["PATH"], "HOME": str(tmp_path)},
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert marker.read_text().splitlines() == ["conda", "vscode", "settings", "extensions"]


@pytest.mark.parametrize(
    ("values", "expected"),
    [
        ({}, "main|https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main"),
        (
            {"PS_REPO_USER": "someone", "PS_BRANCH": "topic/test"},
            "custom|https://raw.githubusercontent.com/someone/pythonsupport-scripts/topic/test",
        ),
        ({"PS_REPO_URL": "https://example.test/raw"}, "custom|https://example.test/raw"),
    ],
)
def test_macos_environment_resolves_online_profiles(
    values: dict[str, str], expected: str
) -> None:
    environment = {"PATH": os.environ["PATH"], **values}
    env_script = shlex.quote(str(REPO_ROOT / "Core/env.sh"))
    result = subprocess.run(
        ["bash", "-c", f"source {env_script}; printf '%s|%s' \"$PS_ENV\" \"$PS_REPO_URL\""],
        env=environment,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert result.stdout == expected


@pytest.mark.parametrize(
    "values",
    [
        {"PS_ENV": "main", "PS_REPO_URL": "https://example.test/raw"},
        {"PS_ENV": "custom"},
        {"PS_OFFLINE": "1"},
    ],
)
def test_macos_environment_rejects_invalid_inputs(values: dict[str, str]) -> None:
    result = subprocess.run(
        ["bash", str(REPO_ROOT / "Core/env.sh")],
        env={"PATH": os.environ["PATH"], **values},
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 2


def test_windows_wrapper_selects_both_native_launchers() -> None:
    wrapper = (
        REPO_ROOT / "Utils/OfflineBundle/windows/DTU Python Support.cmd"
    ).read_text()
    assert "pis-launcher-windows-amd64.exe" in wrapper
    assert "pis-launcher-windows-arm64.exe" in wrapper
    assert "PROCESSOR_ARCHITECTURE" in wrapper
    assert "PS_ENV=offline" in wrapper
    assert "title DTU Python Support" in wrapper

    autorun = (REPO_ROOT / "Utils/OfflineBundle/windows/autorun.inf").read_text()
    assert "label=DTU Python Support" in autorun
    assert "DTU-Python-Support.ico" in autorun
