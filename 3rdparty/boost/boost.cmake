# MIT License
#
# Copyright (c) 2022 Luca Lobefaro, Meher Malladi, Ignacio Vizzo, Cyrill
# Stachniss, University of Bonn
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

function(set_target_system_include_dirs TARGET_NAME)
  get_target_property(interface_include_dirs ${TARGET_NAME} INTERFACE_INCLUDE_DIRECTORIES)
  set_target_properties(${TARGET_NAME} PROPERTIES INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${interface_include_dirs}")
endfunction()

# numeric/conversion is not included in OpenVDB's cmake when find packaging,
# although they use the headers in their math code. we can make a PR?
set(BOOST_INCLUDE_LIBRARIES headers numeric/conversion CACHE STRING "Boost list of libraries to be configured.")
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Boost built as shared lib.")

set(boost_fetch_content_args URL
                             https://github.com/boostorg/boost/releases/download/boost-1.85.0/boost-1.85.0-cmake.tar.gz)
if(${CMAKE_VERSION} GREATER_EQUAL 3.28)
  list(APPEND boost_fetch_content_args SYSTEM EXCLUDE_FROM_ALL OVERRIDE_FIND_PACKAGE)
endif()

FetchContent_Declare(boost ${boost_fetch_content_args})

if(${CMAKE_VERSION} GREATER_EQUAL 3.28)
  FetchContent_MakeAvailable(boost)
else()
  # we cannot use MakeAvailable because EXCLUDE_FROM_ALL in Declare is 3.28
  FetchContent_GetProperties(boost)
  if(NOT boost_POPULATED)
    FetchContent_Populate(boost)
    if(${CMAKE_VERSION} GREATER_EQUAL 3.25)
      add_subdirectory(${boost_SOURCE_DIR} ${boost_BINARY_DIR} SYSTEM EXCLUDE_FROM_ALL)
    else()
      # Emulate the SYSTEM flag introduced in CMake 3.25.
      add_subdirectory(${boost_SOURCE_DIR} ${boost_BINARY_DIR} EXCLUDE_FROM_ALL)
      set_target_system_include_dirs(boost_headers)
      set_target_system_include_dirs(boost_numeric_conversion)
    endif()

    # Emulate the OVERRIDE_FIND_PACKAGE behaviour in 3.24
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/fpRedirects")

    # Dummy an empty config file. We add_subdirectory above anyways
    file(WRITE "${CMAKE_BINARY_DIR}/fpRedirects/FindBoost.cmake" "")

    # Modify cmake module path only if it already doesnt have the directory
    list(FIND CMAKE_MODULE_PATH "${CMAKE_BINARY_DIR}/fpRedirects" _index)
    if(${_index} EQUAL -1)
      list(APPEND CMAKE_MODULE_PATH "${CMAKE_BINARY_DIR}/fpRedirects")
    endif()
  endif()
endif()
