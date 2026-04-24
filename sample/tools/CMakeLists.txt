add_executable(sample_console sample_console.cc)
target_link_libraries(sample_console PRIVATE ${sample_library} rime::rime)
set_target_properties(sample_console PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)

file(COPY ${PROJECT_SOURCE_DIR}/tools/default.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
file(COPY ${PROJECT_SOURCE_DIR}/tools/sample.schema.yaml
     DESTINATION ${PROJECT_BINARY_DIR}/bin)
