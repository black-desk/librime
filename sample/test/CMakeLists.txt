add_executable(sample_test sample_test.cc)
target_link_libraries(sample_test PRIVATE ${sample_library} rime::rime GTest::gtest GTest::gtest_main)
if(BUILD_SHARED_LIBS)
  target_compile_definitions(sample_test PRIVATE RIME_IMPORTS)
endif(BUILD_SHARED_LIBS)
set_target_properties(sample_test PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/test)

add_test(NAME sample_test COMMAND sample_test)
