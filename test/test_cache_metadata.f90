program test_cache_metadata
  use iso_fortran_env, only : int64
  use fgof_cache, only : &
    FGOF_CACHE_OK, &
    cache_entry_is_stale, &
    clear_cache_options, &
    resolve_cache_entry, &
    write_cache_text
  use fgof_cache_types, only : cache_entry, cache_options
  implicit none

  type(cache_options) :: options
  type(cache_entry) :: entry
  character(len=:), allocatable :: root_path

  root_path = unique_root("metadata")
  options = clear_cache_options()
  options%root_dir = root_path
  options%namespace = "demo"

  entry = write_cache_text("alpha", "hello", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "write_cache_text should succeed before metadata checks"
  if (.not. entry%metadata_available) error stop "written entries should report metadata"
  if (entry%size_bytes /= 5_int64) error stop "entry metadata should report exact file size"
  if (entry%modified_time_seconds <= 0_int64) error stop "entry metadata should report a positive modified time"
  if (cache_entry_is_stale(entry, 3600_int64, entry%modified_time_seconds + 60_int64)) then
    error stop "fresh entries should not be stale when the reference time stays inside max_age_seconds"
  end if
  if (.not. cache_entry_is_stale(entry, 3600_int64, entry%modified_time_seconds + 4000_int64)) then
    error stop "entries should report stale once the reference time exceeds max_age_seconds"
  end if

  entry = resolve_cache_entry("alpha", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "resolve_cache_entry should succeed for stored entries"
  if (.not. entry%metadata_available) error stop "resolved entries should expose metadata for stored files"
  if (entry%size_bytes /= 5_int64) error stop "resolved entry metadata should report file size"

contains

  function unique_root(label) result(path)
    character(len=*), intent(in) :: label
    character(len=:), allocatable :: path
    character(len=32) :: count_text
    integer :: count_value

    call system_clock(count=count_value)
    write(count_text, "(i0)") count_value
    path = "build/fgof-cache-meta-" // label // "-" // trim(count_text)
  end function unique_root

end program test_cache_metadata
