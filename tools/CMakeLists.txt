set(rime_console_deps rime::rime)
if(BUILD_SEPARATE_LIBS)
  list(APPEND rime_console_deps rime::dict rime::gears rime::levers)
  if(rime_plugins_library)
    list(APPEND rime_console_deps rime-plugins)
  endif()
endif()

set(rime_api_console_src "rime_api_console.cc" "line_editor.cc")
add_executable(rime_api_console ${rime_api_console_src})
target_link_libraries(rime_api_console PRIVATE ${rime_console_deps})
set_target_properties(rime_api_console PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)

set(rime_console_src "rime_console.cc")
add_executable(rime_console ${rime_console_src})
target_compile_definitions(rime_console PRIVATE RIME_IMPORTS)
target_link_libraries(rime_console PRIVATE ${rime_console_deps})
set_target_properties(rime_console PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)

set(rime_deployer_src "rime_deployer.cc")
add_executable(rime_deployer ${rime_deployer_src})
target_compile_definitions(rime_deployer PRIVATE RIME_IMPORTS)
target_link_libraries(rime_deployer PRIVATE rime::rime)
if(BUILD_SEPARATE_LIBS)
  target_link_libraries(rime_deployer PRIVATE rime::dict rime::levers)
endif()
set_target_properties(rime_deployer PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)

set(rime_dict_manager_src "rime_dict_manager.cc")
add_executable(rime_dict_manager ${rime_dict_manager_src})
target_link_libraries(rime_dict_manager PRIVATE rime::rime)
if(BUILD_SEPARATE_LIBS)
  target_link_libraries(rime_dict_manager PRIVATE rime::dict rime::levers)
endif()
set_target_properties(rime_dict_manager PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)

set(rime_patch_src "rime_patch.cc")
add_executable(rime_patch ${rime_patch_src})
target_link_libraries(rime_patch PRIVATE rime::rime)
if(BUILD_SEPARATE_LIBS)
  target_link_libraries(rime_patch PRIVATE rime::levers)
endif()
set_target_properties(rime_patch PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)

install(TARGETS rime_deployer rime_dict_manager rime_patch
  RUNTIME DESTINATION ${BIN_INSTALL_DIR})

# do not work with Windows DLL; interfaces to dict are missing DLL export.
if(NOT WIN32 OR NOT BUILD_SHARED_LIBS)
  set(rime_table_decompiler_src "rime_table_decompiler.cc")
  add_executable(rime_table_decompiler ${rime_table_decompiler_src})
  target_compile_definitions(rime_table_decompiler PRIVATE RIME_IMPORTS)
  target_link_libraries(rime_table_decompiler PRIVATE rime::rime)
  if(BUILD_SEPARATE_LIBS)
    target_link_libraries(rime_table_decompiler PRIVATE rime::dict)
  endif()
  set_target_properties(rime_table_decompiler PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)

  install(TARGETS rime_table_decompiler RUNTIME DESTINATION ${BIN_INSTALL_DIR})
endif()

file(COPY ${PROJECT_SOURCE_DIR}/data/minimal/default.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
file(COPY ${PROJECT_SOURCE_DIR}/data/minimal/symbols.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
file(COPY ${PROJECT_SOURCE_DIR}/data/minimal/essay.txt
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
file(COPY ${PROJECT_SOURCE_DIR}/data/minimal/luna_pinyin.dict.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
file(COPY ${PROJECT_SOURCE_DIR}/data/minimal/luna_pinyin.schema.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
file(COPY ${PROJECT_SOURCE_DIR}/data/minimal/cangjie5.dict.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
file(COPY ${PROJECT_SOURCE_DIR}/data/minimal/cangjie5.schema.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
