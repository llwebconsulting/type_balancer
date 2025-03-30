cmake_minimum_required(VERSION 3.10)
project(type_balancer_tests)

# Enable compile_commands.json generation
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set C++ standard to C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Remove -Werror from flags
string(REPLACE "-Werror" "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
string(REPLACE "-Werror" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

# Set warning flags, but exclude problematic warnings
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wpedantic -Wno-unused-parameter")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wno-unused-parameter -DRUBY_NO_OLD_COMPATIBILITY -DRUBY_EXTERN=extern\\ \\\"C\\\" -DRUBY_EXTCONF_H=\\\"extconf.h\\\"")

# Enable clang-tidy
set(CLANG_TIDY_EXE "/opt/homebrew/Cellar/llvm/20.1.1/bin/clang-tidy")
if(EXISTS ${CLANG_TIDY_EXE})
    set(CMAKE_C_CLANG_TIDY 
        ${CLANG_TIDY_EXE};
        -checks=*,-llvmlibc-*,-modernize-*,-fuchsia-*,-altera-*,-hicpp-*;
        -header-filter=.*
    )
    set(CMAKE_CXX_CLANG_TIDY 
        ${CLANG_TIDY_EXE};
        -checks=*,-llvmlibc-*,-modernize-*,-fuchsia-*,-altera-*,-hicpp-*;
        -header-filter=.*
    )
    message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
else()
    message(WARNING "clang-tidy not found!")
endif()

# Find Ruby and add its include directories
find_package(Ruby REQUIRED)
include_directories(
    ${RUBY_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer
    ${CMAKE_SOURCE_DIR}/include
)

# Add source files
set(SOURCE_FILES
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/gap_filler.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/sequential_filler.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/distributor.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/position_calculator.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/spacing_calculator.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/position_generator.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/position_array.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/item_queue.c
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer/alternating_filler.c
)

# Create a library target for source files to ensure they're in compile_commands.json
add_library(type_balancer_lib OBJECT ${SOURCE_FILES})
target_include_directories(type_balancer_lib PRIVATE
    ${RUBY_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/../ext/type_balancer
    ${CMAKE_SOURCE_DIR}/include
)

# Set C source file properties
set_source_files_properties(${SOURCE_FILES} PROPERTIES
    COMPILE_FLAGS "-x c"
)

# Only build tests if GTest is found
find_package(GTest)
if(GTest_FOUND)
    # Add test files
    set(TEST_FILES
        test_main.cpp
        test_spacing_calculator.cpp
        test_position_calculator.cpp
        test_position_generator.cpp
        test_position_array.cpp
        test_position_adjuster.cpp
        test_distributor.cpp
        test_sequential_filler.cpp
    )

    # Add test executable
    add_executable(type_balancer_tests
        ${TEST_FILES}
        $<TARGET_OBJECTS:type_balancer_lib>
    )

    # Include directories
    target_include_directories(type_balancer_tests PRIVATE
        ${CMAKE_SOURCE_DIR}/../ext/type_balancer
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/include/wrapped
        ${GTEST_INCLUDE_DIRS}
    )

    # Link libraries
    target_link_libraries(type_balancer_tests
        ${GTEST_LIBRARIES}
        ${RUBY_LIBRARY}
        pthread
    )

    # Enable testing
    enable_testing()
    add_test(NAME type_balancer_tests COMMAND type_balancer_tests)

    # Coverage settings
    if(COVERAGE)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
    endif()
else()
    message(STATUS "GTest not found - skipping test build")
endif()
