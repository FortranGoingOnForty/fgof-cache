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
    clear_cache_prune_result, &
    clear_cache_text_result, &
    clear_cache_options
  use fgof_cache_types, only : cache_entry, cache_options, cache_prune_result, cache_root, cache_text_result
  implicit none

  type(cache_options) :: options
  type(cache_root) :: root
  type(cache_entry) :: entry
  type(cache_prune_result) :: prune_result
  type(cache_text_result) :: text_result

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
  if (entry%metadata_available) error stop "cache entry should start without metadata"
  if (entry%error_code /= FGOF_CACHE_OK) error stop "cache entry should start ok"
  if (entry%size_bytes /= 0) error stop "cache entry should start with zero size metadata"
  if (entry%modified_time_seconds /= 0) error stop "cache entry should start with zero modified time metadata"
  if (entry%key /= "") error stop "cache entry should start with an empty key"
  if (entry%root_path /= "") error stop "cache entry should start with an empty root path"
  if (entry%relative_path /= "") error stop "cache entry should start with an empty relative path"
  if (entry%path /= "") error stop "cache entry should start with an empty path"
  if (entry%error_message /= "") error stop "cache entry should start with an empty message"

  prune_result = clear_cache_prune_result()
  if (prune_result%completed) error stop "cache prune result should start incomplete"
  if (prune_result%error_code /= FGOF_CACHE_OK) error stop "cache prune result should start ok"
  if (prune_result%scanned_count /= 0) error stop "cache prune result should start with zero scanned count"
  if (prune_result%removed_count /= 0) error stop "cache prune result should start with zero removed count"
  if (prune_result%root_path /= "") error stop "cache prune result should start with an empty root path"
  if (prune_result%error_message /= "") error stop "cache prune result should start with an empty message"

  text_result = clear_cache_text_result()
  if (text_result%found) error stop "cache text result should start not found"
  if (text_result%error_code /= FGOF_CACHE_OK) error stop "cache text result should start ok"
  if (text_result%entry%error_code /= FGOF_CACHE_OK) error stop "cache text result should carry a cleared entry by default"
  if (text_result%text /= "") error stop "cache text result should start with empty text"
  if (text_result%error_message /= "") error stop "cache text result should start with an empty message"

  if (cache_backend_name() /= "posix") error stop "backend helper should describe the current backend"
  if (cache_error_name(FGOF_CACHE_OK) /= "ok") error stop "error helper should map ok"
  if (cache_error_name(FGOF_CACHE_ERR_INVALID_OPTIONS) /= "invalid-options") error stop "error helper should map invalid options"
  if (cache_error_name(FGOF_CACHE_ERR_NOT_FOUND) /= "not-found") error stop "error helper should map not-found"
  if (cache_error_name(FGOF_CACHE_ERR_IO) /= "io") error stop "error helper should map io"
  if (cache_error_name(FGOF_CACHE_ERR_INTERNAL) /= "internal") error stop "error helper should map internal"
  if (cache_error_name(999) /= "unknown") error stop "error helper should map unknown codes"
end program test_scaffold
