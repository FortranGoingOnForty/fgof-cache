program test_cache_io_edges
  use fgof_cache, only : &
    FGOF_CACHE_ERR_IO, &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    clear_cache_options, &
    read_cache_text, &
    resolve_cache_entry, &
    remove_cache_entry, &
    write_cache_text
  use fgof_cache_types, only : cache_entry, cache_options, cache_text_result
  use fgof_cache_posix, only : ensure_directory_posix
  implicit none

  type(cache_options) :: options
  type(cache_entry) :: entry
  type(cache_text_result) :: read_result
  character(len=:), allocatable :: root_path
  logical :: exists
  integer :: sys_errno
  logical :: success

  root_path = unique_root("edges")
  options = clear_cache_options()
  options%root_dir = root_path
  options%namespace = "demo"

  entry = write_cache_text("", "hello", options)
  if (entry%error_code /= FGOF_CACHE_ERR_INVALID_OPTIONS) error stop "write_cache_text should reject empty keys"

  read_result = read_cache_text("missing", options)
  if (read_result%error_code /= FGOF_CACHE_ERR_NOT_FOUND) error stop "read_cache_text should treat missing roots as not-found"
  inquire(file=root_path // "/demo", exist=exists)
  if (exists) error stop "read_cache_text should not create cache roots while probing for missing entries"

  entry = remove_cache_entry("missing", options)
  if (entry%error_code /= FGOF_CACHE_ERR_NOT_FOUND) error stop "remove_cache_entry should report not-found for missing entries"
  inquire(file=root_path // "/demo", exist=exists)
  if (exists) error stop "remove_cache_entry should not create cache roots while probing for missing entries"

  entry = write_cache_text("a ", "trail ", options)
  if (entry%error_code /= 0) error stop "write_cache_text should accept keys and payloads with trailing spaces"
  read_result = read_cache_text("a ", options)
  if (read_result%error_code /= 0) error stop "read_cache_text should read entries with trailing-space keys"
  if (read_result%text /= "trail ") error stop "cache entry text should preserve trailing spaces"

  entry = resolve_cache_entry("dirkey", options)
  if (entry%error_code /= 0) error stop "resolve_cache_entry should succeed before non-file path tests"
  success = ensure_directory_posix(entry%path, sys_errno)
  if (.not. success) error stop "non-file path setup should be able to create a directory at the cache entry path"

  read_result = read_cache_text("dirkey", options)
  if (read_result%error_code /= FGOF_CACHE_ERR_IO) error stop "read_cache_text should reject non-file cache entry paths"

  entry = remove_cache_entry("dirkey", options)
  if (entry%error_code /= FGOF_CACHE_ERR_IO) error stop "remove_cache_entry should reject non-file cache entry paths"

  entry = write_cache_text("dirkey", "hello", options)
  if (entry%error_code /= FGOF_CACHE_ERR_IO) error stop "write_cache_text should reject non-file cache entry paths"

contains

  function unique_root(label) result(path)
    character(len=*), intent(in) :: label
    character(len=:), allocatable :: path
    character(len=32) :: count_text
    integer :: count_value

    call system_clock(count=count_value)
    write(count_text, "(i0)") count_value
    path = "build/fgof-cache-io-" // label // "-" // trim(count_text)
  end function unique_root

end program test_cache_io_edges
