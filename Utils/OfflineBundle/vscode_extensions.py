"""VS Code extension resolution and downloads for offline installer bundles."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx

from .downloader import BundleError, Downloader, DownloadResult

MARKETPLACE_QUERY_URL = (
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
)
EXTENSION_PLATFORMS = ("darwin-arm64", "darwin-x64", "win32-x64", "win32-arm64")


@dataclass(frozen=True)
class MarketplaceVersion:
    extension_id: str
    version: str
    target_platform: str
    download_url: str


class MarketplaceClient:
    def __init__(self, client: httpx.Client) -> None:
        self.client = client
        self._query_cache: dict[str, list[dict[str, Any]]] = {}

    def _versions(self, extension_id: str) -> list[dict[str, Any]]:
        if extension_id in self._query_cache:
            return self._query_cache[extension_id]
        payload = {
            "filters": [
                {
                    "criteria": [{"filterType": 7, "value": extension_id}],
                    "pageNumber": 1,
                    "pageSize": 1,
                    "sortBy": 0,
                    "sortOrder": 0,
                }
            ],
            "assetTypes": ["Microsoft.VisualStudio.Services.VSIXPackage"],
            "flags": 914,
        }
        response = self.client.post(
            MARKETPLACE_QUERY_URL,
            headers={
                "Accept": "application/json;api-version=7.1-preview.1",
                "Content-Type": "application/json",
            },
            json=payload,
        )
        response.raise_for_status()
        try:
            extensions = response.json()["results"][0]["extensions"]
            versions = extensions[0]["versions"]
        except (KeyError, IndexError, TypeError) as exc:
            raise BundleError(f"Marketplace extension not found: {extension_id}") from exc
        if not isinstance(versions, list) or not versions:
            raise BundleError(f"Marketplace returned no versions for {extension_id}")
        self._query_cache[extension_id] = versions
        return versions

    def resolve(self, extension_id: str, platform_name: str) -> MarketplaceVersion:
        versions = self._versions(extension_id)
        candidates: list[tuple[int, dict[str, Any]]] = []
        for item in versions:
            target = item.get("targetPlatform") or "universal"
            if target == platform_name:
                candidates.append((0, item))
            elif target == "universal":
                candidates.append((1, item))
        if not candidates:
            available = sorted(
                {str(item.get("targetPlatform") or "universal") for item in versions}
            )
            raise BundleError(
                f"No {platform_name} or universal VSIX exists for {extension_id}; "
                f"available targets: {', '.join(available)}"
            )
        _, selected = min(candidates, key=lambda pair: pair[0])
        files = selected.get("files") or []
        download_url = next(
            (
                str(item["source"])
                for item in files
                if item.get("assetType") == "Microsoft.VisualStudio.Services.VSIXPackage"
                and item.get("source")
            ),
            "",
        )
        if not download_url:
            asset_uri = selected.get("assetUri")
            if asset_uri:
                download_url = (
                    str(asset_uri).rstrip("/")
                    + "/Microsoft.VisualStudio.Services.VSIXPackage"
                )
        if not download_url:
            raise BundleError(f"Marketplace returned no VSIX URL for {extension_id}")
        return MarketplaceVersion(
            extension_id=extension_id,
            version=str(selected["version"]),
            target_platform=str(selected.get("targetPlatform") or "universal"),
            download_url=download_url,
        )


def read_extension_ids(extensions_file: Path) -> list[str]:
    """Read clean extension IDs from an extensions.txt file."""
    lines: list[str] = []
    for line in extensions_file.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            lines.append(stripped.lower())
    return lines


def resolve_extensions(
    platform_name: str,
    marketplace: MarketplaceClient,
    downloader: Downloader,
    cache_dir: Path,
    extension_ids: list[str],
) -> list[tuple[MarketplaceVersion, DownloadResult]]:
    """Download required extensions for a specific platform, sharing universal packages."""
    resolved: list[tuple[MarketplaceVersion, DownloadResult]] = []
    for extension_id in extension_ids:
        normalized = extension_id.lower()
        marketplace_version = marketplace.resolve(normalized, platform_name)
        safe_id = normalized.replace("/", "_")
        target_folder = (
            "universal"
            if marketplace_version.target_platform == "universal"
            else platform_name
        )
        cache_path = (
            cache_dir
            / "extensions"
            / target_folder
            / f"{safe_id}-{marketplace_version.version}.vsix"
        )
        download = downloader.download(
            marketplace_version.download_url, cache_path, immutable=True
        )
        resolved.append((marketplace_version, download))
    return resolved
