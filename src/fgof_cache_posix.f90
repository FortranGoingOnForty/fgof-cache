module fgof_cache_posix
  use iso_c_binding, only : c_char, c_int, c_long_long, c_null_char
  use iso_fortran_env, only : int64
  implicit none
  private

  public :: &
    current_time_seconds_posix, &
    directory_exists_posix, &
    ensure_directory_posix, &
    path_exists_posix, &
    prune_stale_posix, &
    remove_file_posix, &
    stat_path_posix

  interface
    integer(c_int) function fgof_cache_directory_exists(path) bind(c, name="fgof_cache_directory_exists")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
    end function fgof_cache_directory_exists

    integer(c_int) function fgof_cache_ensure_directory(path, error_code) bind(c, name="fgof_cache_ensure_directory")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
      integer(c_int), intent(out) :: error_code
    end function fgof_cache_ensure_directory

    integer(c_int) function fgof_cache_path_exists(path) bind(c, name="fgof_cache_path_exists")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
    end function fgof_cache_path_exists

    integer(c_int) function fgof_cache_remove_file(path, error_code) bind(c, name="fgof_cache_remove_file")
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
      integer(c_int), intent(out) :: error_code
    end function fgof_cache_remove_file

    integer(c_int) function fgof_cache_stat_path(path, size_bytes, modified_time_seconds, error_code) &
      bind(c, name="fgof_cache_stat_path")
      import :: c_char, c_int, c_long_long
      character(kind=c_char), intent(in) :: path(*)
      integer(c_long_long), intent(out) :: size_bytes
      integer(c_long_long), intent(out) :: modified_time_seconds
      integer(c_int), intent(out) :: error_code
    end function fgof_cache_stat_path

    integer(c_int) function fgof_cache_prune_stale(path, cutoff_seconds, scanned_count, removed_count, error_code) &
      bind(c, name="fgof_cache_prune_stale")
      import :: c_char, c_int, c_long_long
      character(kind=c_char), intent(in) :: path(*)
      integer(c_long_long), value :: cutoff_seconds
      integer(c_long_long), intent(out) :: scanned_count
      integer(c_long_long), intent(out) :: removed_count
      integer(c_int), intent(out) :: error_code
    end function fgof_cache_prune_stale

    integer(c_long_long) function fgof_cache_now_seconds() bind(c, name="fgof_cache_now_seconds")
      import :: c_long_long
    end function fgof_cache_now_seconds
  end interface

contains

  logical function path_exists_posix(path) result(exists)
    character(len=*), intent(in) :: path
    character(kind=c_char), allocatable :: c_path(:)

    if (len(path) == 0) then
      exists = .false.
      return
    end if

    c_path = to_c_string(path)
    exists = (fgof_cache_path_exists(c_path) /= 0_c_int)
  end function path_exists_posix

  logical function directory_exists_posix(path) result(exists)
    character(len=*), intent(in) :: path
    character(kind=c_char), allocatable :: c_path(:)

    if (len(path) == 0) then
      exists = .false.
      return
    end if

    c_path = to_c_string(path)
    exists = (fgof_cache_directory_exists(c_path) /= 0_c_int)
  end function directory_exists_posix

  logical function ensure_directory_posix(path, error_code) result(success)
    character(len=*), intent(in) :: path
    integer, intent(out) :: error_code
    character(kind=c_char), allocatable :: c_path(:)
    integer(c_int) :: c_error

    if (len(path) == 0) then
      error_code = 22
      success = .false.
      return
    end if

    c_path = to_c_string(path)
    success = (fgof_cache_ensure_directory(c_path, c_error) /= 0_c_int)
    error_code = c_error
  end function ensure_directory_posix

  logical function remove_file_posix(path, error_code) result(success)
    character(len=*), intent(in) :: path
    integer, intent(out) :: error_code
    character(kind=c_char), allocatable :: c_path(:)
    integer(c_int) :: c_error

    if (len(path) == 0) then
      error_code = 22
      success = .false.
      return
    end if

    c_path = to_c_string(path)
    success = (fgof_cache_remove_file(c_path, c_error) /= 0_c_int)
    error_code = c_error
  end function remove_file_posix

  logical function stat_path_posix(path, size_bytes, modified_time_seconds, error_code) result(success)
    character(len=*), intent(in) :: path
    integer(int64), intent(out) :: size_bytes
    integer(int64), intent(out) :: modified_time_seconds
    integer, intent(out) :: error_code
    character(kind=c_char), allocatable :: c_path(:)
    integer(c_long_long) :: c_size_bytes
    integer(c_long_long) :: c_modified_time_seconds
    integer(c_int) :: c_error

    size_bytes = 0_int64
    modified_time_seconds = 0_int64

    if (len(path) == 0) then
      error_code = 22
      success = .false.
      return
    end if

    c_path = to_c_string(path)
    success = (fgof_cache_stat_path(c_path, c_size_bytes, c_modified_time_seconds, c_error) /= 0_c_int)
    size_bytes = int(c_size_bytes, int64)
    modified_time_seconds = int(c_modified_time_seconds, int64)
    error_code = c_error
  end function stat_path_posix

  logical function prune_stale_posix(path, cutoff_seconds, scanned_count, removed_count, error_code) result(success)
    character(len=*), intent(in) :: path
    integer(int64), intent(in) :: cutoff_seconds
    integer(int64), intent(out) :: scanned_count
    integer(int64), intent(out) :: removed_count
    integer, intent(out) :: error_code
    character(kind=c_char), allocatable :: c_path(:)
    integer(c_long_long) :: c_scanned_count
    integer(c_long_long) :: c_removed_count
    integer(c_int) :: c_error

    scanned_count = 0_int64
    removed_count = 0_int64

    if (len(path) == 0) then
      error_code = 22
      success = .false.
      return
    end if

    c_path = to_c_string(path)
    success = (fgof_cache_prune_stale(c_path, int(cutoff_seconds, c_long_long), &
                                      c_scanned_count, c_removed_count, c_error) /= 0_c_int)
    scanned_count = int(c_scanned_count, int64)
    removed_count = int(c_removed_count, int64)
    error_code = c_error
  end function prune_stale_posix

  function current_time_seconds_posix() result(seconds)
    integer(int64) :: seconds

    seconds = int(fgof_cache_now_seconds(), int64)
  end function current_time_seconds_posix

  function to_c_string(text) result(c_text)
    character(len=*), intent(in) :: text
    character(kind=c_char), allocatable :: c_text(:)
    integer :: i

    allocate(c_text(0:len(text)))
    do i = 1, len(text)
      c_text(i - 1) = text(i:i)
    end do
    c_text(len(text)) = c_null_char
  end function to_c_string

end module fgof_cache_posix
