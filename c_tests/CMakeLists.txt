cmake_minimum_required(VERSION 3.10)
project(TypeBalancerTests)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add code coverage flags if enabled
option(ENABLE_COVERAGE "Enable coverage reporting" OFF)
if(ENABLE_COVERAGE)
    add_compile_options(--coverage -O0 -g)
    add_link_options(--coverage)
endif()

# Find GoogleTest
find_package(GTest REQUIRED)
include(GoogleTest)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${GTEST_INCLUDE_DIRS}
)

# Add C source files
add_library(type_balancer_core STATIC
    src/test_spacing_calculator.c
)

# Create test executable
add_executable(type_balancer_tests
    src/spacing_calculator_test.cpp
    src/test_main.cpp
)

# Link against GoogleTest, pthread, and our core library
target_link_libraries(type_balancer_tests
    ${GTEST_BOTH_LIBRARIES}
    pthread
    type_balancer_core
)

# Enable testing
enable_testing()
gtest_discover_tests(type_balancer_tests)

# Add coverage target
if(ENABLE_COVERAGE)
    add_custom_target(coverage
        COMMAND ${CMAKE_COMMAND} -E make_directory coverage
        COMMAND gcovr -r ${CMAKE_SOURCE_DIR} --html --html-details -o coverage/index.html
        COMMAND gcovr -r ${CMAKE_SOURCE_DIR} --xml -o coverage/coverage.xml
        COMMAND gcovr -r ${CMAKE_SOURCE_DIR} --txt -o coverage/coverage.txt
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating coverage reports"
    )
endif()
