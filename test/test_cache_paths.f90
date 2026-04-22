program test_cache_paths
  use fgof_cache, only : &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    cache_key_token, &
    cache_path_for_key, &
    cache_relative_path_for_key, &
    clear_cache_options, &
    resolve_cache_entry
  use fgof_cache_types, only : cache_entry, cache_options
  implicit none

  type(cache_options) :: options
  type(cache_entry) :: entry
  character(len=:), allocatable :: root_path

  if (cache_key_token("abc") /= "616263") error stop "cache_key_token should hex-encode bytes"
  if (cache_key_token("a ") /= "6120") error stop "cache_key_token should preserve trailing spaces"

  if (cache_relative_path_for_key("abc") /= "61/62/616263") error stop "relative path helper should shard tokenized keys"
  if (cache_path_for_key("/tmp/cache", "abc") /= "/tmp/cache/61/62/616263") error stop "path helper should join cache roots and sharded keys"

  root_path = unique_root("entry")
  options = clear_cache_options()
  options%root_dir = root_path
  options%namespace = "demo"
  entry = resolve_cache_entry("abc", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "entry resolution should succeed for normal keys"
  if (entry%present) error stop "fresh cache entries should not report present"
  if (entry%root_path /= root_path // "/demo") error stop "entry resolution should report the resolved root path"
  if (entry%relative_path /= "61/62/616263") error stop "entry resolution should expose the relative cache path"
  if (entry%path /= root_path // "/demo/61/62/616263") error stop "entry resolution should expose the full cache path"

  entry = resolve_cache_entry("", options)
  if (entry%error_code /= FGOF_CACHE_ERR_INVALID_OPTIONS) error stop "empty keys should be rejected"

  options = clear_cache_options()
  options%create_root = .false.
  options%root_dir = unique_root("missing-entry")
  entry = resolve_cache_entry("abc", options)
  if (entry%error_code /= FGOF_CACHE_ERR_NOT_FOUND) error stop "entry resolution should surface missing cache roots"

contains

  function unique_root(label) result(path)
    character(len=*), intent(in) :: label
    character(len=:), allocatable :: path
    character(len=32) :: count_text
    integer :: count_value

    call system_clock(count=count_value)
    write(count_text, "(i0)") count_value
    path = "build/fgof-cache-path-" // label // "-" // trim(count_text)
  end function unique_root

end program test_cache_paths
