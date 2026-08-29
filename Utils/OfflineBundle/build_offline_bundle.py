#!/usr/bin/env python3
"""Build a fully offline DTU Python Support installer bundle."""

from __future__ import annotations

import os
import plistlib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from pathlib import Path, PurePosixPath
from typing import Annotated, Any

import httpx
import typer
from rich.console import Console

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from Utils.OfflineBundle.downloader import (
    BundleError,
    Downloader,
    DownloadResult,
    normalized_url,
    sha256_file,
)
from Utils.OfflineBundle.vscode_extensions import (
    EXTENSION_PLATFORMS,
    MARKETPLACE_QUERY_URL,
    MarketplaceClient,
    MarketplaceVersion,
    read_extension_ids,
    resolve_extensions,
)

APP = typer.Typer(add_completion=False, no_args_is_help=False)
CONSOLE = Console()
GITHUB_RELEASE_API = (
    "https://api.github.com/repos/dtudk/pythonsupport-forge/releases/latest"
)
VSCODE_URLS = {
    "macos-universal": "https://update.code.visualstudio.com/latest/darwin-universal/stable",
    "windows-x64": "https://update.code.visualstudio.com/latest/win32-x64-user/stable",
    "windows-arm64": "https://update.code.visualstudio.com/latest/win32-arm64-user/stable",
}
MIN_FREE_BYTES = 4 * 1024**3
CHECKSUM_RE = re.compile(r"^([0-9a-fA-F]{64})(?:\s+[* ]?)(.+)?$")


@dataclass
class AssetRecord:
    name: str
    kind: str
    platform: str
    version: str
    source_url: str
    resolved_url: str
    bundled_path: str
    sha256: str
    size: int
    dependencies: list[str] = field(default_factory=list)
    upstream_sha256: str | None = None


def nearest_existing_parent(path: Path) -> Path:
    candidate = path.resolve()
    while not candidate.exists():
        if candidate.parent == candidate:
            raise BundleError(f"Cannot find an existing parent for {path}")
        candidate = candidate.parent
    return candidate


def ensure_free_space(path: Path, required_bytes: int = MIN_FREE_BYTES) -> None:
    parent = nearest_existing_parent(path)
    free = shutil.disk_usage(parent).free
    if free < required_bytes:
        required_gib = required_bytes / 1024**3
        free_gib = free / 1024**3
        raise BundleError(
            f"Insufficient free space near {path}: {free_gib:.1f} GiB available; "
            f"at least {required_gib:.1f} GiB is required"
        )


def run_git(*args: str, repo_root: Path = REPO_ROOT) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise BundleError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout.strip()


def require_clean_worktree(repo_root: Path = REPO_ROOT) -> None:
    status = run_git("status", "--porcelain", repo_root=repo_root)
    if status:
        lines = [line for line in status.splitlines() if not line.endswith(".part")]
        if lines:
            raise BundleError(
                "Building an offline bundle requires a clean worktree at HEAD.\n"
                + "\n".join(lines)
            )


def github_headers() -> dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "dtudk-pythonsupport-bundle-builder",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def fetch_latest_miniforge_release(client: httpx.Client) -> dict[str, Any]:
    response = client.get(GITHUB_RELEASE_API, headers=github_headers(), follow_redirects=True)
    response.raise_for_status()
    payload = response.json()
    if not isinstance(payload, dict) or "assets" not in payload:
        raise BundleError("Unexpected GitHub release payload structure")
    return payload


def select_miniforge_assets(release: dict[str, Any]) -> list[dict[str, str]]:
    assets = {
        item["name"]: item["browser_download_url"]
        for item in release.get("assets", [])
        if "name" in item and "browser_download_url" in item
    }
    expected = (
        ("macos-arm64", "MacOSX-arm64.sh"),
        ("macos-x86_64", "MacOSX-x86_64.sh"),
        ("windows-x64", "Windows-x86_64.exe"),
    )
    selected: list[dict[str, str]] = []
    for platform_name, suffix in expected:
        asset_name = next(
            (name for name in assets if name.endswith(suffix) and not name.endswith(".sha256")),
            None,
        )
        if not asset_name:
            raise BundleError(f"Release is missing asset for {platform_name} (*{suffix})")
        checksum_name = next(
            (name for name in assets if name.endswith(f"{suffix}.sha256")),
            None,
        )
        selected.append(
            {
                "platform": platform_name,
                "asset_name": asset_name,
                "asset_url": assets[asset_name],
                "checksum_name": checksum_name or "",
                "checksum_url": assets[checksum_name] if checksum_name else "",
            }
        )
    return selected


def parse_checksum_file(path: Path) -> str:
    for line in path.read_text(encoding="utf-8").splitlines():
        match = CHECKSUM_RE.match(line.strip())
        if match:
            return match.group(1).lower()
    raise BundleError(f"No SHA-256 checksum found in {path}")


def vscode_version_from_archive(path: Path) -> str:
    with zipfile.ZipFile(path) as archive:
        candidates = [
            name
            for name in archive.namelist()
            if name.endswith("Visual Studio Code.app/Contents/Info.plist")
        ]
        if len(candidates) != 1:
            raise BundleError(f"Cannot locate VS Code Info.plist in {path}")
        data = plistlib.loads(archive.read(candidates[0]))
    version = data.get("CFBundleShortVersionString")
    if not isinstance(version, str) or not version:
        raise BundleError(f"Could not extract CFBundleShortVersionString from {path}")
    return version


def export_git_head(destination: Path, repo_root: Path = REPO_ROOT) -> None:
    archive_path = destination.parent / "repository.tar"
    result = subprocess.run(
        ["git", "archive", "--format=tar", "--output", str(archive_path), "HEAD"],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise BundleError(result.stderr.strip() or "git archive failed")
    destination.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive_path) as archive:
        archive.extractall(destination, filter="data")
    archive_path.unlink()


def copy_download(download: DownloadResult, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(download.path, destination)


def write_json(path: Path, data: Any) -> None:
    path.write_text(
        json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def relative_files(root: Path) -> list[Path]:
    return sorted(
        (path.relative_to(root) for path in root.rglob("*") if path.is_file()),
        key=lambda path: path.as_posix(),
    )


def create_deterministic_zip(source_root: Path, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temp_output = output_path.with_suffix(output_path.suffix + ".part")
    temp_output.unlink(missing_ok=True)
    archive_root = source_root.name
    try:
        with zipfile.ZipFile(
            temp_output,
            "w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=9,
            allowZip64=True,
        ) as archive:
            for relative_path in relative_files(source_root):
                source_path = source_root / relative_path
                archive_name = str(PurePosixPath(archive_root) / relative_path.as_posix())
                info = zipfile.ZipInfo(archive_name, date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                mode = source_path.stat().st_mode & 0o777
                info.external_attr = (0o100000 | mode) << 16
                info.flag_bits |= 0x800
                with source_path.open("rb") as source, archive.open(info, "w") as target:
                    shutil.copyfileobj(source, target, length=1024 * 1024)
        temp_output.replace(output_path)
    except Exception:
        temp_output.unlink(missing_ok=True)
        raise


def validate_bundle_zip(path: Path, archive_root: str) -> None:
    with zipfile.ZipFile(path) as archive:
        bad_file = archive.testzip()
        if bad_file:
            raise BundleError(f"ZIP integrity failure: {bad_file}")
        prefix = archive_root.rstrip("/") + "/"
        names = archive.namelist()
        if not names or any(not name.startswith(prefix) for name in names):
            raise BundleError("ZIP must contain exactly one top-level bundle directory")


def build_bundle(
    *,
    output_dir: Path,
    cache_dir: Path,
    platform: str = "all",
    refresh: bool = False,
    keep_staging: bool = False,
    verbose: bool = False,
    repo_root: Path = REPO_ROOT,
) -> Path:
    require_clean_worktree(repo_root)
    ensure_free_space(output_dir)
    ensure_free_space(cache_dir)
    staging_parent = Path(tempfile.mkdtemp(prefix="dtu-offline-bundle-"))
    ensure_free_space(staging_parent)
    success = False
    try:
        git_commit = run_git("rev-parse", "HEAD", repo_root=repo_root)
        git_sha = run_git("rev-parse", "--short", "HEAD", repo_root=repo_root)
        date_stamp = datetime.now(UTC).strftime("%Y.%m.%d")

        target_platform = platform.lower()
        if target_platform == "current":
            target_platform = "macos" if sys.platform == "darwin" else "windows"

        if target_platform == "macos":
            bundle_name = f"DTU-Python-Support-Offline-macOS-{date_stamp}-{git_sha}"
            miniforge_filter = lambda plat: plat.startswith("macos")
            vscode_filter = lambda plat: plat.startswith("macos")
            extension_filter = lambda plat: plat.startswith("darwin")
        elif target_platform == "windows":
            bundle_name = f"DTU-Python-Support-Offline-Windows-{date_stamp}-{git_sha}"
            miniforge_filter = lambda plat: plat.startswith("windows")
            vscode_filter = lambda plat: plat.startswith("windows")
            extension_filter = lambda plat: plat.startswith("win32")
        else:
            bundle_name = f"DTU-Python-Support-Offline-{date_stamp}-{git_sha}"
            miniforge_filter = lambda plat: True
            vscode_filter = lambda plat: True
            extension_filter = lambda plat: True

        bundle_root = staging_parent / bundle_name

        CONSOLE.print(f"[bold]Exporting repository at {git_sha}...[/bold]")
        export_git_head(bundle_root, repo_root=repo_root)

        with httpx.Client(timeout=60.0, follow_redirects=True) as client:
            downloader = Downloader(client)
            records: list[AssetRecord] = []

            CONSOLE.print("[bold]Resolving DTU Miniforge release...[/bold]")
            miniforge_release = fetch_latest_miniforge_release(client)
            miniforge_version = str(miniforge_release.get("tag_name") or "latest")
            miniforge_targets = [
                t for t in select_miniforge_assets(miniforge_release)
                if miniforge_filter(t["platform"])
            ]
            for item in miniforge_targets:
                upstream_sha256 = None
                if item["checksum_url"]:
                    checksum_download = downloader.download(
                        item["checksum_url"],
                        cache_dir / "miniforge" / miniforge_version / item["checksum_name"],
                        refresh=refresh,
                    )
                    upstream_sha256 = parse_checksum_file(checksum_download.path)
                download = downloader.download(
                    item["asset_url"],
                    cache_dir / "miniforge" / miniforge_version / item["asset_name"],
                    expected_sha256=upstream_sha256,
                    immutable=True,
                    refresh=refresh,
                )
                bundled_ext = Path(item["asset_name"]).suffix
                bundled_path = (
                    f"bundle_assets/miniforge/{item['platform']}/Miniforge3{bundled_ext}"
                )
                copy_download(download, bundle_root / bundled_path)
                records.append(
                    AssetRecord(
                        name="DTU Miniforge",
                        kind="miniforge",
                        platform=item["platform"],
                        version=miniforge_version,
                        source_url=download.source_url,
                        resolved_url=download.resolved_url,
                        bundled_path=bundled_path,
                        sha256=download.sha256,
                        size=download.size,
                        upstream_sha256=upstream_sha256,
                    )
                )

            CONSOLE.print("[bold]Downloading stable VS Code...[/bold]")
            vscode_downloads: dict[str, DownloadResult] = {}
            filtered_vscode_urls = {
                plat: url for plat, url in VSCODE_URLS.items() if vscode_filter(plat)
            }
            for platform_name, url in filtered_vscode_urls.items():
                suffix = ".zip" if platform_name == "macos-universal" else ".exe"
                download = downloader.download(
                    url, cache_dir / "vscode" / platform_name / f"VSCode{suffix}"
                )
                vscode_downloads[platform_name] = download

            if "macos-universal" in vscode_downloads:
                vscode_version = vscode_version_from_archive(
                    vscode_downloads["macos-universal"].path
                )
            else:
                vscode_version = "latest"

            for platform_name, download in vscode_downloads.items():
                suffix = ".zip" if platform_name == "macos-universal" else ".exe"
                bundled_path = f"bundle_assets/vscode/{platform_name}/VSCode{suffix}"
                copy_download(download, bundle_root / bundled_path)
                records.append(
                    AssetRecord(
                        name="Visual Studio Code",
                        kind="vscode",
                        platform=platform_name,
                        version=vscode_version,
                        source_url=download.source_url,
                        resolved_url=download.resolved_url,
                        bundled_path=bundled_path,
                        sha256=download.sha256,
                        size=download.size,
                    )
                )

            CONSOLE.print("[bold]Resolving offline VS Code extensions...[/bold]")
            marketplace = MarketplaceClient(client)
            extension_ids = read_extension_ids(repo_root / "Core/VsCode/config/extensions.txt")
            filtered_extension_platforms = [
                plat for plat in EXTENSION_PLATFORMS if extension_filter(plat)
            ]
            for platform_name in filtered_extension_platforms:
                extensions = resolve_extensions(
                    platform_name,
                    marketplace,
                    downloader,
                    cache_dir,
                    extension_ids,
                )
                index_lines: list[str] = []
                for marketplace_version, download in extensions:
                    filename = f"{marketplace_version.extension_id}-{marketplace_version.version}.vsix"
                    target_folder = (
                        "universal"
                        if marketplace_version.target_platform == "universal"
                        else platform_name
                    )
                    bundled_path = f"bundle_assets/extensions/{target_folder}/{filename}"
                    copy_download(download, bundle_root / bundled_path)
                    index_lines.append(bundled_path)
                    records.append(
                        AssetRecord(
                            name=marketplace_version.extension_id,
                            kind="vscode-extension",
                            platform=platform_name,
                            version=marketplace_version.version,
                            source_url=download.source_url,
                            resolved_url=download.resolved_url,
                            bundled_path=bundled_path,
                            sha256=download.sha256,
                            size=download.size,
                        )
                    )
                index_path = (
                    bundle_root / "bundle_assets" / "extensions" / platform_name / "index.txt"
                )
                index_path.parent.mkdir(parents=True, exist_ok=True)
                index_path.write_text("\n".join(index_lines) + "\n", encoding="utf-8")

            manifest = {
                "schema_version": 1,
                "bundle_name": bundle_name,
                "built_at": datetime.now(UTC).isoformat(),
                "repository": {
                    "commit": git_commit,
                    "short_commit": git_sha,
                },
                "target_platform": target_platform,
                "vscode_version": vscode_version,
                "assets": [asdict(record) for record in records],
            }
            write_json(bundle_root / "bundle-manifest.json", manifest)

            output_dir.mkdir(parents=True, exist_ok=True)
            output_path = output_dir / f"{bundle_name}.zip"
            CONSOLE.print(f"[bold]Creating {output_path.name}...[/bold]")
            create_deterministic_zip(bundle_root, output_path)
            validate_bundle_zip(output_path, bundle_name)
            success = True
            return output_path
    except httpx.HTTPError as exc:
        raise BundleError(f"HTTP request failed: {exc}") from exc
    finally:
        if success or not keep_staging:
            shutil.rmtree(staging_parent, ignore_errors=True)
        elif verbose or keep_staging:
            CONSOLE.print(f"[yellow]Retained staging directory: {staging_parent}[/yellow]")


@APP.command()
def main(
    output_dir: Annotated[Path, typer.Option(help="ZIP output directory")] = Path("dist"),
    cache_dir: Annotated[
        Path, typer.Option(help="Persistent download cache")
    ] = Path("release_assets/offline-cache"),
    platform: Annotated[
        str,
        typer.Option(
            "--platform",
            "-p",
            help="Target platform bundle: 'all', 'macos', 'windows', or 'current'",
        ),
    ] = "all",
    refresh: Annotated[bool, typer.Option(help="Redownload all assets")] = False,
    keep_staging: Annotated[
        bool, typer.Option(help="Keep the staging directory when a build fails")
    ] = False,
    verbose: Annotated[
        bool, typer.Option("--verbose", "-v", help="Show diagnostics")
    ] = False,
) -> None:
    """Build a fully offline installer ZIP."""
    resolved_output = output_dir if output_dir.is_absolute() else REPO_ROOT / output_dir
    resolved_cache = cache_dir if cache_dir.is_absolute() else REPO_ROOT / cache_dir
    try:
        output_path = build_bundle(
            output_dir=resolved_output,
            cache_dir=resolved_cache,
            platform=platform,
            refresh=refresh,
            keep_staging=keep_staging,
            verbose=verbose,
        )
    except BundleError as exc:
        CONSOLE.print(f"[bold red]Build failed:[/bold red] {exc}")
        raise typer.Exit(1) from exc
    CONSOLE.print(f"[bold green]Offline bundle created:[/bold green] {output_path}")


if __name__ == "__main__":
    APP()
