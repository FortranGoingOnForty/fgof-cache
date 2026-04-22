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

- richer invalidation policies and size-budget pruning
- metadata-aware cache indexes
- binary payload helpers and more entry formats

## Status

Sprint 04 is in place.

Tracked today:

- explicit cache root resolution with namespace support
- on-demand cache root initialization on POSIX backends
- deterministic key token and key-to-path helpers
- text-focused cache entry write, read, and remove helpers
- entry resolution helpers that expose root, relative path, presence state, and file metadata
- deterministic stale checks with optional explicit reference times
- namespace-aware stale-entry pruning helpers
- tracked round-trip and prune examples
- `fgof-temp`-backed write-through safety for cache writes
- focused coverage in `fpm test`
- CI on macOS and Ubuntu, including direct example execution

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
- `cache_prune_result`
- `cache_text_result`

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
- `clear_cache_prune_result`
- `ensure_cache_root`
- `cache_key_token`
- `cache_relative_path_for_key`
- `cache_path_for_key`
- `resolve_cache_entry`
- `cache_entry_is_stale`
- `clear_cache_text_result`
- `prune_stale_cache`
- `write_cache_text`
- `read_cache_text`
- `remove_cache_entry`
- `cache_backend_name`
- `cache_error_name`

Current semantics:

- `ensure_cache_root()` resolves roots from explicit `root_dir`, or from `XDG_CACHE_HOME` / `HOME` when `root_dir` is absent
- explicit `namespace` values are appended as a subdirectory and validated up front
- `create_root=.true.` creates cache directories on demand; `create_root=.false.` requires the root to already exist
- `cache_key_token()` maps the exact Fortran character payload to a lowercase hex token
- `cache_relative_path_for_key()` shards tokens into a stable `aa/bb/fulltoken` layout
- `resolve_cache_entry()` gives callers the resolved root path, relative path, full path, current presence state, and metadata for stored entries
- `cache_entry_is_stale()` lets callers make deterministic TTL-style decisions, with an optional explicit reference time for tests and batch logic
- `write_cache_text()` creates sharded parent directories as needed and writes through `fgof-temp` atomic replacement
- `read_cache_text()` reads exact stored Fortran character payloads back out of cache entries
- `read_cache_text()` and `remove_cache_entry()` do not create missing cache roots as a side effect
- `remove_cache_entry()` removes stored cache files by key while leaving the cache root in place
- successful removals clear cached metadata on the returned entry
- `prune_stale_cache()` prunes only the resolved namespace root, treats missing roots as a no-op, and removes emptied shard directories as it goes

## Build And Test

```bash
fpm test
```

That is the baseline verification command locally and in CI.

Tracked examples:

- [cache_roundtrip_demo.f90](example/cache_roundtrip_demo.f90)
- [cache_prune_demo.f90](example/cache_prune_demo.f90)

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on cache ergonomics, not full database or state management
- should stay useful on its own even if future state-oriented packages build on top

## License

MIT
