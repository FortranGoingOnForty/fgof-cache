program cache_roundtrip_demo
  use fgof_cache, only : FGOF_CACHE_OK, clear_cache_options, read_cache_text, write_cache_text
  use fgof_cache_types, only : cache_entry, cache_options, cache_text_result
  implicit none

  type(cache_options) :: options
  type(cache_entry) :: entry
  type(cache_text_result) :: read_result

  options = clear_cache_options()
  options%root_dir = "/tmp/fgof-cache-example-roundtrip"
  options%namespace = "demo"

  entry = write_cache_text("alpha", "ready", options)
  if (entry%error_code /= FGOF_CACHE_OK) error stop "cache_roundtrip_demo: write should succeed"

  read_result = read_cache_text("alpha", options)
  if (read_result%error_code /= FGOF_CACHE_OK) error stop "cache_roundtrip_demo: read should succeed"

  print "(a)", read_result%text
end program cache_roundtrip_demo
