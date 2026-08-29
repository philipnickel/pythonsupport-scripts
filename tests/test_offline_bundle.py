from __future__ import annotations

import hashlib
import json
import os
import plistlib
import shutil
import subprocess
import zipfile
from pathlib import Path

import httpx
import pytest
import respx

from Utils.OfflineBundle import build_offline_bundle as bundle
from Utils.OfflineBundle import vscode_extensions as extensions


def make_vsix(
    path: Path,
    extension_id: str,
    *,
    version: str = "1.0.0",
    dependencies: list[str] | None = None,
    extension_pack: list[str] | None = None,
    platform: str | None = None,
    engine: str = "^1.80.0",
) -> Path:
    publisher, name = extension_id.split(".", 1)
    package = {
        "publisher": publisher,
        "name": name,
        "version": version,
        "engines": {"vscode": engine},
        "extensionDependencies": dependencies or [],
        "extensionPack": extension_pack or [],
    }
    target = f' TargetPlatform="{platform}"' if platform else ""
    manifest = f"<PackageManifest{target}></PackageManifest>"
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr("extension/package.json", json.dumps(package))
        archive.writestr("extension.vsixmanifest", manifest)
    return path


def result_for(path: Path, url: str) -> bundle.DownloadResult:
    return bundle.DownloadResult(
        path=path,
        source_url=url,
        resolved_url=url,
        sha256=bundle.sha256_file(path),
        size=path.stat().st_size,
    )


def test_downloader_follows_redirect_and_writes_atomic_cache(tmp_path: Path) -> None:
    target = tmp_path / "cache" / "asset.bin"
    with respx.mock(assert_all_called=True) as router:
        router.get("https://example.test/latest").mock(
            return_value=httpx.Response(
                302, headers={"Location": "https://cdn.example.test/v1/asset.bin"}
            )
        )
        router.get("https://cdn.example.test/v1/asset.bin").mock(
            return_value=httpx.Response(200, content=b"offline asset")
        )
        with httpx.Client(follow_redirects=True) as client:
            result = bundle.Downloader(client, retry_delay=0).download(
                "https://example.test/latest", target
            )

    assert target.read_bytes() == b"offline asset"
    assert not target.with_suffix(".bin.part").exists()
    assert result.resolved_url == "https://cdn.example.test/v1/asset.bin"
    metadata = json.loads(target.with_suffix(".bin.json").read_text())
    assert metadata["sha256"] == hashlib.sha256(b"offline asset").hexdigest()


def test_downloader_retries_and_rejects_bad_checksum(tmp_path: Path) -> None:
    target = tmp_path / "asset.bin"
    with respx.mock() as router:
        route = router.get("https://example.test/asset")
        route.side_effect = [
            httpx.Response(503),
            httpx.Response(200, content=b"complete"),
        ]
        with httpx.Client() as client:
            result = bundle.Downloader(client, retry_delay=0).download(
                "https://example.test/asset", target
            )
    assert route.call_count == 2
    assert result.sha256 == hashlib.sha256(b"complete").hexdigest()

    with respx.mock() as router:
        router.get("https://example.test/wrong").mock(
            return_value=httpx.Response(200, content=b"wrong")
        )
        with (
            httpx.Client() as client,
            pytest.raises(bundle.BundleError, match="Checksum mismatch"),
        ):
            bundle.Downloader(client, retry_delay=0).download(
                "https://example.test/wrong",
                tmp_path / "wrong.bin",
                expected_sha256="0" * 64,
            )
    assert not (tmp_path / "wrong.bin.part").exists()


def test_immutable_download_reuses_verified_cache(tmp_path: Path) -> None:
    target = tmp_path / "asset.bin"
    target.write_bytes(b"cached")
    digest = bundle.sha256_file(target)
    target.with_suffix(".bin.json").write_text(
        json.dumps(
            {
                "source_url": "https://example.test/v1",
                "resolved_url": "https://example.test/v1",
                "sha256": digest,
                "size": target.stat().st_size,
            }
        )
    )
    with respx.mock(assert_all_mocked=True) as router:
        with httpx.Client() as client:
            result = bundle.Downloader(client).download(
                "https://example.test/v1", target, immutable=True
            )
        assert not router.calls
    assert result.sha256 == digest


def test_marketplace_prefers_exact_platform_then_universal() -> None:
    response = {
        "results": [
            {
                "extensions": [
                    {
                        "versions": [
                            {
                                "version": "2.0.0",
                                "targetPlatform": "universal",
                                "files": [
                                    {
                                        "assetType": "Microsoft.VisualStudio.Services.VSIXPackage",
                                        "source": "https://cdn.example.test/universal.vsix",
                                    }
                                ],
                            },
                            {
                                "version": "2.0.0",
                                "targetPlatform": "darwin-arm64",
                                "files": [
                                    {
                                        "assetType": "Microsoft.VisualStudio.Services.VSIXPackage",
                                        "source": "https://cdn.example.test/arm64.vsix",
                                    }
                                ],
                            },
                        ]
                    }
                ]
            }
        ]
    }
    with respx.mock() as router:
        router.post(bundle.MARKETPLACE_QUERY_URL).mock(
            return_value=httpx.Response(200, json=response)
        )
        with httpx.Client() as client:
            marketplace = bundle.MarketplaceClient(client)
            arm = marketplace.resolve("publisher.extension", "darwin-arm64")
            intel = marketplace.resolve("publisher.extension", "darwin-x64")
    assert arm.download_url.endswith("arm64.vsix")
    assert arm.target_platform == "darwin-arm64"
    assert intel.download_url.endswith("universal.vsix")


class FakeDownloader:
    def __init__(self, files: dict[str, Path]) -> None:
        self.files = files

    def download(self, url: str, target: Path, **_: object) -> bundle.DownloadResult:
        target.parent.mkdir(parents=True, exist_ok=True)
        source = self.files.get(url, next(iter(self.files.values())))
        shutil.copyfile(source, target)
        return result_for(target, url)


def test_read_extension_ids_parses_clean_ids(tmp_path: Path) -> None:
    ext_file = tmp_path / "extensions.txt"
    ext_file.write_text("# Python\nms-python.python\n\n# Tools\nms-toolsai.jupyter\n")
    ids = extensions.read_extension_ids(ext_file)
    assert ids == ["ms-python.python", "ms-toolsai.jupyter"]


def test_resolve_extensions_separates_universal_and_platform_cache(tmp_path: Path) -> None:
    platform = "darwin-arm64"
    files = {
        "https://example.test/ms-python.python.vsix": tmp_path / "python.vsix",
        "https://example.test/ms-toolsai.jupyter.vsix": tmp_path / "jupyter.vsix",
    }
    for p in files.values():
        p.write_bytes(b"dummy-vsix")

    class MockMarketplace:
        def resolve(self, ext_id: str, platform_name: str) -> extensions.MarketplaceVersion:
            target = "universal" if "jupyter" in ext_id else platform_name
            return extensions.MarketplaceVersion(
                extension_id=ext_id,
                version="1.0.0",
                target_platform=target,
                download_url=f"https://example.test/{ext_id}.vsix",
            )

    resolved = extensions.resolve_extensions(
        platform,
        MockMarketplace(),  # type: ignore[arg-type]
        FakeDownloader(files),  # type: ignore[arg-type]
        tmp_path / "cache",
        ["ms-python.python", "ms-toolsai.jupyter"],
    )
    assert len(resolved) == 2
    assert (tmp_path / "cache/extensions/darwin-arm64/ms-python.python-1.0.0.vsix").exists()
    assert (tmp_path / "cache/extensions/universal/ms-toolsai.jupyter-1.0.0.vsix").exists()


def test_deterministic_zip_and_permissions(tmp_path: Path) -> None:
    source = tmp_path / "Bundle"
    source.mkdir()
    launcher = source / "Install macOS.command"
    launcher.write_text("#!/bin/bash\nexit 0\n")
    launcher.chmod(0o755)
    (source / "data.txt").write_text("data\n")

    first = tmp_path / "first.zip"
    second = tmp_path / "second.zip"
    bundle.create_deterministic_zip(source, first)
    bundle.create_deterministic_zip(source, second)
    bundle.validate_bundle_zip(first, "Bundle")

    assert first.read_bytes() == second.read_bytes()
    with zipfile.ZipFile(first) as archive:
        info = archive.getinfo("Bundle/Install macOS.command")
        assert (info.external_attr >> 16) & 0o777 == 0o755


def test_vscode_version_is_read_from_macos_archive(tmp_path: Path) -> None:
    archive_path = tmp_path / "VSCode.zip"
    with zipfile.ZipFile(archive_path, "w") as archive:
        archive.writestr(
            "Visual Studio Code.app/Contents/Info.plist",
            plistlib.dumps({"CFBundleShortVersionString": "1.135.0"}),
        )
    assert bundle.vscode_version_from_archive(archive_path) == "1.135.0"


def test_dirty_worktree_is_rejected(tmp_path: Path) -> None:
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    subprocess.run(["git", "config", "user.email", "test@example.invalid"], cwd=tmp_path, check=True)
    subprocess.run(["git", "config", "user.name", "Test"], cwd=tmp_path, check=True)
    tracked = tmp_path / "tracked.txt"
    tracked.write_text("clean\n")
    subprocess.run(["git", "add", "tracked.txt"], cwd=tmp_path, check=True)
    subprocess.run(["git", "commit", "-qm", "initial"], cwd=tmp_path, check=True)
    bundle.require_clean_worktree(tmp_path)
    tracked.write_text("dirty\n")
    with pytest.raises(bundle.BundleError, match="clean worktree"):
        bundle.require_clean_worktree(tmp_path)


def test_insufficient_disk_space_is_rejected(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    usage = shutil._ntuple_diskusage(total=100, used=99, free=1)
    monkeypatch.setattr(bundle.shutil, "disk_usage", lambda _: usage)
    with pytest.raises(bundle.BundleError, match="Insufficient free space"):
        bundle.ensure_free_space(tmp_path, required_bytes=2)


def test_macos_orchestrator_offline_path_never_calls_curl(tmp_path: Path) -> None:
    root = tmp_path / "offline bundle"
    conda = root / "Core/Conda/install/install_macOS.sh"
    vscode = root / "Core/VsCode/install/install_macOS.sh"
    conda.parent.mkdir(parents=True)
    vscode.parent.mkdir(parents=True)
    marker = root / "ran.txt"
    conda.write_text(f"#!/bin/bash\necho conda >> {str(marker)!r}\n")
    vscode.write_text(f"#!/bin/bash\necho vscode >> {str(marker)!r}\n")

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    fake_curl = fake_bin / "curl"
    fake_curl.write_text("#!/bin/bash\necho network attempted >&2\nexit 99\n")
    fake_curl.chmod(0o755)

    environment = os.environ.copy()
    environment.update(
        {
            "PS_OFFLINE": "1",
            "PS_BUNDLE_ROOT": str(root),
            "PATH": f"{fake_bin}:{environment['PATH']}",
        }
    )
    result = subprocess.run(
        ["bash", str(bundle.REPO_ROOT / "Core/Orchestration/install_all_macOS.sh")],
        env=environment,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert marker.read_text().splitlines() == ["conda", "vscode"]
    assert "network attempted" not in result.stderr
