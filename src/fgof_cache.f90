module fgof_cache
  use fgof_cache_posix, only : directory_exists_posix, ensure_directory_posix, path_exists_posix, remove_file_posix
  use fgof_temp, only : atomic_write
  use fgof_temp_types, only : write_result
  use fgof_cache_types, only : &
    FGOF_CACHE_ERR_INTERNAL, &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_IO, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    cache_entry, &
    cache_root, &
    cache_text_result, &
    cache_options
  implicit none
  private

  public :: &
    FGOF_CACHE_ERR_INTERNAL, &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_IO, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    cache_backend_name, &
    cache_entry, &
    cache_key_token, &
    cache_path_for_key, &
    cache_relative_path_for_key, &
    cache_root, &
    cache_text_result, &
    cache_error_name, &
    cache_options, &
    clear_cache_root, &
    clear_cache_entry, &
    clear_cache_text_result, &
    clear_cache_options, &
    ensure_cache_root, &
    read_cache_text, &
    remove_cache_entry, &
    write_cache_text, &
    resolve_cache_entry

contains

  function clear_cache_options() result(options)
    type(cache_options) :: options

    options%create_root = .true.
  end function clear_cache_options

  function clear_cache_root() result(root)
    type(cache_root) :: root

    root%ready = .false.
    root%error_code = FGOF_CACHE_OK
    root%path = ""
    root%error_message = ""
  end function clear_cache_root

  function clear_cache_entry() result(entry)
    type(cache_entry) :: entry

    entry%present = .false.
    entry%error_code = FGOF_CACHE_OK
    entry%key = ""
    entry%root_path = ""
    entry%relative_path = ""
    entry%path = ""
    entry%error_message = ""
  end function clear_cache_entry

  function clear_cache_text_result() result(result_value)
    type(cache_text_result) :: result_value

    result_value%found = .false.
    result_value%error_code = FGOF_CACHE_OK
    result_value%entry = clear_cache_entry()
    result_value%text = ""
    result_value%error_message = ""
  end function clear_cache_text_result

  function ensure_cache_root(options) result(root)
    type(cache_options), intent(in), optional :: options
    type(cache_root) :: root
    type(cache_options) :: local_options
    character(len=:), allocatable :: root_path
    integer :: sys_errno
    logical :: success

    local_options = merged_options(options)
    root = clear_cache_root()

    if (.not. validate_options(local_options, root)) return

    if (.not. resolved_root_path(local_options, root_path)) then
      call set_root_error(root, FGOF_CACHE_ERR_INVALID_OPTIONS, &
                          "unable to resolve cache root: set root_dir, XDG_CACHE_HOME, or HOME")
      return
    end if

    root%path = root_path

    if (local_options%create_root) then
      success = ensure_directory_posix(root_path, sys_errno)
      if (.not. success) then
        call set_root_error(root, FGOF_CACHE_ERR_IO, errno_message("cache root creation failed", sys_errno))
        return
      end if
    else
      if (.not. directory_exists_posix(root_path)) then
        call set_root_error(root, FGOF_CACHE_ERR_NOT_FOUND, "cache root does not exist")
        return
      end if
    end if

    if (.not. directory_exists_posix(root_path)) then
      call set_root_error(root, FGOF_CACHE_ERR_IO, "cache root exists but is not a directory")
      return
    end if

    root%ready = .true.
    root%error_code = FGOF_CACHE_OK
    root%error_message = ""
  end function ensure_cache_root

  function cache_key_token(key) result(token)
    character(len=*), intent(in) :: key
    character(len=:), allocatable :: token
    character(len=16), parameter :: hex_digits = "0123456789abcdef"
    integer :: byte_value
    integer :: i

    if (len(key) == 0) then
      token = ""
      return
    end if

    allocate(character(len=2 * len(key)) :: token)
    do i = 1, len(key)
      byte_value = iachar(key(i:i))
      token(2 * i - 1:2 * i - 1) = hex_digits(byte_value / 16 + 1:byte_value / 16 + 1)
      token(2 * i:2 * i) = hex_digits(mod(byte_value, 16) + 1:mod(byte_value, 16) + 1)
    end do
  end function cache_key_token

  function cache_relative_path_for_key(key) result(path)
    character(len=*), intent(in) :: key
    character(len=:), allocatable :: path
    character(len=:), allocatable :: token

    token = cache_key_token(key)
    if (len(token) == 0) then
      path = ""
      return
    end if

    path = join_path(join_path(shard_segment(token, 1), shard_segment(token, 3)), token)
  end function cache_relative_path_for_key

  function cache_path_for_key(root_path, key) result(path)
    character(len=*), intent(in) :: root_path
    character(len=*), intent(in) :: key
    character(len=:), allocatable :: path
    character(len=:), allocatable :: relative_path

    relative_path = cache_relative_path_for_key(key)
    if (len(relative_path) == 0) then
      path = ""
      return
    end if

    path = join_path(root_path, relative_path)
  end function cache_path_for_key

  function resolve_cache_entry(key, options) result(entry)
    character(len=*), intent(in) :: key
    type(cache_options), intent(in), optional :: options
    type(cache_entry) :: entry
    type(cache_root) :: root

    entry = clear_cache_entry()
    entry%key = key

    if (len(key) == 0) then
      call set_entry_error(entry, FGOF_CACHE_ERR_INVALID_OPTIONS, "cache key must not be empty")
      return
    end if

    root = ensure_cache_root(options)
    if (.not. root%ready) then
      entry%root_path = root%path
      call set_entry_error(entry, root%error_code, root%error_message)
      return
    end if

    entry%root_path = root%path
    entry%relative_path = cache_relative_path_for_key(key)
    entry%path = cache_path_for_key(root%path, key)
    entry%present = path_exists_posix(entry%path)
    entry%error_code = FGOF_CACHE_OK
    entry%error_message = ""
  end function resolve_cache_entry

  function write_cache_text(key, text, options) result(entry)
    character(len=*), intent(in) :: key
    character(len=*), intent(in) :: text
    type(cache_options), intent(in), optional :: options
    type(cache_entry) :: entry
    character(len=:), allocatable :: parent_path
    integer :: sys_errno
    logical :: success
    type(write_result) :: write_outcome

    entry = resolve_cache_entry(key, options)
    if (entry%error_code /= FGOF_CACHE_OK) return

    parent_path = parent_directory(entry%path)
    success = ensure_directory_posix(parent_path, sys_errno)
    if (.not. success) then
      call set_entry_error(entry, FGOF_CACHE_ERR_IO, errno_message("cache entry directory creation failed", sys_errno))
      return
    end if

    write_outcome = atomic_write(entry%path, text)
    if (.not. write_outcome%completed) then
      call set_entry_error(entry, FGOF_CACHE_ERR_IO, write_outcome%error_message)
      return
    end if

    entry%present = .true.
    entry%error_code = FGOF_CACHE_OK
    entry%error_message = ""
  end function write_cache_text

  function read_cache_text(key, options) result(result_value)
    character(len=*), intent(in) :: key
    type(cache_options), intent(in), optional :: options
    type(cache_text_result) :: result_value
    type(cache_entry) :: entry

    result_value = clear_cache_text_result()
    entry = resolve_read_entry(key, options)
    result_value%entry = entry

    if (entry%error_code /= FGOF_CACHE_OK) then
      result_value%error_code = entry%error_code
      result_value%error_message = entry%error_message
      return
    end if

    if (.not. entry%present) then
      result_value%error_code = FGOF_CACHE_ERR_NOT_FOUND
      result_value%error_message = "cache entry not found"
      return
    end if

    call read_text_file(entry%path, result_value%text, result_value%error_code, result_value%error_message)
    if (result_value%error_code /= FGOF_CACHE_OK) return

    result_value%found = .true.
    result_value%error_message = ""
  end function read_cache_text

  function remove_cache_entry(key, options) result(entry)
    character(len=*), intent(in) :: key
    type(cache_options), intent(in), optional :: options
    type(cache_entry) :: entry
    integer :: sys_errno
    logical :: success

    entry = resolve_read_entry(key, options)
    if (entry%error_code /= FGOF_CACHE_OK) return

    if (.not. entry%present) then
      call set_entry_error(entry, FGOF_CACHE_ERR_NOT_FOUND, "cache entry not found")
      return
    end if

    success = remove_file_posix(entry%path, sys_errno)
    if (.not. success) then
      call set_entry_error(entry, FGOF_CACHE_ERR_IO, errno_message("cache entry removal failed", sys_errno))
      return
    end if

    entry%present = .false.
    entry%error_code = FGOF_CACHE_OK
    entry%error_message = ""
  end function remove_cache_entry

  function cache_backend_name() result(name)
    character(len=:), allocatable :: name

    name = "posix"
  end function cache_backend_name

  function cache_error_name(code) result(name)
    integer, intent(in) :: code
    character(len=:), allocatable :: name

    select case (code)
    case (FGOF_CACHE_OK)
      name = "ok"
    case (FGOF_CACHE_ERR_INVALID_OPTIONS)
      name = "invalid-options"
    case (FGOF_CACHE_ERR_NOT_FOUND)
      name = "not-found"
    case (FGOF_CACHE_ERR_IO)
      name = "io"
    case (FGOF_CACHE_ERR_INTERNAL)
      name = "internal"
    case default
      name = "unknown"
    end select
  end function cache_error_name

  function resolve_read_entry(key, options) result(entry)
    character(len=*), intent(in) :: key
    type(cache_options), intent(in), optional :: options
    type(cache_entry) :: entry
    type(cache_options) :: local_options

    local_options = merged_options(options)
    local_options%create_root = .false.
    entry = resolve_cache_entry(key, local_options)
  end function resolve_read_entry

  function merged_options(options) result(local_options)
    type(cache_options), intent(in), optional :: options
    type(cache_options) :: local_options

    local_options = clear_cache_options()
    if (present(options)) local_options = options
  end function merged_options

  logical function validate_options(options, root) result(valid)
    type(cache_options), intent(in) :: options
    type(cache_root), intent(inout) :: root

    valid = .false.

    if (allocated(options%root_dir)) then
      if (len(options%root_dir) == 0) then
        call set_root_error(root, FGOF_CACHE_ERR_INVALID_OPTIONS, "root_dir must not be empty")
        return
      end if
    end if

    if (allocated(options%namespace)) then
      if (len(options%namespace) == 0) then
        call set_root_error(root, FGOF_CACHE_ERR_INVALID_OPTIONS, "namespace must not be empty")
        return
      end if
      if (index(options%namespace, "/") > 0) then
        call set_root_error(root, FGOF_CACHE_ERR_INVALID_OPTIONS, "namespace must not contain '/'")
        return
      end if
      if (options%namespace == "." .or. options%namespace == "..") then
        call set_root_error(root, FGOF_CACHE_ERR_INVALID_OPTIONS, "namespace must not be '.' or '..'")
        return
      end if
    end if

    valid = .true.
  end function validate_options

  logical function resolved_root_path(options, root_path) result(valid)
    type(cache_options), intent(in) :: options
    character(len=:), allocatable, intent(out) :: root_path
    character(len=:), allocatable :: base_path

    valid = .false.
    root_path = ""

    if (allocated(options%root_dir)) then
      base_path = options%root_dir
    else
      base_path = default_cache_base()
      if (.not. allocated(base_path)) return
    end if

    if (allocated(options%namespace)) then
      root_path = join_path(base_path, options%namespace)
    else if (allocated(options%root_dir)) then
      root_path = base_path
    else
      root_path = join_path(base_path, "fgof-cache")
    end if

    valid = .true.
  end function resolved_root_path

  function default_cache_base() result(base_path)
    character(len=:), allocatable :: base_path
    character(len=:), allocatable :: xdg_cache_home
    character(len=:), allocatable :: home

    xdg_cache_home = getenv_text("XDG_CACHE_HOME")
    if (allocated(xdg_cache_home)) then
      base_path = xdg_cache_home
      return
    end if

    home = getenv_text("HOME")
    if (allocated(home)) then
      base_path = join_path(home, ".cache")
    end if
  end function default_cache_base

  function getenv_text(name) result(value)
    character(len=*), intent(in) :: name
    character(len=:), allocatable :: value
    integer :: length
    integer :: status

    call get_environment_variable(name, length=length, status=status)
    if (status /= 0 .or. length <= 0) return

    allocate(character(len=length) :: value)
    call get_environment_variable(name, value, status=status)
    if (status /= 0) then
      deallocate(value)
    end if
  end function getenv_text

  function join_path(left, right) result(path)
    character(len=*), intent(in) :: left
    character(len=*), intent(in) :: right
    character(len=:), allocatable :: path

    if (len(left) == 0) then
      path = right
    else if (len(right) == 0) then
      path = left
    else if (left(len(left):len(left)) == "/") then
      path = left // right
    else
      path = left // "/" // right
    end if
  end function join_path

  function shard_segment(token, start_index) result(segment)
    character(len=*), intent(in) :: token
    integer, intent(in) :: start_index
    character(len=:), allocatable :: segment

    if (start_index > len(token)) then
      segment = "00"
    else if (start_index == len(token)) then
      segment = token(start_index:start_index) // "0"
    else
      segment = token(start_index:start_index + 1)
    end if
  end function shard_segment

  function parent_directory(path) result(parent)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: parent
    integer :: i
    integer :: slash_index

    slash_index = 0
    do i = len(path), 1, -1
      if (path(i:i) == "/") then
        slash_index = i
        exit
      end if
    end do

    if (slash_index == 0) then
      parent = "."
    else if (slash_index == 1) then
      parent = "/"
    else
      parent = path(:slash_index - 1)
    end if
  end function parent_directory

  subroutine read_text_file(path, text, error_code, error_message)
    character(len=*), intent(in) :: path
    character(len=:), allocatable, intent(out) :: text
    integer, intent(out) :: error_code
    character(len=:), allocatable, intent(out) :: error_message
    integer :: file_size
    integer :: ios
    integer :: unit
    character(len=256) :: iomsg

    error_code = FGOF_CACHE_OK
    error_message = ""

    inquire(file=path, size=file_size, iostat=ios, iomsg=iomsg)
    if (ios /= 0) then
      error_code = FGOF_CACHE_ERR_IO
      error_message = io_status_message("cache entry read failed while sizing file", ios, iomsg)
      text = ""
      return
    end if

    allocate(character(len=file_size) :: text)
    if (file_size == 0) return

    iomsg = ""
    open(newunit=unit, file=path, status="old", access="stream", form="unformatted", action="read", iostat=ios, iomsg=iomsg)
    if (ios /= 0) then
      error_code = FGOF_CACHE_ERR_IO
      error_message = io_status_message("cache entry read failed while opening file", ios, iomsg)
      deallocate(text)
      text = ""
      return
    end if

    iomsg = ""
    read(unit, iostat=ios, iomsg=iomsg) text
    if (ios /= 0) then
      close(unit)
      error_code = FGOF_CACHE_ERR_IO
      error_message = io_status_message("cache entry read failed while reading file", ios, iomsg)
      deallocate(text)
      text = ""
      return
    end if

    iomsg = ""
    close(unit, iostat=ios, iomsg=iomsg)
    if (ios /= 0) then
      error_code = FGOF_CACHE_ERR_IO
      error_message = io_status_message("cache entry read failed while closing file", ios, iomsg)
      deallocate(text)
      text = ""
    end if
  end subroutine read_text_file

  subroutine set_root_error(root, code, message)
    type(cache_root), intent(inout) :: root
    integer, intent(in) :: code
    character(len=*), intent(in) :: message

    root%ready = .false.
    root%error_code = code
    root%error_message = message
  end subroutine set_root_error

  subroutine set_entry_error(entry, code, message)
    type(cache_entry), intent(inout) :: entry
    integer, intent(in) :: code
    character(len=*), intent(in) :: message

    entry%present = .false.
    entry%error_code = code
    entry%error_message = message
  end subroutine set_entry_error

  function io_status_message(prefix, status_code, iomsg) result(message)
    character(len=*), intent(in) :: prefix
    integer, intent(in) :: status_code
    character(len=*), intent(in) :: iomsg
    character(len=:), allocatable :: message
    character(len=32) :: status_text

    write(status_text, "(i0)") status_code
    if (len_trim(iomsg) > 0) then
      message = prefix // " (iostat=" // trim(status_text) // ", " // trim(iomsg) // ")"
    else
      message = prefix // " (iostat=" // trim(status_text) // ")"
    end if
  end function io_status_message

  function errno_message(prefix, sys_errno) result(message)
    character(len=*), intent(in) :: prefix
    integer, intent(in) :: sys_errno
    character(len=:), allocatable :: message
    character(len=32) :: errno_text

    write(errno_text, "(i0)") sys_errno
    message = prefix // " (errno=" // trim(errno_text) // ")"
  end function errno_message

end module fgof_cache
