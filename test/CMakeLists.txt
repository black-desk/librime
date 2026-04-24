set(rime_test_src
  algebra_test.cc
  calculus_test.cc
  component_test.cc
  config_compiler_test.cc
  config_test.cc
  corrector_test.cc
  dictionary_test.cc
  encoder_test.cc
  flavored_api_test.cc
  key_event_test.cc
  key_table_test.cc
  menu_test.cc
  prism_test.cc
  resource_resolver_test.cc
  rime_test_main.cc
  segmentor_test.cc
  syllabifier_test.cc
  table_test.cc
  user_db_test.cc
)

add_executable(rime_test ${rime_test_src})
target_link_libraries(rime_test PRIVATE rime::rime GTest::gtest GTest::gtest_main Marisa::marisa)
if(BUILD_SEPARATE_LIBS)
  target_link_libraries(rime_test PRIVATE rime::dict rime::gears)
endif()
if(BUILD_SHARED_LIBS)
  target_compile_definitions(rime_test PRIVATE RIME_IMPORTS)
endif(BUILD_SHARED_LIBS)
set_target_properties(rime_test PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/test)

file(GLOB test_data_files ${PROJECT_SOURCE_DIR}/data/test/*.yaml)
file(COPY ${test_data_files} DESTINATION ${PROJECT_BINARY_DIR}/test)

add_test(NAME rime_test
  COMMAND rime_test
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/test)
