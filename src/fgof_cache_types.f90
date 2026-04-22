module fgof_cache_types
  use iso_fortran_env, only : int64
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
    logical :: metadata_available = .false.
    integer :: error_code = FGOF_CACHE_OK
    integer(int64) :: size_bytes = 0_int64
    integer(int64) :: modified_time_seconds = 0_int64
    character(len=:), allocatable :: key
    character(len=:), allocatable :: root_path
    character(len=:), allocatable :: relative_path
    character(len=:), allocatable :: path
    character(len=:), allocatable :: error_message
  end type cache_entry

  type, public :: cache_text_result
    logical :: found = .false.
    integer :: error_code = FGOF_CACHE_OK
    type(cache_entry) :: entry
    character(len=:), allocatable :: text
    character(len=:), allocatable :: error_message
  end type cache_text_result

  type, public :: cache_prune_result
    logical :: completed = .false.
    integer :: error_code = FGOF_CACHE_OK
    integer(int64) :: scanned_count = 0_int64
    integer(int64) :: removed_count = 0_int64
    character(len=:), allocatable :: root_path
    character(len=:), allocatable :: error_message
  end type cache_prune_result

end module fgof_cache_types
