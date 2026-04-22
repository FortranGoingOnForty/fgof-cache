program test_cache_root
  use fgof_cache, only : &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    clear_cache_options, &
    ensure_cache_root
  use fgof_cache_types, only : cache_options, cache_root
  implicit none

  type(cache_options) :: options
  type(cache_root) :: root
  character(len=:), allocatable :: base_path
  logical :: exists

  base_path = unique_root("ready")
  options = clear_cache_options()
  options%root_dir = base_path
  options%namespace = "demo"
  root = ensure_cache_root(options)
  if (.not. root%ready) error stop "ensure_cache_root should create explicit namespaced roots"
  if (root%error_code /= FGOF_CACHE_OK) error stop "successful root creation should report ok"
  if (root%path /= base_path // "/demo") error stop "ensure_cache_root should append namespace to explicit roots"
  inquire(file=root%path, exist=exists)
  if (.not. exists) error stop "ensure_cache_root should create the cache directory on disk"

  options = clear_cache_options()
  options%create_root = .false.
  options%root_dir = unique_root("missing")
  root = ensure_cache_root(options)
  if (root%ready) error stop "ensure_cache_root should not report missing roots as ready"
  if (root%error_code /= FGOF_CACHE_ERR_NOT_FOUND) error stop "missing roots should report not-found"

  options = clear_cache_options()
  options%root_dir = unique_root("invalid")
  options%namespace = "bad/name"
  root = ensure_cache_root(options)
  if (root%ready) error stop "invalid namespace roots should not be ready"
  if (root%error_code /= FGOF_CACHE_ERR_INVALID_OPTIONS) error stop "invalid namespace should report invalid options"

contains

  function unique_root(label) result(path)
    character(len=*), intent(in) :: label
    character(len=:), allocatable :: path
    character(len=32) :: count_text
    integer :: count_value

    call system_clock(count=count_value)
    write(count_text, "(i0)") count_value
    path = "build/fgof-cache-root-" // label // "-" // trim(count_text)
  end function unique_root

end program test_cache_root
