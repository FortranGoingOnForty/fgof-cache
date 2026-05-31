cmake_minimum_required(VERSION 3.25)

project(fgof_cache VERSION 0.1.0 LANGUAGES Fortran C)

if(NOT TARGET fgof::temp)
  if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/../fgof-temp/CMakeLists.txt")
    add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../fgof-temp" "${CMAKE_CURRENT_BINARY_DIR}/_deps/fgof-temp")
  else()
    message(FATAL_ERROR "fgof-cache requires fgof-temp")
  endif()
endif()

add_library(fgof_cache
  src/fgof_cache_types.f90
  src/fgof_cache_posix.f90
  src/fgof_cache.f90
  src/fgof_cache_posix.c
)
add_library(fgof::cache ALIAS fgof_cache)

set_target_properties(fgof_cache PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod"
)

target_include_directories(fgof_cache PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
)

target_link_libraries(fgof_cache PUBLIC fgof::temp)

target_compile_options(fgof_cache PRIVATE
  $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-std=f2018 -Wall -Wextra -Wpedantic -Werror>
  $<$<COMPILE_LANG_AND_ID:C,GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic -Werror>
)
