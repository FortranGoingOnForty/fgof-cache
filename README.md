# fgof-cache

Disk cache helpers for modern Fortran.

`fgof-cache` is intended to be a small, standalone library for cache
directories, cache entries, and repeatable on-disk storage flows that CLI tools
and local developer tooling keep hand-rolling.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules)
catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- stable cache option, root, and entry types
- predictable cache-root resolution and initialization
- explicit cache key and path helpers
- safe write-through and cleanup semantics built on `fgof-temp`

Future scope:

- TTL and invalidation helpers
- metadata-aware cache indexes
- cache pruning and size-budget policies

## Status

Sprint 01 is in place.

Tracked today:

- explicit cache root resolution with namespace support
- on-demand cache root initialization on POSIX backends
- deterministic key token and key-to-path helpers
- entry resolution helpers that expose root, relative path, and presence state
- focused coverage in `fpm test`
- CI on macOS and Ubuntu

## Why Use It

- cache logic shows up in tools, build helpers, editors, and local services
- most projects still re-solve naming, layout, and cleanup rules themselves
- a focused cache library can build naturally on the released temp and fs layers

## Public API Shape

Primary modules:

- `fgof_cache`
- `fgof_cache_types`

Public types:

- `cache_options`
- `cache_root`
- `cache_entry`

Public constants:

- `FGOF_CACHE_OK`
- `FGOF_CACHE_ERR_INVALID_OPTIONS`
- `FGOF_CACHE_ERR_NOT_FOUND`
- `FGOF_CACHE_ERR_IO`
- `FGOF_CACHE_ERR_INTERNAL`

Current public procedures:

- `clear_cache_options`
- `clear_cache_root`
- `clear_cache_entry`
- `ensure_cache_root`
- `cache_key_token`
- `cache_relative_path_for_key`
- `cache_path_for_key`
- `resolve_cache_entry`
- `cache_backend_name`
- `cache_error_name`

Current semantics:

- `ensure_cache_root()` resolves roots from explicit `root_dir`, or from `XDG_CACHE_HOME` / `HOME` when `root_dir` is absent
- explicit `namespace` values are appended as a subdirectory and validated up front
- `create_root=.true.` creates cache directories on demand; `create_root=.false.` requires the root to already exist
- `cache_key_token()` maps the exact Fortran character payload to a lowercase hex token
- `cache_relative_path_for_key()` shards tokens into a stable `aa/bb/fulltoken` layout
- `resolve_cache_entry()` gives callers the resolved root path, relative path, full path, and current presence state without forcing cache entry I/O yet

## Build And Test

```bash
fpm test
```

That is the baseline verification command locally and in CI.

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on cache ergonomics, not full database or state management
- should stay useful on its own even if future state-oriented packages build on top

## License

MIT
