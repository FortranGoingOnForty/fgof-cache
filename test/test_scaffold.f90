program test_scaffold
  use fgof_cache, only : &
    FGOF_CACHE_ERR_INTERNAL, &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_IO, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    cache_backend_name, &
    cache_error_name, &
    clear_cache_root, &
    clear_cache_entry, &
    clear_cache_options
  use fgof_cache_types, only : cache_entry, cache_options, cache_root
  implicit none

  type(cache_options) :: options
  type(cache_root) :: root
  type(cache_entry) :: entry

  options = clear_cache_options()
  if (.not. options%create_root) error stop "cache options should create roots by default"
  if (allocated(options%root_dir)) error stop "cache options should not allocate root_dir by default"
  if (allocated(options%namespace)) error stop "cache options should not allocate namespace by default"

  root = clear_cache_root()
  if (root%ready) error stop "cache root should start unready"
  if (root%error_code /= FGOF_CACHE_OK) error stop "cache root should start ok"
  if (root%path /= "") error stop "cache root should start with an empty path"
  if (root%error_message /= "") error stop "cache root should start with an empty message"

  entry = clear_cache_entry()
  if (entry%present) error stop "cache entry should start absent"
  if (entry%error_code /= FGOF_CACHE_OK) error stop "cache entry should start ok"
  if (entry%key /= "") error stop "cache entry should start with an empty key"
  if (entry%root_path /= "") error stop "cache entry should start with an empty root path"
  if (entry%relative_path /= "") error stop "cache entry should start with an empty relative path"
  if (entry%path /= "") error stop "cache entry should start with an empty path"
  if (entry%error_message /= "") error stop "cache entry should start with an empty message"

  if (cache_backend_name() /= "posix") error stop "backend helper should describe the current backend"
  if (cache_error_name(FGOF_CACHE_OK) /= "ok") error stop "error helper should map ok"
  if (cache_error_name(FGOF_CACHE_ERR_INVALID_OPTIONS) /= "invalid-options") error stop "error helper should map invalid options"
  if (cache_error_name(FGOF_CACHE_ERR_NOT_FOUND) /= "not-found") error stop "error helper should map not-found"
  if (cache_error_name(FGOF_CACHE_ERR_IO) /= "io") error stop "error helper should map io"
  if (cache_error_name(FGOF_CACHE_ERR_INTERNAL) /= "internal") error stop "error helper should map internal"
  if (cache_error_name(999) /= "unknown") error stop "error helper should map unknown codes"
end program test_scaffold
