# Explicit source file lists (replaces aux_source_directory for reliability)

set(rime_api_src
  rime_api.cc
  rime_api_stdbool.cc
)

set(rime_base_src
  rime/candidate.cc
  rime/commit_history.cc
  rime/composition.cc
  rime/context.cc
  rime/core_module.cc
  rime/deployer.cc
  rime/engine.cc
  rime/key_event.cc
  rime/key_table.cc
  rime/language.cc
  rime/menu.cc
  rime/module.cc
  rime/registry.cc
  rime/resource.cc
  rime/schema.cc
  rime/segmentation.cc
  rime/service.cc
  rime/setup.cc
  rime/signature.cc
  rime/switcher.cc
  rime/switches.cc
  rime/ticket.cc
  rime/translation.cc
)

set(rime_algo_src
  rime/algo/algebra.cc
  rime/algo/calculus.cc
  rime/algo/encoder.cc
  rime/algo/spelling.cc
  rime/algo/strings.cc
  rime/algo/syllabifier.cc
  rime/algo/utilities.cc
)

set(rime_config_src
  rime/config/auto_patch_config_plugin.cc
  rime/config/build_info_plugin.cc
  rime/config/config_compiler.cc
  rime/config/config_component.cc
  rime/config/config_data.cc
  rime/config/config_types.cc
  rime/config/default_config_plugin.cc
  rime/config/legacy_dictionary_config_plugin.cc
  rime/config/legacy_preset_config_plugin.cc
  rime/config/save_output_plugin.cc
)

set(rime_dict_src
  rime/dict/corrector.cc
  rime/dict/db.cc
  rime/dict/db_utils.cc
  rime/dict/dict_compiler.cc
  rime/dict/dict_module.cc
  rime/dict/dict_settings.cc
  rime/dict/dictionary.cc
  rime/dict/entry_collector.cc
  rime/dict/level_db.cc
  rime/dict/mapped_file.cc
  rime/dict/preset_vocabulary.cc
  rime/dict/prism.cc
  rime/dict/reverse_lookup_dictionary.cc
  rime/dict/string_table.cc
  rime/dict/table.cc
  rime/dict/table_db.cc
  rime/dict/text_db.cc
  rime/dict/tsv.cc
  rime/dict/user_db.cc
  rime/dict/user_db_recovery_task.cc
  rime/dict/user_dictionary.cc
  rime/dict/vocabulary.cc
)

set(rime_gears_src
  rime/gear/abc_segmentor.cc
  rime/gear/affix_segmentor.cc
  rime/gear/ascii_composer.cc
  rime/gear/ascii_segmentor.cc
  rime/gear/charset_filter.cc
  rime/gear/chord_composer.cc
  rime/gear/contextual_translation.cc
  rime/gear/echo_translator.cc
  rime/gear/editor.cc
  rime/gear/fallback_segmentor.cc
  rime/gear/filter_commons.cc
  rime/gear/gears_module.cc
  rime/gear/history_translator.cc
  rime/gear/key_binder.cc
  rime/gear/matcher.cc
  rime/gear/memory.cc
  rime/gear/navigator.cc
  rime/gear/poet.cc
  rime/gear/punctuator.cc
  rime/gear/recognizer.cc
  rime/gear/reverse_lookup_filter.cc
  rime/gear/reverse_lookup_translator.cc
  rime/gear/schema_list_translator.cc
  rime/gear/script_translator.cc
  rime/gear/selector.cc
  rime/gear/shape.cc
  rime/gear/simplifier.cc
  rime/gear/single_char_filter.cc
  rime/gear/speller.cc
  rime/gear/switch_translator.cc
  rime/gear/table_translator.cc
  rime/gear/translator_commons.cc
  rime/gear/uniquifier.cc
  rime/gear/unity_table_encoder.cc
)

set(rime_levers_src
  rime/lever/custom_settings.cc
  rime/lever/customizer.cc
  rime/lever/deployment_tasks.cc
  rime/lever/levers_module.cc
  rime/lever/levers_stdbool.cc
  rime/lever/switcher_settings.cc
  rime/lever/user_dict_manager.cc
)

# Module groupings
set(rime_core_module_src
  ${rime_api_src}
  ${rime_base_src}
  ${rime_config_src}
)
set(rime_dict_module_src
  ${rime_algo_src}
  ${rime_dict_src}
)

# add rc info for windows MSVC build
if(WIN32)
  include(${CMAKE_SOURCE_DIR}/cmake/AddRCInfo.cmake)
endif()

# Collect plugins source if building separate plugins library
if(rime_plugins_library)
  file(GLOB rime_plugins_src ${CMAKE_CURRENT_SOURCE_DIR}/../plugins/*.cc)
endif()

if(BUILD_SHARED_LIBS AND BUILD_SEPARATE_LIBS)
  set(rime_src ${rime_core_module_src})
else()
  set(rime_src
      ${rime_core_module_src}
      ${rime_dict_module_src}
      ${rime_gears_src}
      ${rime_levers_src}
      ${rime_plugins_src}
      ${rime_plugins_objs})
endif()

if(BUILD_SHARED_LIBS)
  add_library(rime ${rime_src})
  add_library(rime::rime ALIAS rime)
  set(_rime_lib rime)
else()
  add_library(rime-static STATIC ${rime_src})
  add_library(rime INTERFACE)
  add_library(rime::rime ALIAS rime)
  target_link_libraries(rime INTERFACE
    $<LINK_LIBRARY:WHOLE_ARCHIVE,rime-static>)
  set(_rime_lib rime-static)
endif()

# Public include directories (needed by consumers via rime::rime)
target_include_directories(${_rime_lib}
  PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/src>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# OpenCC from FetchContent: source headers have no opencc/ prefix, create symlink
if(USE_VENDORED_DEPS AND TARGET opencc)
  file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/opencc-include)
  file(CREATE_LINK ${opencc_SOURCE_DIR}/src ${CMAKE_BINARY_DIR}/opencc-include/opencc SYMBOLIC)
  target_include_directories(${_rime_lib} PRIVATE ${CMAKE_BINARY_DIR}/opencc-include)
endif()

# Private compile definitions
target_compile_definitions(${_rime_lib}
  PRIVATE
    RIME_VERSION="${PROJECT_VERSION}"
    $<$<NOT:$<BOOL:${ENABLE_THREADING}>>:RIME_NO_THREADING>
    $<$<NOT:$<BOOL:${ENABLE_TIMESTAMP}>>:RIME_NO_TIMESTAMP>
)

# Address Sanitizer
if(ENABLE_ASAN)
  target_compile_options(${_rime_lib} PRIVATE -fsanitize=address -fno-omit-frame-pointer)
  target_link_options(${_rime_lib} PRIVATE -fsanitize=address)
endif()

# X11 keysym headers - already covered by the public include directory
# (find_path resolves X11/keysym.h from the project's include/ directory)

# Private link dependencies
target_link_libraries(${_rime_lib}
  PUBLIC
    Boost::regex
    $<$<BOOL:${USE_VENDORED_DEPS}>:
      Boost::signals2
      Boost::algorithm
      Boost::crc
      Boost::dll
      Boost::interprocess
      Boost::range
      Boost::scope_exit
      Boost::unordered
      Boost::uuid
    >
    glog::glog
  PRIVATE
    yaml-cpp::yaml-cpp
    Threads::Threads
    leveldb::leveldb
    Marisa::marisa
    OpenCC::OpenCC
    ${rime_plugins_deps}
)

# Workaround: OpenCC vcpkg port incorrectly lists "RapidJSON" as a link
# dependency (it's header-only). Strip it from the exported target.
if(NOT USE_VENDORED_DEPS)
  get_target_property(_opencc_iface_libs OpenCC::OpenCC INTERFACE_LINK_LIBRARIES)
  if(_opencc_iface_libs)
    list(FILTER _opencc_iface_libs EXCLUDE REGEX "^[Rr]apidJSON$")
    set_target_properties(OpenCC::OpenCC PROPERTIES INTERFACE_LINK_LIBRARIES "${_opencc_iface_libs}")
  endif()
endif()

# Logging deps
if(ENABLE_LOGGING)
  if(gflags_FOUND)
    target_link_libraries(${_rime_lib} PRIVATE gflags::gflags)
  endif()
endif()

# External plugin loading
if(ENABLE_EXTERNAL_PLUGINS)
  target_link_libraries(${_rime_lib} PRIVATE ${CMAKE_DL_LIBS})
endif()

# Platform-specific
if(glog_FOUND AND WIN32)
  target_link_libraries(${_rime_lib} PRIVATE dbghelp)
endif()
if(MINGW)
  target_link_libraries(${_rime_lib} PRIVATE wsock32 ws2_32 bcrypt)
endif()

# Shared vs static library properties
if(BUILD_SHARED_LIBS)
  target_compile_definitions(rime
    PUBLIC RIME_BUILD_SHARED_LIBS
    PRIVATE RIME_EXPORTS
  )
  set_target_properties(rime PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${rime_soversion}
    DEFINE_SYMBOL "RIME_EXPORTS"
    LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin
  )
  if(XCODE_VERSION)
    set_target_properties(rime PROPERTIES INSTALL_NAME_DIR "@rpath")
  endif()
else()
  set_target_properties(rime-static PROPERTIES
    OUTPUT_NAME "rime"
    PREFIX "lib"
    ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
  )
  # Propagate the real library's link dependencies through the interface target
  target_link_libraries(rime INTERFACE ${_rime_lib})
endif()

# MSVC PDB install
if(MSVC AND BUILD_SHARED_LIBS)
  install(FILES $<TARGET_PDB_FILE:rime>
    DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}
    OPTIONAL)
endif()

# Setup extra modules definition
if(DEFINED RIME_SETUP_EXTRA_MODULES)
  set_property(SOURCE rime/setup.cc
    PROPERTY COMPILE_DEFINITIONS
    "RIME_EXTRA_MODULES=${RIME_SETUP_EXTRA_MODULES}")
endif()

if(BUILD_SHARED_LIBS AND BUILD_SEPARATE_LIBS)
  add_library(rime-dict ${rime_dict_module_src})
  add_library(rime::dict ALIAS rime-dict)
  target_link_libraries(rime-dict
    PRIVATE leveldb::leveldb Marisa::marisa
    PUBLIC rime::rime
  )
  set_target_properties(rime-dict PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${rime_soversion}
    LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin
  )
  if(XCODE_VERSION)
    set_target_properties(rime-dict PROPERTIES INSTALL_NAME_DIR "@rpath")
  endif()
  install(TARGETS rime-dict DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

  add_library(rime-gears ${rime_gears_src})
  add_library(rime::gears ALIAS rime-gears)
  target_link_libraries(rime-gears
    PUBLIC rime::rime rime::dict
  )
  if(X11Keysym)
    target_include_directories(rime-gears PRIVATE ${X11Keysym})
  endif()
  set_target_properties(rime-gears PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${rime_soversion}
    LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin
  )
  if(XCODE_VERSION)
    set_target_properties(rime-gears PROPERTIES INSTALL_NAME_DIR "@rpath")
  endif()
  install(TARGETS rime-gears DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

  add_library(rime-levers ${rime_levers_src})
  add_library(rime::levers ALIAS rime-levers)
  target_link_libraries(rime-levers
    PUBLIC rime::rime
  )
  set_target_properties(rime-levers PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${rime_soversion}
    LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin
  )
  if(XCODE_VERSION)
    set_target_properties(rime-levers PROPERTIES INSTALL_NAME_DIR "@rpath")
  endif()
  install(TARGETS rime-levers DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

  if(rime_plugins_library)
    file(GLOB rime_plugins_src ${CMAKE_CURRENT_SOURCE_DIR}/../plugins/*.cc)
    add_library(rime-plugins ${rime_plugins_src} ${rime_plugins_objs})
    target_link_libraries(rime-plugins
      PUBLIC rime::rime rime::dict rime::gears
      PRIVATE ${rime_plugins_deps}
    )
    set_target_properties(rime-plugins PROPERTIES
      VERSION ${PROJECT_VERSION}
      SOVERSION ${rime_soversion}
      LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
      RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin
    )
    if(XCODE_VERSION)
      set_target_properties(rime-plugins PROPERTIES INSTALL_NAME_DIR "@rpath")
    endif()
    install(TARGETS rime-plugins DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})
  endif()
endif()
