module fgof_cache
  use fgof_cache_types, only : &
    FGOF_CACHE_ERR_INTERNAL, &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_IO, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    cache_entry, &
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
    cache_error_name, &
    cache_options, &
    clear_cache_entry, &
    clear_cache_options

contains

  function clear_cache_options() result(options)
    type(cache_options) :: options

    options%create_root = .true.
  end function clear_cache_options

  function clear_cache_entry() result(entry)
    type(cache_entry) :: entry

    entry%present = .false.
    entry%error_code = FGOF_CACHE_OK
    entry%key = ""
    entry%path = ""
    entry%error_message = ""
  end function clear_cache_entry

  function cache_backend_name() result(name)
    character(len=:), allocatable :: name

    name = "scaffold"
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

end module fgof_cache
