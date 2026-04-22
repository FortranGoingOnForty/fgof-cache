program test_cache_prune
  use iso_fortran_env, only : int64
  use fgof_cache, only : &
    FGOF_CACHE_ERR_INVALID_OPTIONS, &
    FGOF_CACHE_ERR_NOT_FOUND, &
    FGOF_CACHE_OK, &
    clear_cache_options, &
    prune_stale_cache, &
    read_cache_text, &
    write_cache_text
  use fgof_cache_types, only : cache_entry, cache_options, cache_prune_result, cache_text_result
  implicit none

  type(cache_options) :: keep_options
  type(cache_options) :: prune_options
  type(cache_options) :: missing_options
  type(cache_options) :: unsafe_options
  type(cache_entry) :: entry
  type(cache_prune_result) :: prune_result
  type(cache_text_result) :: read_result
  character(len=:), allocatable :: root_path
  logical :: exists

  root_path = unique_root("prune")

  prune_options = clear_cache_options()
  prune_options%root_dir = root_path
  prune_options%namespace = "prune"

  keep_options = clear_cache_options()
  keep_options%root_dir = root_path
  keep_options%namespace = "keep"

  entry = write_cache_text("alpha", "old-a", prune_options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "write_cache_text should succeed for stale-prune setup"
  entry = write_cache_text("beta", "old-b", prune_options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "write_cache_text should succeed for second stale-prune setup entry"
  entry = write_cache_text("gamma", "keep-me", keep_options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "write_cache_text should succeed for control namespace entries"

  prune_result = prune_stale_cache(60_int64, prune_options, entry%modified_time_seconds + 120_int64)
  if (.not. prune_result%completed) error stop "prune_stale_cache should complete for existing namespaces"
  if (prune_result%error_code /= FGOF_CACHE_OK) error stop "prune_stale_cache should report ok on success"
  if (prune_result%scanned_count /= 2_int64) error stop "prune_stale_cache should only scan files inside the selected namespace"
  if (prune_result%removed_count /= 2_int64) error stop "prune_stale_cache should remove stale files inside the selected namespace"
  if (prune_result%root_path /= root_path // "/prune") error stop "prune_stale_cache should report the resolved namespace root"

  read_result = read_cache_text("alpha", prune_options)
  if (read_result%error_code /= FGOF_CACHE_ERR_NOT_FOUND) error stop "pruned entries should read back as not-found"

  read_result = read_cache_text("beta", prune_options)
  if (read_result%error_code /= FGOF_CACHE_ERR_NOT_FOUND) error stop "all stale files in the pruned namespace should be removed"

  read_result = read_cache_text("gamma", keep_options)
  if (read_result%error_code /= FGOF_CACHE_OK) error stop "pruning one namespace should not disturb another namespace"
  if (read_result%text /= "keep-me") error stop "control namespace entries should remain intact after prune"

  prune_result = prune_stale_cache(-1_int64, prune_options, entry%modified_time_seconds + 120_int64)
  if (prune_result%completed) error stop "negative max_age_seconds should not report a completed prune"
  if (prune_result%error_code /= FGOF_CACHE_ERR_INVALID_OPTIONS) error stop "negative max_age_seconds should report invalid options"

  unsafe_options = clear_cache_options()
  unsafe_options%root_dir = root_path
  prune_result = prune_stale_cache(60_int64, unsafe_options, entry%modified_time_seconds + 120_int64)
  if (prune_result%completed) error stop "prune_stale_cache should reject explicit unnamespaced root_dir pruning"
  if (prune_result%error_code /= FGOF_CACHE_ERR_INVALID_OPTIONS) error stop "explicit unnamespaced root_dir pruning should report invalid options"

  missing_options = clear_cache_options()
  missing_options%root_dir = unique_root("missing")
  missing_options%namespace = "demo"
  prune_result = prune_stale_cache(60_int64, missing_options, 3600_int64)
  if (.not. prune_result%completed) error stop "prune_stale_cache should be a completed no-op for missing roots"
  if (prune_result%error_code /= FGOF_CACHE_OK) error stop "missing roots should not be treated as prune failures"
  inquire(file=missing_options%root_dir // "/demo", exist=exists)
  if (exists) error stop "prune_stale_cache should not create missing roots while probing"

contains

  function unique_root(label) result(path)
    character(len=*), intent(in) :: label
    character(len=:), allocatable :: path
    character(len=32) :: count_text
    integer :: count_value

    call system_clock(count=count_value)
    write(count_text, "(i0)") count_value
    path = "build/fgof-cache-prune-" // label // "-" // trim(count_text)
  end function unique_root

end program test_cache_prune
