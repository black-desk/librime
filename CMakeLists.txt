set(CMAKE_USER_MAKE_RULES_OVERRIDE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/c_flag_overrides.cmake)
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cxx_flag_overrides.cmake)

cmake_minimum_required(VERSION 3.24)
if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()
project(rime VERSION 1.16.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(rime_soversion 1)

# generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(FetchContent)

option(BUILD_SHARED_LIBS "Build Rime as shared library" ON)
option(BUILD_MERGED_PLUGINS "Merge plugins into one Rime library" ON)
option(BUILD_STATIC "Build with dependencies as static libraries" OFF)
option(USE_VENDORED_DEPS "Fetch and build dependencies from source" OFF)
option(BUILD_DATA "Build data for Rime" OFF)
option(BUILD_SAMPLE "Build sample Rime plugin" OFF)
option(BUILD_TEST "Build and run tests" ON)
option(BUILD_SEPARATE_LIBS "Build separate rime-* libraries" OFF)
option(ENABLE_LOGGING "Enable logging with google-glog library" ON)
option(ALSO_LOG_TO_STDERR "Log to stderr as well as log file" OFF)
option(ENABLE_ASAN "Enable Address Sanitizer (Unix Only)" OFF)
option(INSTALL_PRIVATE_HEADERS "Install private headers (usually needed for externally built Rime plugins)" OFF)
option(ENABLE_EXTERNAL_PLUGINS "Enable loading of externally built Rime plugins (from directory set by RIME_PLUGINS_DIR variable)" OFF)
option(ENABLE_THREADING "Enable threading for deployer" ON)
option(ENABLE_TIMESTAMP "Embed timestamp to schema artifacts" ON)

set(RIME_DATA_DIR "rime-data" CACHE STRING "Target directory for Rime data")
set(RIME_PLUGINS_DIR "rime-plugins" CACHE STRING "Target directory for externally built Rime plugins")

if(WIN32)
  set(ext ".exe")
endif(WIN32)

set(Boost_USE_STATIC_LIBS ${BUILD_STATIC})
set(Boost_USE_MULTITHREADED ON)
if(BUILD_STATIC)
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a .lib)
endif()
if(MSVC)
  set(Boost_USE_STATIC_RUNTIME ON)
endif()

find_package(Threads REQUIRED)

if(USE_VENDORED_DEPS)
  # Boost
  set(BOOST_INCLUDE_LIBRARIES
    algorithm crc dll interprocess range regex scope_exit signals2 unordered uuid
    CACHE STRING "" FORCE)
  FetchContent_Declare(Boost
    URL https://github.com/boostorg/boost/releases/download/boost-1.91.0-1/boost-1.91.0-1-cmake.tar.gz
    OVERRIDE_FIND_PACKAGE
  )
  FetchContent_MakeAvailable(Boost)

  # glog
  FetchContent_Declare(glog
    URL https://github.com/google/glog/archive/refs/tags/v0.7.1.tar.gz
    OVERRIDE_FIND_PACKAGE
  )
  set(WITH_GFLAGS OFF CACHE BOOL "" FORCE)
  set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(glog)

  # yaml-cpp
  FetchContent_Declare(yaml-cpp
    URL https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.9.0.tar.gz
    OVERRIDE_FIND_PACKAGE
  )
  set(YAML_CPP_BUILD_CONTRIB OFF CACHE BOOL "" FORCE)
  set(YAML_CPP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(YAML_CPP_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(yaml-cpp)

  # leveldb
  FetchContent_Declare(leveldb
    URL https://github.com/google/leveldb/archive/refs/tags/1.23.tar.gz
    OVERRIDE_FIND_PACKAGE
  )
  set(LEVELDB_BUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)
  set(LEVELDB_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(leveldb)
  if(NOT TARGET leveldb::leveldb)
    add_library(leveldb::leveldb ALIAS leveldb)
  endif()

  # marisa-trie
  FetchContent_Declare(Marisa
    URL https://github.com/s-yata/marisa-trie/archive/refs/tags/v0.3.1.tar.gz
    OVERRIDE_FIND_PACKAGE
  )
  set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "" FORCE)
  set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
  set(ENABLE_TOOLS OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(Marisa)

  # OpenCC
  FetchContent_Declare(OpenCC
    # FIXME: URL https://github.com/BYVoid/OpenCC/archive/refs/tags/ver.1.3.0.tar.gz
    URL https://github.com/BYVoid/OpenCC/archive/150feaac3f8fa4bfb3716e7d4d79380af948534b.zip
    PATCH_COMMAND
      patch -p1 -i "${CMAKE_CURRENT_SOURCE_DIR}/cmake/patches/opencc-fetchcontent-fix.patch"
    OVERRIDE_FIND_PACKAGE
  )
  set(LIBMARISA "marisa" CACHE FILEPATH "marisa library")
  set(USE_SYSTEM_RAPIDJSON OFF CACHE BOOL "Use vendored rapidjson in opencc" FORCE)
  set(USE_SYSTEM_DARTS OFF CACHE BOOL "Use vendored darts in opencc" FORCE)
  set(USE_SYSTEM_TCLAP OFF CACHE BOOL "Use vendored tclap in opencc" FORCE)
  FetchContent_MakeAvailable(OpenCC)

  if(BUILD_TEST)
    FetchContent_Declare(GTest
      URL https://github.com/google/googletest/releases/download/v1.17.0/googletest-1.17.0.tar.gz
      OVERRIDE_FIND_PACKAGE
    )
    set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(GTest)
  endif()
endif()

if(ENABLE_LOGGING)
  find_package(glog REQUIRED)
  find_package(gflags)
  set(RIME_ENABLE_LOGGING 1)
  if(ALSO_LOG_TO_STDERR)
    set(RIME_ALSO_LOG_TO_STDERR 1)
  endif()
endif()

find_package(Boost REQUIRED COMPONENTS regex)
find_package(yaml-cpp REQUIRED)
find_package(leveldb REQUIRED)
find_package(Marisa REQUIRED)
find_package(OpenCC REQUIRED)

if(BUILD_TEST)
  find_package(GTest REQUIRED)
  enable_testing()
endif()

find_path(X11Keysym X11/keysym.h)
if(X11Keysym)
  message(STATUS "Found X11/keysym.h at ${X11Keysym}")
else()
  message(WARNING "X11/keysym.h not found.")
endif()

configure_file(
  "${PROJECT_SOURCE_DIR}/src/rime/build_config.h.in"
  "${PROJECT_BINARY_DIR}/src/rime/build_config.h")

if (NOT CMAKE_BUILD_PARALLEL_LEVEL)
  include(ProcessorCount)
  ProcessorCount(N)
  if (NOT N EQUAL 0)
    set(CMAKE_BUILD_PARALLEL_LEVEL ${N})
  endif()
endif()

# keep these variables lest some Rime plugin's cmake file is still using them {
if(NOT DEFINED LIB_INSTALL_DIR)
    set(LIB_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR})
endif()

if(NOT DEFINED BIN_INSTALL_DIR)
    set(BIN_INSTALL_DIR ${CMAKE_INSTALL_BINDIR})
endif()
# }

# remove target
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
  IMMEDIATE @ONLY)
add_custom_target(remove
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux|FreeBSD|OpenBSD|DragonFly|GNU|Darwin" OR MINGW)
  set(prefix "${CMAKE_INSTALL_PREFIX}")
  set(exec_prefix "${CMAKE_INSTALL_PREFIX}")
  set(bindir "${CMAKE_INSTALL_FULL_BINDIR}")
  set(libdir "${CMAKE_INSTALL_FULL_LIBDIR}")
  set(pkgdatadir "${CMAKE_INSTALL_FULL_DATADIR}/${RIME_DATA_DIR}")
  set(pluginsdir "${CMAKE_INSTALL_FULL_LIBDIR}/${RIME_PLUGINS_DIR}")
  set(includedir "${CMAKE_INSTALL_FULL_INCLUDEDIR}")
  configure_file(
      ${PROJECT_SOURCE_DIR}/rime.pc.in
      ${PROJECT_BINARY_DIR}/rime.pc
      @ONLY)
  install(FILES ${PROJECT_BINARY_DIR}/rime.pc
    DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig)
endif()

file(GLOB rime_public_header_files ${PROJECT_SOURCE_DIR}/src/*.h)
list(FILTER rime_public_header_files EXCLUDE REGEX .*_impl\.h$)
install(FILES ${rime_public_header_files}
  DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR})
if(INSTALL_PRIVATE_HEADERS)
  file(GLOB rime_private_header_files
    ${PROJECT_SOURCE_DIR}/src/rime/*.h
    ${PROJECT_BINARY_DIR}/src/rime/*.h)
  install(FILES ${rime_private_header_files}
    DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/rime)
  foreach(rime_private_header_files_dir algo config dict gear lever)
    file(GLOB rime_private_header_files
      ${PROJECT_SOURCE_DIR}/src/rime/${rime_private_header_files_dir}/*.h)
    install(FILES ${rime_private_header_files}
      DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/rime/${rime_private_header_files_dir})
  endforeach()
endif()

if(BUILD_DATA)
  file(GLOB rime_preset_data_files ${PROJECT_SOURCE_DIR}/data/preset/*.yaml)
  install(FILES ${rime_preset_data_files} DESTINATION ${CMAKE_INSTALL_FULL_DATADIR}/${RIME_DATA_DIR})
endif()

set(rime_library rime)
if(BUILD_SHARED_LIBS AND BUILD_SEPARATE_LIBS)
  set(rime_dict_library rime-dict)
  set(rime_gears_library rime-gears)
  set(rime_levers_library rime-levers)
endif()

add_subdirectory(plugins)
message(STATUS "rime_plugins_libs: ${rime_plugins_deps}")
message(STATUS "rime_plugins_modules: ${rime_plugins_modules}")
set(list "")
foreach(mod ${rime_plugins_modules})
  set(list "${list},Q(${mod})")
endforeach()
set(RIME_SETUP_EXTRA_MODULES "${list}")
if(BUILD_SHARED_LIBS AND BUILD_SEPARATE_LIBS AND rime_plugins_objs)
  set(rime_plugins_library rime-plugins)
endif()

add_subdirectory(src)

if(BUILD_SHARED_LIBS)
  add_subdirectory(tools)

  if (BUILD_SAMPLE)
    add_subdirectory(sample)
  endif()
endif()

if(BUILD_TEST)
  add_subdirectory(test)
endif()

if(BUILD_SHARED_LIBS)
  set(rime_export_targets rime)
else()
  set(rime_export_targets rime-static)
endif()
if(BUILD_SHARED_LIBS AND BUILD_SEPARATE_LIBS)
  list(APPEND rime_export_targets rime-dict rime-gears rime-levers)
endif()

if(USE_VENDORED_DEPS)
  install(TARGETS ${rime_export_targets}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )
else()
  install(TARGETS ${rime_export_targets}
    EXPORT rime-targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )

  install(EXPORT rime-targets
    NAMESPACE rime::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/rime
  )
endif()

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/RimeConfigVersion.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RimeConfig.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/RimeConfig.cmake"
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/rime
)

install(FILES
  "${CMAKE_CURRENT_BINARY_DIR}/RimeConfig.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/RimeConfigVersion.cmake"
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/rime
)
