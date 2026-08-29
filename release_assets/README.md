

# Release asset cache

`Utils/OfflineBundle/build_offline_bundle.py` manages its persistent downloads under
`release_assets/offline-cache/`. The cache is ignored by Git and keyed by the
resolved asset version and checksum.

Build or refresh the cache with:

```bash
uv run --locked Utils/OfflineBundle/build_offline_bundle.py
uv run --locked Utils/OfflineBundle/build_offline_bundle.py --refresh
```

The older `dtu-miniconda/` and `vsCode/` directories are development caches and
are not copied into generated bundles.
