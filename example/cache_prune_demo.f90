program cache_prune_demo
  use iso_fortran_env, only : int64
  use fgof_cache, only : &
    FGOF_CACHE_OK, &
    clear_cache_options, &
    prune_stale_cache, &
    write_cache_text
  use fgof_cache_types, only : cache_entry, cache_options, cache_prune_result
  implicit none

  type(cache_options) :: options
  type(cache_entry) :: entry
  type(cache_prune_result) :: prune_result

  options = clear_cache_options()
  options%root_dir = "/tmp/fgof-cache-example-prune"
  options%namespace = "demo"

  entry = write_cache_text("alpha", "one", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "cache_prune_demo: first write should succeed"

  entry = write_cache_text("beta", "two", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "cache_prune_demo: second write should succeed"

  prune_result = prune_stale_cache(60_int64, options, entry%modified_time_seconds + 120_int64)
  if (prune_result%error_code /= FGOF_CACHE_OK) error stop "cache_prune_demo: prune should succeed"

  print "(a,i0)", "removed=", prune_result%removed_count
end program cache_prune_demo
