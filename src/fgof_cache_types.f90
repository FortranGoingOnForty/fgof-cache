module fgof_cache_types
  implicit none
  private

  integer, parameter, public :: FGOF_CACHE_OK = 0
  integer, parameter, public :: FGOF_CACHE_ERR_INVALID_OPTIONS = 10
  integer, parameter, public :: FGOF_CACHE_ERR_NOT_FOUND = 20
  integer, parameter, public :: FGOF_CACHE_ERR_IO = 30
  integer, parameter, public :: FGOF_CACHE_ERR_INTERNAL = 99

  type, public :: cache_options
    logical :: create_root = .true.
    character(len=:), allocatable :: root_dir
    character(len=:), allocatable :: namespace
  end type cache_options

  type, public :: cache_root
    logical :: ready = .false.
    integer :: error_code = FGOF_CACHE_OK
    character(len=:), allocatable :: path
    character(len=:), allocatable :: error_message
  end type cache_root

  type, public :: cache_entry
    logical :: present = .false.
    integer :: error_code = FGOF_CACHE_OK
    character(len=:), allocatable :: key
    character(len=:), allocatable :: root_path
    character(len=:), allocatable :: relative_path
    character(len=:), allocatable :: path
    character(len=:), allocatable :: error_message
  end type cache_entry

end module fgof_cache_types
