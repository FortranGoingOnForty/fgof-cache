program test_cache_io
  use fgof_cache, only : &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    clear_cache_options, &
    read_cache_text, &
    remove_cache_entry, &
    write_cache_text
  use fgof_cache_types, only : cache_entry, cache_options, cache_text_result
  implicit none

  type(cache_options) :: options
  type(cache_entry) :: entry
  type(cache_text_result) :: read_result
  character(len=:), allocatable :: root_path

  root_path = unique_root("io")
  options = clear_cache_options()
  options%root_dir = root_path
  options%namespace = "demo"

  entry = write_cache_text("alpha", "hello", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "write_cache_text should succeed for normal entries"
  if (.not. entry%present) error stop "write_cache_text should mark written entries as present"

  read_result = read_cache_text("alpha", options)
  if (read_result%error_code /= FGOF_CACHE_OK) error stop "read_cache_text should succeed after a write"
  if (.not. read_result%found) error stop "read_cache_text should mark stored entries as found"
  if (read_result%text /= "hello") error stop "read_cache_text should preserve the stored text"
  if (read_result%entry%path /= entry%path) error stop "read_cache_text should report the same entry path that write_cache_text created"

  entry = remove_cache_entry("alpha", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "remove_cache_entry should succeed for stored entries"
  if (entry%present) error stop "remove_cache_entry should clear presence on success"

  read_result = read_cache_text("alpha", options)
  if (read_result%error_code /= FGOF_CACHE_ERR_NOT_FOUND) error stop "removed entries should report not-found on later reads"
  if (read_result%found) error stop "removed entries should not still read as found"

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

end program test_cache_io
