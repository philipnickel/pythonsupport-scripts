"""HTTP download manager with atomic caching, resume support, and progress bars."""

from __future__ import annotations

import hashlib
import json
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit, urlunsplit

import httpx
from rich.progress import (
    BarColumn,
    DownloadColumn,
    Progress,
    SpinnerColumn,
    TextColumn,
    TimeRemainingColumn,
    TransferSpeedColumn,
)

RETRYABLE_STATUS = {408, 425, 429, 500, 502, 503, 504}


class BundleError(RuntimeError):
    """A user-facing build failure."""


@dataclass(frozen=True)
class DownloadResult:
    path: Path
    source_url: str
    resolved_url: str
    sha256: str
    size: int
    etag: str | None = None
    last_modified: str | None = None


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalized_url(url: str) -> str:
    parts = urlsplit(url)
    return urlunsplit((parts.scheme, parts.netloc, parts.path, "", ""))


class Downloader:
    def __init__(
        self,
        client: httpx.Client,
        *,
        max_retries: int = 5,
        retry_delay: float = 1.0,
        show_progress: bool = True,
    ) -> None:
        self.client = client
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self.show_progress = show_progress

    def _metadata_path(self, target: Path) -> Path:
        return target.with_suffix(target.suffix + ".json")

    def _valid_cached(
        self,
        target: Path,
        metadata: dict[str, Any],
        expected_sha256: str | None,
    ) -> bool:
        if not target.exists():
            return False
        if metadata.get("size") != target.stat().st_size:
            return False
        digest = sha256_file(target)
        if metadata.get("sha256") != digest:
            return False
        return not (expected_sha256 and digest.lower() != expected_sha256.lower())

    def _cached_result(self, target: Path, metadata: dict[str, Any]) -> DownloadResult:
        return DownloadResult(
            path=target,
            source_url=str(metadata["source_url"]),
            resolved_url=str(metadata["resolved_url"]),
            sha256=str(metadata["sha256"]),
            size=int(metadata["size"]),
            etag=metadata.get("etag"),
            last_modified=metadata.get("last_modified"),
        )

    def download(
        self,
        url: str,
        target: Path,
        *,
        expected_sha256: str | None = None,
        immutable: bool = False,
        refresh: bool = False,
    ) -> DownloadResult:
        target.parent.mkdir(parents=True, exist_ok=True)
        metadata_file = self._metadata_path(target)
        cached_meta: dict[str, Any] | None = None
        if metadata_file.exists() and not refresh:
            try:
                loaded = json.loads(metadata_file.read_text(encoding="utf-8"))
                if isinstance(loaded, dict):
                    cached_meta = loaded
            except (json.JSONDecodeError, OSError):
                cached_meta = None

        if cached_meta and self._valid_cached(target, cached_meta, expected_sha256):
            if immutable:
                return self._cached_result(target, cached_meta)
            headers = {}
            if cached_meta.get("etag"):
                headers["If-None-Match"] = str(cached_meta["etag"])
            if cached_meta.get("last_modified"):
                headers["If-Modified-Since"] = str(cached_meta["last_modified"])
            if headers:
                try:
                    head = self.client.head(url, headers=headers, follow_redirects=True)
                    if head.status_code == 304:
                        return self._cached_result(target, cached_meta)
                except httpx.HTTPError:
                    pass

        part_file = target.with_suffix(target.suffix + ".part")
        if refresh:
            part_file.unlink(missing_ok=True)

        filename = target.name
        for attempt in range(1, self.max_retries + 1):
            request_headers: dict[str, str] = {}
            initial_bytes = 0
            if part_file.exists() and not refresh:
                initial_bytes = part_file.stat().st_size
                if initial_bytes > 0:
                    request_headers["Range"] = f"bytes={initial_bytes}-"

            try:
                with self.client.stream(
                    "GET", url, headers=request_headers, follow_redirects=True
                ) as response:
                    if (
                        response.status_code in RETRYABLE_STATUS
                        and attempt < self.max_retries
                    ):
                        time.sleep(self.retry_delay * attempt)
                        continue
                    if response.status_code == 416:
                        # Range Not Satisfiable: file already completed or corrupt, restart
                        part_file.unlink(missing_ok=True)
                        initial_bytes = 0
                        continue
                    response.raise_for_status()

                    resuming = response.status_code == 206
                    write_mode = "ab" if resuming else "wb"
                    if not resuming and initial_bytes > 0:
                        initial_bytes = 0

                    content_length = response.headers.get("content-length")
                    total_bytes = (
                        initial_bytes + int(content_length)
                        if content_length and content_length.isdigit()
                        else None
                    )

                    progress = None
                    task_id = None
                    if self.show_progress:
                        progress = Progress(
                            SpinnerColumn(),
                            TextColumn("[bold blue]{task.fields[filename]}"),
                            BarColumn(bar_width=30),
                            "[progress.percentage]{task.percentage:>3.1f}%",
                            "•",
                            DownloadColumn(),
                            "•",
                            TransferSpeedColumn(),
                            "•",
                            TimeRemainingColumn(),
                        )
                        progress.start()
                        task_id = progress.add_task(
                            "download",
                            filename=filename,
                            total=total_bytes,
                            completed=initial_bytes,
                        )

                    try:
                        with part_file.open(write_mode) as handle:
                            for chunk in response.iter_bytes(chunk_size=512 * 1024):
                                handle.write(chunk)
                                if progress and task_id is not None:
                                    progress.update(task_id, advance=len(chunk))
                    finally:
                        if progress:
                            progress.stop()

                    calculated_sha256 = sha256_file(part_file)
                    if (
                        expected_sha256
                        and calculated_sha256.lower() != expected_sha256.lower()
                    ):
                        part_file.unlink(missing_ok=True)
                        raise BundleError(
                            f"Checksum mismatch for {url}: expected {expected_sha256}, "
                            f"got {calculated_sha256}"
                        )
                    part_file.replace(target)
                    result = DownloadResult(
                        path=target,
                        source_url=url,
                        resolved_url=str(response.url),
                        sha256=calculated_sha256,
                        size=target.stat().st_size,
                        etag=response.headers.get("etag"),
                        last_modified=response.headers.get("last_modified"),
                    )
                    metadata_file.write_text(
                        json.dumps(
                            {
                                "source_url": result.source_url,
                                "resolved_url": result.resolved_url,
                                "sha256": result.sha256,
                                "size": result.size,
                                "etag": result.etag,
                                "last_modified": result.last_modified,
                            },
                            indent=2,
                        )
                        + "\n",
                        encoding="utf-8",
                    )
                    return result
            except (httpx.HTTPError, OSError) as exc:
                if attempt >= self.max_retries:
                    raise BundleError(f"Failed to download {url}: {exc}") from exc
                time.sleep(self.retry_delay * attempt)
        raise BundleError(f"Exhausted retries for {url}")
